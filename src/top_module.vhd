library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity top_module is
	port (
		i_Clock	 : in  STD_LOGIC;
		i_Reset	: in  STD_LOGIC;
		i_Button	: in  STD_LOGIC;
		i_Switch	: in  STD_LOGIC_VECTOR (9 downto 0);

		i_Section_01_Sensor   : in  STD_LOGIC;
		i_Section_02_Sensor   : in  STD_LOGIC;
		i_Section_03_Sensor   : in  STD_LOGIC;
		o_Speaker   : out  STD_LOGIC;
		i_End_Stop_X : in STD_LOGIC_VECTOR (1 downto 0);
		i_End_Stop_Z : in STD_LOGIC_VECTOR (1 downto 0);

		o_Driver_S1  : out STD_LOGIC := '0'; 
		o_Driver_S2  : out STD_LOGIC := '0'; 
		o_Driver_A_A_S2  : out STD_LOGIC; 
		o_Driver_A_B_S2  : out STD_LOGIC;

		o_VGA_R : out  STD_LOGIC_VECTOR (3 downto 0);
		o_VGA_G : out  STD_LOGIC_VECTOR (3 downto 0);
		o_VGA_B : out  STD_LOGIC_VECTOR (3 downto 0);
		o_VGA_Hsync : out STD_LOGIC;
		o_VGA_Vsync : out STD_LOGIC;
		o_LEDR	  : out STD_LOGIC_VECTOR (9 downto 0);

		o_X_Stepper_Motor_Enable   : out STD_LOGIC;
		o_X_Stepper_Motor_Direction   : out  STD_LOGIC;
		o_X_Stepper_Motor_Step   : out STD_LOGIC;

		o_Z_Stepper_Motor_Enable   : out STD_LOGIC;
		o_Z_Stepper_Motor_Direction   : out  STD_LOGIC;
		o_Z_Stepper_Motor_Step   : out STD_LOGIC

	);
end top_module;

architecture Behavioral of top_module is

	constant c_CLOCK_FREQUENCY : INTEGER := 50_000_000;

	constant c_DC_Motor_PWM_FREQUENCY : INTEGER := 200_000;

	constant c_TWO_SECONDS : INTEGER := 100_000_000;

	constant c_X_RIGHT : STD_LOGIC := '1';
	constant c_X_LEFT : STD_LOGIC := '0';

	constant c_Z_LIFT : STD_LOGIC := '1';
	constant c_Z_LOWER : STD_LOGIC := '0';

	constant c_DONT_CARE : STD_LOGIC := '-';
	constant c_OFF : STD_LOGIC := '0';
	constant c_ON : STD_LOGIC := '1';

	type t_Section_01 is (
			s_IDLE, s_BALL_DELAY, s_ACTIVE, s_COOLDOWN
		);
	type t_Section_02 is (
			s_IDLE, s_STEPPER_LEFT, s_DC_MOTOR_LOWER,
			s_MAGNETIZE, s_DC_MOTOR_LIFT, s_STEPPER_RIGHT, s_DE_MAGNETIZE, s_HOME	
		);

	type t_Section_03 is (
			s_IDLE, s_STEPPER_LOWER, s_STEPPER_LIFT,
			s_HOME, s_BALL_DELAY
		);

	signal r_Section_01 : t_Section_01 := s_IDLE;
	signal r_Section_02 : t_Section_02 := s_HOME;
	signal r_Section_03 : t_Section_03 := s_HOME;


	signal r_Counter_Section_01 : INTEGER range 0 to c_TWO_SECONDS := 0;
	signal r_Counter_Section_02 : INTEGER range 0 to c_TWO_SECONDS := 0;
	signal r_Counter_Section_03 : INTEGER range 0 to c_TWO_SECONDS := 0;

	signal r_StepperEnableX : STD_LOGIC := '0';
	signal r_StepperEnableZ : STD_LOGIC := '0';

	signal r_StepperDirectionX : STD_LOGIC := '0';
	signal r_StepperDirectionZ : STD_LOGIC := '0';

	signal r_DCEnable : STD_LOGIC_VECTOR (7 downto 0) := "00000000";
	signal r_DCDirection : STD_LOGIC := '0';

	signal r_Driver_S1 : STD_LOGIC := '0';
	signal r_Driver_S2 : STD_LOGIC := '0';

	signal w_Reset : STD_LOGIC := '0';

    signal r_Sensor_Delay : std_logic := '0';
    signal w_Sensor_Pulse : std_logic;

	signal r_EndStopZ_Hit_0 : std_logic := '0';
	signal r_EndStopZ_Hit_1 : std_logic := '0';

	signal r_EndStopX_Hit_0 : std_logic := '0';
	signal r_EndStopX_Hit_1 : std_logic := '0';

	signal r_Sensor02_Delay : std_logic := '0';
	signal w_Section_02_Pulse : std_logic;

	begin
		----------------------------------------------------------------------------------
		-- Static assignment
		----------------------------------------------------------------------------------
		w_Reset <= not i_Reset;

		o_LEDR(8) <= i_End_Stop_Z(1);
		o_LEDR(7) <= i_End_Stop_Z(0);

		o_LEDR(6) <= i_End_Stop_X(1);
		o_LEDR(5) <= i_End_Stop_X(0);

		o_LEDR(2) <= i_Section_03_Sensor;
		o_LEDR(1) <= i_Section_02_Sensor;
		o_LEDR(0) <= i_Section_01_Sensor;

		o_Driver_S1 <= r_Driver_S1;
		o_Driver_S2 <= r_Driver_S2;

		-- rising edge = new press event

	w_Sensor_Pulse <= i_Section_01_Sensor and not r_Sensor_Delay;
w_Section_02_Pulse <= i_Section_02_Sensor and not r_Sensor02_Delay;

	p_Seciton_01_Edge_Detector : process(i_Clock)
	begin
		if rising_edge(i_Clock) then
			r_Sensor_Delay <= i_Section_01_Sensor;
		end if;
	end process p_Seciton_01_Edge_Detector;


	p_Section_02_Edge : process(i_Clock)
	begin
		if rising_edge(i_Clock) then
			r_Sensor02_Delay <= i_Section_02_Sensor;
		end if;
	end process p_Section_02_Edge;
		----------------------------------------------------------------------------------
		-- Component decleration
		----------------------------------------------------------------------------------
		Speaker_init : entity work.Speaker
			generic map(
				g_CLOCK_FREQUENCY => C_CLOCK_FREQUENCY,
				g_PWM_FREQUENCY => 20_000
			)
			port map (
				i_Clock => i_Clock,
				o_Speaker => o_Speaker
			);

		VGA_init : entity work.VGA_Rainbow
			generic map(
				g_CLOCK_FREQUENCY => C_CLOCK_FREQUENCY,
				g_PIXEL_CLOCK => 12_500_000,

				g_H_LEFT_BORDER => 8,
				g_H_BACK_PORCH => 40,
				g_H_ACTIVE_VIDEO => 640,
				g_H_FRONT_PORCH => 8,
				g_H_RIGHT_BORDER => 8,
				g_H_SYNC => 96,

				g_V_TOP_BORDER => 8,
				g_V_BACK_PORCH => 25,
				g_V_ACTIVE_VIDEO => 480,
				g_V_FRONT_PORCH => 2,
				g_V_BOTTOM_BORDER => 8,
				g_V_SYNC => 2
			)
			port map(
				i_Clock => i_Clock,

				o_VGA_R => o_VGA_R,
				o_VGA_G => o_VGA_G,
				o_VGA_B => o_VGA_B,

				o_VGA_Vsync => o_VGA_Vsync,
				o_VGA_Hsync => o_VGA_Hsync
			);

		-- This will be used for a DC MOTOR for the final exit
		Motor_Driver_1_init : entity work.L9110_2_CHANNEL_MOTOR_DRIVER
			generic map(
				g_CLOCK_FREQUENCY => c_CLOCK_FREQUENCY,
				g_A_PWM_FREQUENCY => c_DC_MOTOR_PWM_FREQUENCY,
				g_B_PWM_FREQUENCY => c_DC_MOTOR_PWM_FREQUENCY
			)
			port map(
				i_A_Speed => r_DCEnable,
				i_A_Direction => r_DCDirection,
				i_B_Speed => (others => c_DONT_CARE),
				i_B_Direction => c_OFF,
				i_Clock => i_Clock,
				o_A_i_A => o_Driver_A_A_S2,
				o_A_i_B => o_Driver_A_B_S2,
				o_B_i_A => open,
				o_B_i_B => open
		);

		TMC2208_Stepper_Motor_Driver_Z_init_01 : entity work.TMC2208_Stepper_Motor_Driver
			generic map(
				g_CLOCK_FREQUENCY => c_CLOCK_FREQUENCY,
				g_STEP_RATE_HZ => 1000,
				g_STEP_PULSE => 100
			)
			port map (
				i_Clock => i_Clock,
				i_Enable  => r_StepperEnableZ,
				i_Direction => r_StepperDirectionZ,
				
				o_Enable => o_Z_Stepper_Motor_Enable,
				o_Direction => o_Z_Stepper_Motor_Direction,
				o_Step => o_Z_Stepper_Motor_Step
				
			);
			
		TMC2208_Stepper_Motor_Driver_Z_init_02 : entity work.TMC2208_Stepper_Motor_Driver
			generic map(
				g_CLOCK_FREQUENCY => c_CLOCK_FREQUENCY,
				g_STEP_RATE_HZ => 1000,
				g_STEP_PULSE => 100
			)
			port map (
				i_Clock => i_Clock,
				i_Enable  => r_StepperEnableX,
				i_Direction => r_StepperDirectionX,
				
				o_Enable => o_X_Stepper_Motor_Enable,
				o_Direction => o_X_Stepper_Motor_Direction,
				o_Step => o_X_Stepper_Motor_Step
				
			);

	p_SECTION_01 : process(i_Clock, w_Reset) begin
		if w_Reset = '1' then

			r_Section_01 <= s_IDLE;
			r_Counter_Section_01 <= 0;
			r_Driver_S1 <= '0';

		elsif rising_edge(i_Clock) then

			case r_Section_01 is

				------------------------------------------------------------
				when s_IDLE =>

					r_Driver_S1 <= '0';
					r_Counter_Section_01 <= 0;

					-- ONLY trigger once per press
					if w_Sensor_Pulse = '1' then
						r_Section_01 <= s_BALL_DELAY;
					end if;


				------------------------------------------------------------
				when s_BALL_DELAY =>

					if r_Counter_Section_01 < 2_000_000 - 1 then
						r_Counter_Section_01 <= r_Counter_Section_01 + 1;
					else
						r_Counter_Section_01 <= 0;
						r_Driver_S1 <= '1';
						r_Section_01 <= s_ACTIVE;
					end if;


				------------------------------------------------------------
				when s_ACTIVE =>

					r_Driver_S1 <= '1';

					if r_Counter_Section_01 < 10_000_000 - 1 then
						r_Counter_Section_01 <= r_Counter_Section_01 + 1;
					else
						r_Counter_Section_01 <= 0;
						r_Driver_S1 <= '0';
						r_Section_01 <= s_COOLDOWN;
					end if;


				------------------------------------------------------------
				when s_COOLDOWN =>

					-- prevents immediate retrigger while sensor still active
					r_Driver_S1 <= '0';

					if r_Counter_Section_01 < 2_000_000 - 1 then
						r_Counter_Section_01 <= r_Counter_Section_01 + 1;
					else
						r_Counter_Section_01 <= 0;
						r_Section_01 <= s_IDLE;
					end if;

			end case;

		end if;
	end process p_SECTION_01;
	
	p_SECTION_02 : process(i_Clock, w_Reset) begin
		if w_Reset = '1' then

			r_Section_02         <= s_HOME;

			r_StepperEnableX     <= c_OFF;
			r_StepperDirectionX  <= c_X_RIGHT;

			r_DCEnable           <= "00000000";
			r_DCDirection        <= c_Z_LOWER;

			r_Driver_S2          <= c_OFF;

			r_Counter_Section_02 <= 0;

			r_EndStopX_Hit_0     <= '0';
			r_EndStopX_Hit_1     <= '0';

		elsif rising_edge(i_Clock) then

			case r_Section_02 is

				------------------------------------------------------------
				when s_IDLE =>
					r_StepperEnableX <= c_OFF;
					r_DCEnable       <= "00000000";
					r_Driver_S2      <= c_OFF;

					r_EndStopX_Hit_0 <= '0';
					r_EndStopX_Hit_1 <= '0';

					if w_Section_02_Pulse = '1' then
						r_Section_02 <= s_STEPPER_LEFT;
					end if;

				------------------------------------------------------------
				when s_HOME =>
					r_StepperEnableX    <= c_ON;
					r_StepperDirectionX <= c_X_RIGHT;

					if i_End_Stop_X(1) = '0' then
						r_EndStopX_Hit_0 <= '1';
					end if;

					if r_EndStopX_Hit_0 = '1' then
						r_StepperEnableX <= c_OFF;
						r_Section_02 <= s_IDLE;
					end if;

				------------------------------------------------------------
				when s_STEPPER_LEFT =>
					r_StepperEnableX    <= c_ON;
					r_StepperDirectionX <= c_X_LEFT;

					if i_End_Stop_X(0) = '0' then
						r_EndStopX_Hit_1 <= '1';
					end if;

					if r_EndStopX_Hit_1 = '1' then
						r_StepperEnableX <= c_OFF;
						r_Counter_Section_02 <= 0;
						r_Section_02 <= s_DC_MOTOR_LOWER;
					end if;

				------------------------------------------------------------
				when s_DC_MOTOR_LOWER =>
					r_DCEnable    <= "11000000";
					r_DCDirection <= c_Z_LOWER;

					if r_Counter_Section_02 < 50_000_000 - 1 then
						r_Counter_Section_02 <= r_Counter_Section_02 + 1;
					else
						r_Counter_Section_02 <= 0;
						r_DCEnable <= "00000000";
						r_Section_02 <= s_MAGNETIZE;
					end if;

				------------------------------------------------------------
	when s_MAGNETIZE =>

		r_StepperEnableX <= c_OFF;
		r_DCEnable       <= "00000000";
		r_Driver_S2      <= c_ON;

		if r_Counter_Section_02 < c_TWO_SECONDS - 1 then
			r_Counter_Section_02 <= r_Counter_Section_02 + 1;
		else
			r_Counter_Section_02 <= 0;
			r_Section_02 <= s_DC_MOTOR_LIFT;
		end if;
				------------------------------------------------------------
				when s_DC_MOTOR_LIFT =>
					r_DCEnable    <= "11000000";
					r_DCDirection <= c_Z_LIFT;

					if r_Counter_Section_02 < 50_000_000 - 1 then
						r_Counter_Section_02 <= r_Counter_Section_02 + 1;
					else
						r_Counter_Section_02 <= 0;
						r_DCEnable <= "00000000";
						r_Section_02 <= s_STEPPER_RIGHT;
					end if;

				------------------------------------------------------------
				when s_STEPPER_RIGHT =>
					r_StepperEnableX    <= c_ON;
					r_StepperDirectionX <= c_X_RIGHT;

					if i_End_Stop_X(1) = '0' then
						r_EndStopX_Hit_0 <= '1';
					end if;

					if r_EndStopX_Hit_0 = '1' then
						r_StepperEnableX <= c_OFF;
						r_Section_02 <= s_HOME;
					end if;

				------------------------------------------------------------
	when s_DE_MAGNETIZE =>

		r_StepperEnableX <= c_OFF;
		r_DCEnable       <= "00000000";
		r_Driver_S2      <= c_OFF;

		if r_Counter_Section_02 < c_TWO_SECONDS - 1 then
			r_Counter_Section_02 <= r_Counter_Section_02 + 1;
		else
			r_Counter_Section_02 <= 0;
			r_Section_02 <= s_HOME;
		end if;

				------------------------------------------------------------
				when others =>
					r_Section_02 <= s_HOME;

			end case;
		end if;
	end process p_SECTION_02;

	p_SECTION_03 : process(i_Clock, w_Reset)
	begin

		if w_Reset = '1' then

			r_Section_03 <= s_HOME;
			r_Counter_Section_03 <= 0;

			r_StepperEnableZ <= c_OFF;
			r_StepperDirectionZ <= c_Z_LOWER;

			r_EndStopZ_Hit_0 <= '0';
			r_EndStopZ_Hit_1 <= '0';

		elsif rising_edge(i_Clock) then

			case r_Section_03 is

				------------------------------------------------------------
				when s_IDLE =>

					r_StepperEnableZ <= c_OFF;
					r_Counter_Section_03 <= 0;

					-- re-arm system
					r_EndStopZ_Hit_0 <= '0';
					r_EndStopZ_Hit_1 <= '0';

					if i_Section_03_Sensor = c_ON then
						r_Section_03 <= s_STEPPER_LIFT;
					end if;

				------------------------------------------------------------
				when s_HOME =>

					r_StepperEnableZ <= c_ON;
					r_StepperDirectionZ <= c_Z_LOWER;

					-- FIXED POLARITY: pressed = '0'
					if i_End_Stop_Z(0) = '0' then
						r_EndStopZ_Hit_0 <= '1';
					end if;

					if r_EndStopZ_Hit_0 = '1' then
						r_StepperEnableZ <= c_OFF;
						r_Section_03 <= s_IDLE;
					end if;

				------------------------------------------------------------
				when s_STEPPER_LOWER =>

					r_StepperEnableZ <= c_ON;
					r_StepperDirectionZ <= c_Z_LOWER;

					if i_End_Stop_Z(0) = '0' then
						r_EndStopZ_Hit_0 <= '1';
					end if;

					if r_EndStopZ_Hit_0 = '1' then
						r_Section_03 <= s_STEPPER_LIFT;
					end if;

				------------------------------------------------------------
				when s_STEPPER_LIFT =>

					r_StepperEnableZ <= c_ON;
					r_StepperDirectionZ <= c_Z_LIFT;

					-- FIXED POLARITY
					if i_End_Stop_Z(1) = '1' then
						r_EndStopZ_Hit_1 <= '1';
					end if;

					if r_EndStopZ_Hit_1 = '1' then
						r_StepperEnableZ <= c_OFF;
						r_Section_03 <= s_BALL_DELAY;
					end if;

				------------------------------------------------------------
				when s_BALL_DELAY =>

					r_StepperEnableZ <= c_OFF;

					if r_Counter_Section_03 < c_TWO_SECONDS - 1 then
						r_Counter_Section_03 <= r_Counter_Section_03 + 1;
					else
						r_Counter_Section_03 <= 0;

						r_EndStopZ_Hit_0 <= '0';
						r_EndStopZ_Hit_1 <= '0';

						r_Section_03 <= s_HOME;
					end if;

			end case;

		end if;
	end process p_SECTION_03;
	
end Behavioral;

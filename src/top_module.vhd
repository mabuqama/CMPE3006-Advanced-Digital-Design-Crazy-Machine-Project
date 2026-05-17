library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity top_module is
	port (
		i_Clock	 : in  STD_LOGIC;
		i_Reset	: in  STD_LOGIC;
		i_Button	: in  STD_LOGIC;
		o_UART_TX   : out STD_LOGIC;
		i_UART_RX   : in  STD_LOGIC;

		i_Section_01_Sensor   : in  STD_LOGIC;
		i_Section_02_Sensor   : in  STD_LOGIC;
		i_Section_03_Sensor   : in  STD_LOGIC;
		o_Speaker   : out  STD_LOGIC;
		i_End_Stop_X : in STD_LOGIC_VECTOR (1 downto 0);
		i_End_Stop_Z : in STD_LOGIC_VECTOR (1 downto 0);

		o_Driver_A_A_S1  : out STD_LOGIC; 
		o_Driver_A_B_S1  : out STD_LOGIC;
		o_Driver_B_A_S2  : out STD_LOGIC; 
		o_Driver_B_B_S2  : out STD_LOGIC;
		o_Driver_A_A_S3  : out STD_LOGIC; 
		o_Driver_A_B_S3  : out STD_LOGIC;
		o_Stepper_Motor_X : out STD_LOGIC_VECTOR (3 downto 0);
		o_Stepper_Motor_Z : out STD_LOGIC_VECTOR (3 downto 0);
		i_Switch	: in  STD_LOGIC_VECTOR (9 downto 0);
		o_VGA_R : out  STD_LOGIC_VECTOR (3 downto 0);
		o_VGA_G : out  STD_LOGIC_VECTOR (3 downto 0);
		o_VGA_B : out  STD_LOGIC_VECTOR (3 downto 0);
		o_VGA_Hsync : out STD_LOGIC;
		o_VGA_Vsync : out STD_LOGIC;
		o_LEDR	  : out STD_LOGIC_VECTOR (9 downto 0)

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
			s_IDLE, s_BALL_DELAY, s_ACTIVE
		);

	type t_Section_02 is (
			s_IDLE, s_BALL_DELAY, s_Z_LIFT, s_X_RIGHT, s_Z_LOWER, s_X_LEFT
		);


	signal r_Section_01 : t_Section_01 := s_IDLE;
	signal r_Section_02 : t_Section_02 := s_IDLE;
	signal r_Section_03 : t_Section_01 := s_IDLE;

	signal r_Counter_Section_01 : INTEGER range 0 to c_TWO_SECONDS := 0;
	signal r_Counter_Section_02 : INTEGER range 0 to c_TWO_SECONDS := 0;
	signal r_Counter_Section_03 : INTEGER range 0 to c_TWO_SECONDS := 0;

	signal r_StepperEnableX : STD_LOGIC := '0';
	signal r_StepperEnableZ : STD_LOGIC := '0';

	signal r_StepperSpeedX : STD_LOGIC := '0';
	signal r_StepperSpeedZ : STD_LOGIC := '0';

	signal r_StepperDirectionX : STD_LOGIC := '0';
	signal r_StepperDirectionZ : STD_LOGIC := '0';

	signal w_Actuator_S01 : STD_LOGIC := '0';
	signal w_Motor_S03 : STD_LOGIC := '0';
	signal w_ElectroMagnet : STD_LOGIC := '0';

	signal w_Reset : STD_LOGIC := '0';

	begin
		----------------------------------------------------------------------------------
		-- Static assignment
		----------------------------------------------------------------------------------
		w_Reset <= not i_Reset;

		o_LEDR(5) <= o_Driver_A_A_S3;
		o_LEDR(4) <= o_Driver_B_A_S2;
		o_LEDR(3) <= o_Driver_A_A_S1;
		o_LEDR(2) <= i_Section_03_Sensor;
		o_LEDR(1) <= not i_Section_02_Sensor;
		o_LEDR(0) <= not i_Section_01_Sensor;

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

		-- This will be used for actuator and electro magnet so reversing polarity does the samething so direction is set '0'
		Motor_Driver_1_init : entity work.L9110_2_CHANNEL_MOTOR_DRIVER
			generic map(
				g_CLOCK_FREQUENCY => c_CLOCK_FREQUENCY,
				g_A_PWM_FREQUENCY => c_DC_MOTOR_PWM_FREQUENCY,
				g_B_PWM_FREQUENCY => c_DC_MOTOR_PWM_FREQUENCY
			)
			port map(
				i_A_Speed => (others => w_Actuator_S01),
				i_A_Direction => c_OFF,
				i_B_Speed => (others => w_ElectroMagnet),
				i_B_Direction => c_OFF,
				i_Clock => i_Clock,
				o_A_i_A => o_Driver_A_A_S1,
				o_A_i_B => o_Driver_A_B_S1,
				o_B_i_A => o_Driver_B_A_S2,
				o_B_i_B => o_Driver_B_B_S2
		);
		-- This will be used for a DC MOTOR for the final exit
		Motor_Driver_2_init : entity work.L9110_2_CHANNEL_MOTOR_DRIVER
			generic map(
				g_CLOCK_FREQUENCY => c_CLOCK_FREQUENCY,
				g_A_PWM_FREQUENCY => c_DC_MOTOR_PWM_FREQUENCY,
				g_B_PWM_FREQUENCY => c_DC_MOTOR_PWM_FREQUENCY
			)
			port map(
				i_A_Speed => (others => w_Motor_S03),
				i_A_Direction => c_OFF,
				i_B_Speed => (others => c_DONT_CARE),
				i_B_Direction => c_OFF,
				i_Clock => i_Clock,
				o_A_i_A => o_Driver_A_A_S3,
				o_A_i_B => o_Driver_A_B_S3,
				o_B_i_A => open,
				o_B_i_B => open
		);

		Stepper_Motor_X_init : entity work.Motor_StepperSequencer
			generic map(
				g_CLOCK_FREQUENCY => c_CLOCK_FREQUENCY,
				g_MIN_DELAY => 60_000,
				g_MAX_DELAY => 180_000
			)
			port map(
				i_Enable => r_StepperEnableX,
				i_Direction => r_StepperDirectionX,
				i_Clock => i_Clock,
				i_Speed => (others => r_StepperSpeedX),
				o_Coils => o_Stepper_Motor_X
		);

		Stepper_Motor_Z_init : entity work.Motor_StepperSequencer
			generic map(
				g_CLOCK_FREQUENCY => c_CLOCK_FREQUENCY,
				g_MIN_DELAY => 60_000,
				g_MAX_DELAY => 180_000
			)
			port map(
				i_Enable => r_StepperEnableZ,
				i_Direction => r_StepperEnableZ,
				i_Clock => i_Clock,
				i_Speed => (others => r_StepperSpeedZ),
				o_Coils => o_Stepper_Motor_Z
		);

		p_SECTION_01 : process(i_Clock, w_Reset) begin
			if w_Reset = '1' then
				r_Section_01 <= s_IDLE;

			elsif rising_edge(i_Clock)then
				case r_Section_01 is
					when s_IDLE =>
						r_Section_01 <= s_IDLE;
						r_Counter_Section_01 <= 0;
						w_Actuator_S01 <= c_OFF;
						if i_Section_01_Sensor = c_OFF then
							r_Section_01 <= s_BALL_DELAY;
						end if;

					when s_BALL_DELAY =>
						r_Section_01 <= s_BALL_DELAY;
						if r_Counter_Section_01 < c_TWO_SECONDS - 1 then
							r_Section_01 <= s_BALL_DELAY;
							r_Counter_Section_01 <= r_Counter_Section_01 + 1;
						else
							r_Counter_Section_01 <= 0;
							w_Actuator_S01 <= c_ON;
							r_Section_01 <= s_ACTIVE;
						end if;

					when s_ACTIVE =>
						r_Section_01 <= s_ACTIVE;
						w_Actuator_S01 <= '1';
						if r_Counter_Section_01 < c_TWO_SECONDS - 1 then
							r_Section_01 <= s_ACTIVE;
							r_Counter_Section_01 <= r_Counter_Section_01 + 1;
						else
							r_Counter_Section_01 <= 0;
							w_Actuator_S01 <= c_OFF;
							r_Section_01 <= s_IDLE;
						end if;
				end case;
			end if;

		end process p_SECTION_01;


		p_SECTION_02 : process(i_Clock, i_Reset) begin
			if w_Reset = c_ON then
				r_Section_02 <= s_IDLE;

				if i_End_Stop_X(0) = c_ON then
					r_StepperEnableX <= c_ON;
					r_StepperDirectionX <= c_X_LEFT;
					r_StepperSpeedX <= c_ON;
				else
					r_StepperEnableX <= c_OFF;
					r_StepperDirectionX <= c_DONT_CARE;
					r_StepperSpeedX <= c_OFF;
				end if;

				if i_End_Stop_X(1) = c_ON then
					r_StepperEnableX <= c_ON;
					r_StepperDirectionX <= c_X_RIGHT;
					r_StepperSpeedX <= c_ON;
				else
					r_StepperEnableX <= c_OFF;
					r_StepperDirectionX <= c_DONT_CARE;
					r_StepperSpeedX <= c_OFF;
				end if;

				if i_End_Stop_Z(0) = c_ON then
					r_StepperEnableZ <= c_ON;
					r_StepperDirectionZ <= c_Z_LOWER;
					r_StepperSpeedZ <= c_ON;
				else
					r_StepperEnableX <= c_OFF;
					r_StepperDirectionX <= c_OFF;
					r_StepperSpeedX <= c_OFF;
				end if;

				if i_End_Stop_Z(1) = c_ON then
					r_StepperEnableZ <= c_ON;
					r_StepperDirectionZ <= c_Z_LIFT;
					r_StepperSpeedZ <= c_ON;
				else
					r_StepperEnableZ <= c_OFF;
					r_StepperDirectionZ <= c_DONT_CARE;
					r_StepperSpeedZ <= c_OFF;
				end if;

			elsif rising_edge(i_Clock)then
				case r_Section_02 is
					when s_IDLE =>
						r_Section_02 <= s_IDLE;
						r_Counter_Section_02 <= 0;
						w_ElectroMagnet <= c_OFF;
						if i_Section_02_Sensor = c_ON then
							r_Section_02 <= s_BALL_DELAY;
						end if;
						if i_End_Stop_X(0) = c_ON then
							r_StepperEnableX <= c_ON;
							r_StepperDirectionX <= c_X_RIGHT;
							r_StepperSpeedX <= c_ON;
						else
							r_StepperEnableX <= c_OFF;
							r_StepperDirectionX <= c_DONT_CARE;
							r_StepperSpeedX <= c_OFF;
						end if;

						if i_End_Stop_X(1) = c_ON then
							r_StepperEnableX <= c_ON;
							r_StepperDirectionX <= c_X_LEFT;
							r_StepperSpeedX <= c_ON;
						else
							r_StepperEnableX <= c_OFF;
							r_StepperDirectionX <= c_DONT_CARE;
							r_StepperSpeedX <= c_OFF;
						end if;

						if i_End_Stop_Z(0) = c_ON then
							r_StepperEnableZ <= c_ON;
							r_StepperDirectionZ <= c_Z_LOWER;
							r_StepperSpeedZ <= c_ON;
						else
							r_StepperEnableZ <= c_OFF;
							r_StepperDirectionZ <= c_DONT_CARE;
							r_StepperSpeedZ <= c_OFF;
						end if;

						if i_End_Stop_Z(1) = c_ON then
							r_StepperEnableZ <= c_ON;
							r_StepperDirectionZ <= c_Z_LIFT;
							r_StepperSpeedZ <= c_ON;
						else
							r_StepperEnableZ <= c_OFF;
							r_StepperDirectionZ <= c_DONT_CARE;
							r_StepperSpeedZ <= c_OFF;
						end if;

					when s_BALL_DELAY =>
						r_Section_02 <= s_BALL_DELAY;
						if r_Counter_Section_02 < c_TWO_SECONDS - 1 then
							r_Section_02 <= s_BALL_DELAY;
							r_Counter_Section_02 <= r_Counter_Section_02 + 1;
						else
							r_Counter_Section_02 <= 0;
							w_ElectroMagnet <= c_OFF;
							r_Section_02 <= s_Z_LIFT;
						end if;

					when s_Z_LIFT =>
						r_Section_02 <= s_Z_LIFT;
						r_StepperEnableZ <= c_ON;
						r_StepperDirectionZ <= c_Z_LIFT;
						r_StepperSpeedZ <= c_ON;
						if i_End_Stop_Z(0) = c_ON then
							r_StepperEnableZ <= c_OFF;
							r_StepperDirectionZ <= c_DONT_CARE;
							r_StepperSpeedZ <= c_OFF;
							if w_ElectroMagnet = c_OFF then
								r_Section_02 <= s_X_RIGHT;
							else
								r_Section_02 <= s_X_LEFT;
							end if;
						end if;

					when s_X_RIGHT =>
						r_Section_02 <= s_X_RIGHT;
						r_StepperEnableX <= c_ON;
						r_StepperDirectionX <= c_X_RIGHT;
						r_StepperSpeedX <= c_ON;
						if i_End_Stop_X(1) = c_ON then
							r_StepperEnableX <= c_OFF;
							r_StepperDirectionX <= c_DONT_CARE;
							r_StepperSpeedX <= c_OFF;
							r_Section_02 <= s_Z_LOWER;
						end if;

					-- can add extra logic to make it go back to idle but i think it always moving might be fun
					when s_Z_LOWER =>
						r_Section_02 <= s_Z_LOWER;
						r_StepperEnableZ <= c_ON;
						r_StepperDirectionZ <= c_Z_LOWER;
						r_StepperSpeedZ <= c_ON;
						if i_End_Stop_Z(1) = c_ON then
							r_StepperEnableZ <= c_OFF;
							r_StepperDirectionZ <= c_DONT_CARE;
							r_StepperSpeedZ <= c_OFF;
							w_ElectroMagnet <= not w_ElectroMagnet;
							if w_ElectroMagnet <= c_ON then
								r_Section_02 <= s_Z_LIFT;
							else
								r_Section_02 <= s_IDLE;
							end if;
						end if;

					when s_X_LEFT =>
						r_Section_02 <= s_X_LEFT;
						r_StepperEnableX <= c_ON;
						r_StepperDirectionX <= c_X_LEFT;
						r_StepperSpeedX <= c_ON;
						if i_End_Stop_X(0) = c_ON then
							r_StepperEnableX <= c_OFF;
							r_StepperDirectionX <= c_DONT_CARE;
							r_StepperSpeedX <= c_OFF;
							r_Section_02 <= s_Z_LOWER;
						end if;
				end case;
			end if;
		end process p_SECTION_02;


		p_SECTION_03 : process(i_Clock, w_Reset) begin
			if w_Reset = '1' then
				r_Section_03 <= s_IDLE;

			elsif rising_edge(i_Clock)then
				case r_Section_03 is
					when s_IDLE =>
						r_Section_03 <= s_IDLE;
						r_Counter_Section_03 <= 0;
						w_Motor_S03 <= c_OFF;
						if i_Section_03_Sensor = c_OFF then
							r_Section_03 <= s_BALL_DELAY;
						end if;

					when s_BALL_DELAY =>
						r_Section_03 <= s_BALL_DELAY;
						if r_Counter_Section_03 < c_TWO_SECONDS - 1 then
							r_Section_03 <= s_BALL_DELAY;
							r_Counter_Section_03 <= r_Counter_Section_03 + 1;
						else
							r_Counter_Section_03 <= 0;
							w_Motor_S03 <= c_ON;
							r_Section_03 <= s_ACTIVE;
						end if;

					when s_ACTIVE =>
						r_Section_03 <= s_ACTIVE;
						w_Motor_S03 <= '1';
						if r_Counter_Section_03 < c_TWO_SECONDS - 1 then
							r_Section_03 <= s_ACTIVE;
							r_Counter_Section_03 <= r_Counter_Section_03 + 1;
						else
							r_Counter_Section_03 <= 0;
							w_Motor_S03 <= c_OFF;
							r_Section_03 <= s_IDLE;
						end if;
				end case;
			end if;

		end process p_SECTION_03;
end Behavioral;

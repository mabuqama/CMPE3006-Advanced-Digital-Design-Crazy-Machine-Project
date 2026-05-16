library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity top_module is
	port (
		i_Clock     : in  STD_LOGIC;
		i_Reset    : in  STD_LOGIC;
		i_Button    : in  STD_LOGIC;
		o_UART_TX   : out STD_LOGIC;
		i_UART_RX   : in  STD_LOGIC;
		o_Speaker   : out  STD_LOGIC;
		i_Pressure_Sensor   : in  STD_LOGIC;
		i_LightSensor : in  STD_LOGIC;
		o_Motor_A_A  : out STD_LOGIC; 
		o_Motor_A_B  : out STD_LOGIC;
		o_Motor_B_A  : out STD_LOGIC; 
		o_Motor_B_B  : out STD_LOGIC;
		i_Switch    : in  STD_LOGIC_VECTOR (9 downto 0);
		o_LEDR      : out STD_LOGIC_VECTOR (9 downto 0)

	);
end top_module;

architecture Behavioral of top_module is

	constant c_CLOCK_FREQUENCY : INTEGER := 50_000_000;

	constant c_DC_Motor_PWM_FREQUENCY : INTEGER := 200_000;

	constant c_TWO_SECONDS : INTEGER := 100_000_000;

	type t_Section_01 is (
			s_IDLE, s_BALL_DELAY, s_ACTUATE
		);

	signal r_Section_01 : t_Section_01 := s_IDLE;

	signal r_Counter_Section_01 : INTEGER range 0 to c_TWO_SECONDS := 0;

	signal w_Actuator : STD_LOGIC := '0';
	signal w_Reset : STD_LOGIC;

	begin
		----------------------------------------------------------------------------------
		-- Static assignment
		----------------------------------------------------------------------------------
		w_Reset <= not i_Reset;
		o_LEDR(8) <= o_Motor_A_A;
		o_LEDR(9) <= o_Motor_A_B;
		o_LEDR(0) <= not i_Pressure_Sensor;
		o_LEDR(2) <= not i_LightSensor;

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

		Motor_Driver_init : entity work.L9110_2_CHANNEL_MOTOR_DRIVER
			generic map(
				g_CLOCK_FREQUENCY => c_CLOCK_FREQUENCY,
				g_A_PWM_FREQUENCY => c_DC_MOTOR_PWM_FREQUENCY,
				g_B_PWM_FREQUENCY => c_DC_MOTOR_PWM_FREQUENCY
			)
			port map(
				i_A_Speed => (others => w_Actuator),
				i_A_Direction => '0',
				i_B_Speed => (others => '0'),
				i_B_Direction => '0',
				i_Clock => i_Clock,
				o_A_i_A => o_Motor_A_A,
				o_A_i_B => o_Motor_A_B,
				o_B_i_A => o_Motor_B_A,
				o_B_i_B => o_Motor_B_B
		);

		p_SECTION_01 : process(i_Clock, i_Reset) begin
			if w_Reset = '1' then
				r_Section_01 <= s_IDLE;

			elsif rising_edge(i_Clock)then
				case r_Section_01 is
					when s_IDLE =>
						r_Section_01 <= s_IDLE;
						r_Counter_Section_01 <= 0;
						w_Actuator <= '0';
						if i_Pressure_Sensor = '1' then
							r_Section_01 <= s_BALL_DELAY;
						end if;

					when s_BALL_DELAY =>
						r_Section_01 <= s_BALL_DELAY;
						if r_Counter_Section_01 < c_TWO_SECONDS - 1 then
							r_Section_01 <= s_BALL_DELAY;
							r_Counter_Section_01 <= r_Counter_Section_01 + 1;
						else
							r_Counter_Section_01 <= 0;
							w_Actuator <= '1';
							r_Section_01 <= s_ACTUATE;
						end if;

					when s_ACTUATE =>
						r_Section_01 <= s_ACTUATE;
						w_Actuator <= '1';
						if r_Counter_Section_01 < c_TWO_SECONDS - 1 then
							r_Section_01 <= s_ACTUATE;
							r_Counter_Section_01 <= r_Counter_Section_01 + 1;
						else
							r_Counter_Section_01 <= 0;
							w_Actuator <= '0';
							r_Section_01 <= s_IDLE;
						end if;
				end case;
			end if;

		end process p_SECTION_01;

end Behavioral;

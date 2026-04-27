LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;


entity L9110_2_CHANNEL_MOTOR_DRIVER is
	generic(
		g_CLOCK_FREQUENCY : INTEGER := 50_000_000;
		g_A_PWM_FREQUENCY   : INTEGER := 20_000;
		g_B_PWM_FREQUENCY   : INTEGER := 20_000
	);
	port(
		i_A_Speed : in STD_LOGIC_VECTOR (7 downto 0) := (others => '0');
		i_A_Direction : in STD_LOGIC := '0';
		i_B_Speed : in STD_LOGIC_VECTOR (7 downto 0) := (others => '0');
		i_B_Direction : in STD_LOGIC := '0';
		i_Clock : in STD_LOGIC;
		o_A_i_A : out STD_LOGIC := '0';
		o_A_i_B : out STD_LOGIC := '0';
		o_B_i_A : out STD_LOGIC := '0';
		o_B_i_B : out STD_LOGIC := '0'
	);
end L9110_2_CHANNEL_MOTOR_DRIVER;

architecture Behavioral of L9110_2_CHANNEL_MOTOR_DRIVER is

	signal w_A_Motor_PWM: STD_LOGIC;
	signal w_B_Motor_PWM : STD_LOGIC;


	begin
		PWM_A_init : entity work.Motor_PulseWidthModulation
			generic map(
				g_CLOCK_FREQUENCY => g_CLOCK_FREQUENCY,
				g_PWM_FREQUENCY => g_A_PWM_FREQUENCY
			)
			port map(
				i_Clock => i_Clock,
				i_Duty_Cycle => i_A_Speed,
				o_PWM_Signal => w_A_Motor_PWM
		);

		PWM_B_init : entity work.Motor_PulseWidthModulation
			generic map(
				g_CLOCK_FREQUENCY => g_CLOCK_FREQUENCY,
				g_PWM_FREQUENCY => g_B_PWM_FREQUENCY
			)
			port map(
				i_Clock => i_Clock,
				i_Duty_Cycle => i_B_Speed,
				o_PWM_Signal => w_B_Motor_PWM
		);

		p_MAIN : process(all) begin
			case i_A_Direction is
				when '0' =>
					o_A_i_A <= w_A_Motor_PWM;
					o_A_i_B <= '0';
				when '1' =>
					o_A_i_A <= '0';
					o_A_i_B <= w_A_Motor_PWM;
				when others =>
					o_A_i_A <= '0';
					o_A_i_B <= '0';
			end case;

			case i_B_Direction is
				when '0' =>
					o_B_i_A <= w_B_Motor_PWM;
					o_B_i_B <= '0';
				when '1' => 
					o_B_i_A <= '0';
					o_B_i_B <= w_B_Motor_PWM;
				when others =>
					o_B_i_A <= '0';
					o_B_i_B <= '0';
			end case;
		end process p_MAIN;
end Behavioral;

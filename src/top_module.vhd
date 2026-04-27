library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity top_module is
	port (
		i_Clock     : in  STD_LOGIC;
		i_Button    : in  STD_LOGIC;
		o_UART_TX   : out STD_LOGIC;
		i_UART_RX   : in  STD_LOGIC;
		o_Motor_A_A  : out STD_LOGIC; 
		o_Motor_A_B  : out STD_LOGIC;
		i_Switch    : in  STD_LOGIC_VECTOR (9 downto 0);
		o_LEDR      : out STD_LOGIC_VECTOR (9 downto 0)
	);
end top_module;

architecture Behavioral of top_module is

	constant c_CLOCK_FREQUENCY : INTEGER := 50_000_000;

	constant c_DC_Motor_PWM_FREQUENCY : INTEGER := 200_000;

begin
	Motor_Driver_init : entity work.L9110_2_CHANNEL_MOTOR_DRIVER
		generic map(
			g_CLOCK_FREQUENCY => c_CLOCK_FREQUENCY,
			g_A_PWM_FREQUENCY => c_DC_Motor_PWM_FREQUENCY,
			g_B_PWM_FREQUENCY => c_DC_Motor_PWM_FREQUENCY
		)
		port map(
			i_A_Speed => i_Switch(7 downto 0),
			i_A_Direction => not i_Button,
			i_B_Speed => (others => '0'),
			i_B_Direction => '0',
			i_Clock => i_Clock,
			o_A_i_A => o_Motor_A_A,
			o_A_i_B => o_Motor_A_B,
			o_B_i_A => open,
			o_B_i_B => open
	);
	o_LEDR(7 downto 0) <= i_Switch(7 downto 0);
	o_LEDR(8) <= o_Motor_A_A;
	o_LEDR(9) <= o_Motor_A_B;

end Behavioral;

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
		i_Pressure_Sensor   : in  STD_LOGIC;
		o_Motor_A_A  : out STD_LOGIC; 
		o_Motor_A_B  : out STD_LOGIC;
		o_Motor_B_A  : out STD_LOGIC; 
		o_Motor_B_B  : out STD_LOGIC;
		o_Stepper_Motor_A : out STD_LOGIC_VECTOR (3 downto 0);
		i_Switch    : in  STD_LOGIC_VECTOR (9 downto 0);
		o_LEDR      : out STD_LOGIC_VECTOR (9 downto 0)
	);
end top_module;

architecture Behavioral of top_module is

	constant c_CLOCK_FREQUENCY : INTEGER := 50_000_000;

	begin
		Stepper_Sequencer_init : entity work.Motor_StepperSequencer
			generic map(
				g_CLOCK_FREQUENCY => c_CLOCK_FREQUENCY,
				g_MIN_DELAY => 60_000,
				g_MAX_DELAY => 180_000
			)
			port map(
				i_Enable => i_Switch(0),
				i_Direction => i_Switch(1),
				i_Clock => i_Clock,
				i_Speed => i_Switch(9 downto 2),
				o_Coils => o_Stepper_Motor_A
		);

	o_LEDR <= i_Switch;
end Behavioral;

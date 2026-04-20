library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity top_module is
	port (
		i_Clock     : in  STD_LOGIC;
		i_Button    : in  STD_LOGIC;
		o_PWM       : out STD_LOGIC;
		o_UART_TX   : out STD_LOGIC;
		i_UART_RX   : in  STD_LOGIC;
		o_PWMmotor  : out STD_LOGIC; 
		o_DIR       : out STD_LOGIC;
		o_NOTDIR       : out STD_LOGIC; 
		i_Switch    : in  STD_LOGIC_VECTOR (9 downto 0);
		o_LEDR      : out STD_LOGIC_VECTOR (9 downto 0)
	);
end top_module;

architecture Behavioral of top_module is


begin
	o_LEDR <= (others => i_Button);

end Behavioral;

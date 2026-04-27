LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

entity Motor_PulseWidthModulation is
	generic(
		g_CLOCK_FREQUENCY : INTEGER := 125_000_000;
		g_PWM_FREQUENCY   : INTEGER := 20_000
	);
	Port(
		i_Clock : in STD_LOGIC;
		i_Duty_Cycle : in STD_LOGIC_VECTOR (7 downto 0);
		o_PWM_Signal : out STD_LOGIC
	);
end Motor_PulseWidthModulation;

architecture Behavioral of Motor_PulseWidthModulation is

	constant c_PERIOD_TICKS : INTEGER := g_CLOCK_FREQUENCY / g_PWM_FREQUENCY;

	signal r_Clock_Count : INTEGER := 0;
	signal r_PulseTicks : integer;

	begin
	r_PulseTicks <= (to_integer(unsigned(i_Duty_Cycle)) * c_PERIOD_TICKS) / 255;

	p_PWM_SIGNAL : process(i_Clock) begin
		if rising_edge(i_Clock) then
			if r_Clock_Count = c_PERIOD_TICKS - 1 then
				r_Clock_Count <= 0;
			else
				r_Clock_Count <= r_Clock_Count + 1;
			end if;

			if r_Clock_Count < r_PulseTicks then
				o_PWM_Signal <= '1';
			else
				o_PWM_Signal <= '0';
			end if;
		end if;
	end process p_PWM_SIGNAL;


end Behavioral;

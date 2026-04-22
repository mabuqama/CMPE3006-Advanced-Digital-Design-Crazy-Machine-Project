LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

entity PWM is
	generic(
		g_CLOCK_FREQUENCY : INTEGER := 125_000_000;
		g_PULSE_WIDTH_MAX : INTEGER := 2_100;
		g_PULSE_WIDTH_MIN : INTEGER := 900;
		g_FRAME : INTEGER := 20_000
	);
	Port(
		i_Clock : in STD_LOGIC;
		i_Duty_Cycle : in UNSIGNED (7 downto 0);
		o_PWM_Signal : out STD_LOGIC
	);
end PWM;

architecture Behavioral of PWM is

	constant c_FRAME_TICKS : INTEGER := g_CLOCK_FREQUENCY / 1_000_000 * g_FRAME;
	constant c_MAX_TICKS : INTEGER := g_CLOCK_FREQUENCY / 1_000_000 * g_PULSE_WIDTH_MAX;
	constant c_MIN_TICKS : INTEGER := g_CLOCK_FREQUENCY / 1_000_000 * g_PULSE_WIDTH_MIN;

	signal r_Clock_Count : INTEGER := 0;
	signal r_PulseTicks : integer;

	begin
	r_PulseTicks <= c_MIN_TICKS + (to_integer(i_Duty_Cycle) * (c_MAX_TICKS - c_MIN_TICKS)) / 255;

	p_PWM_SIGNAL : process(i_Clock) begin
		if rising_edge(i_Clock) then
			if r_Clock_Count = c_FRAME_TICKS - 1 then
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

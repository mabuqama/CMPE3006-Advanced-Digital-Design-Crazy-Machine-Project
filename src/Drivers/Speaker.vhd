LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

entity Speaker is
	generic(
		g_CLOCK_FREQUENCY : INTEGER := 50_000_000;
		g_PWM_FREQUENCY   : INTEGER := 20_000
	);
	Port (
		i_Clock : in STD_LOGIC;
		o_Speaker: out STD_LOGIC
	);
end Speaker;

architecture Behavioral of speaker is

	type t_Song is array (0 to 15) of integer;
	constant c_Song : t_Song := (
		440, 440, 440, 349, 440, 440, 440, 349, 
		440, 440, 440, 349, 440, 440, 440, 349
	);
	signal r_NoteIndex : integer range 0 to 15 := 0;
	signal r_Counter : integer := 0;
	signal r_PWMDuty : STD_LOGIC_VECTOR (7 downto 0) := (others => '0');

	begin
		PWM_init : entity work.Motor_PulseWidthModulation
			generic map(
				g_CLOCK_FREQUENCY => g_CLOCK_FREQUENCY,
				g_PWM_FREQUENCY => g_PWM_FREQUENCY
			)
			port map(
				i_Clock => i_Clock,
				i_Duty_Cycle => r_PWMDuty,
				o_PWM_Signal => o_Speaker
		);

		p_Song : process(i_Clock) begin
			if rising_edge(i_Clock) then
				if r_Counter = g_CLOCK_FREQUENCY / 2_000 then
					r_Counter <= 0;
					if r_NoteIndex = 15 then
						r_NoteIndex <= 0;
					else
						r_NoteIndex <= r_NoteIndex + 1;
					end if;
				else
					r_Counter <= r_Counter + 1;
				end if;

				r_PWMDuty <= std_logic_vector(to_unsigned(128,8)); 
			end if;
		end process;

end Behavioral;

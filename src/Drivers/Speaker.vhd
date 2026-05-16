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

	-- Tiny 5-second chiptune (square wave frequencies in Hz)
	type t_Song is array (0 to 15) of integer;
	constant c_Song : t_Song := (
		440, 494, 523, 440, 440, 440, 494, 523, 
		440, 494, 523, 440, 440, 392, 440, 440
	);

	signal r_NoteIndex : integer range 0 to 15 := 0;
	signal r_Counter : integer := 0;
	signal r_PWMCounter : integer := 0;
	signal r_PWMDuty : STD_LOGIC_VECTOR (7 downto 0) := (others => '0');
	signal r_Square : STD_LOGIC := '0';

begin
	-- Instantiate your PWM module
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

	p_Song : process(i_Clock)
		variable halfPeriod : integer := 0;
	begin
		if rising_edge(i_Clock) then

			-- Determine half-period of current note in FPGA clocks
			halfPeriod := g_CLOCK_FREQUENCY / (2 * c_Song(r_NoteIndex));

			-- Square wave generation
			if r_PWMCounter >= halfPeriod then
				r_PWMCounter <= 0;
				if r_Square = '0' then
					r_Square <= '1';
				else
					r_Square <= '0';
				end if;
			else
				r_PWMCounter <= r_PWMCounter + 1;
			end if;

			-- Map square wave to PWM duty cycle (simple on/off)
			if r_Square = '1' then
				r_PWMDuty <= std_logic_vector(to_unsigned(200,8));  -- high
			else
				r_PWMDuty <= std_logic_vector(to_unsigned(50,8));   -- low
			end if;

			-- Advance note every ~0.25 seconds (adjust as needed)
			if r_Counter >= g_CLOCK_FREQUENCY / 4 then
				r_Counter <= 0;
				if r_NoteIndex = 15 then
					r_NoteIndex <= 0;  -- loop the song
				else
					r_NoteIndex <= r_NoteIndex + 1;
				end if;
			else
				r_Counter <= r_Counter + 1;
			end if;

		end if;
	end process;

end Behavioral;

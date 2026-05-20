LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

entity A4988_Stepper_Motor_Driver is
	generic(
		g_CLOCK_FREQUENCY : INTEGER := 50_000_000;
		g_MIN_DELAY	   : INTEGER := 1_000;
		g_MAX_DELAY	   : INTEGER := 100_000;
		g_STEP_PULSE	  : INTEGER := 500
	);
	port(
		i_Clock	  : in  STD_LOGIC;
		i_Enable	 : in  STD_LOGIC;
		i_Direction  : in  STD_LOGIC;
		i_Speed	  : in  STD_LOGIC_VECTOR(7 downto 0);

		o_Enable	 : out STD_LOGIC;
		o_Direction  : out STD_LOGIC;
		o_Step	   : out STD_LOGIC
	);
end A4988_Stepper_Motor_Driver;

architecture Behavioral of A4988_Stepper_Motor_Driver is

	type t_State is (
		s_IDLE,
		s_STEP_HIGH,
		s_STEP_LOW
	);

	signal r_State : t_State := s_IDLE;

	signal r_Delay_Count : INTEGER := 0;
	signal r_Pulse_Count : INTEGER := 0;

	signal r_Target_Delay : INTEGER := g_MAX_DELAY;

	signal r_Step : STD_LOGIC := '0';

begin

	o_Direction <= i_Direction;

	o_Enable <= i_Enable;

	o_Step <= r_Step;

	p_Speed_Map : process(i_Speed)
	begin

		r_Target_Delay <= g_MAX_DELAY -
			(to_integer(unsigned(i_Speed)) *
			(g_MAX_DELAY - g_MIN_DELAY)) / 255;

	end process;

	p_Stepper : process(i_Clock)
		begin
			if rising_edge(i_Clock) then

				if i_Enable = '0' then

					r_State <= s_IDLE;
					r_Step <= '0';

					r_Delay_Count <= 0;
					r_Pulse_Count <= 0;

				else

					case r_State is

						when s_IDLE =>

							r_Step <= '0';

							if r_Delay_Count >= r_Target_Delay then
								r_Delay_Count <= 0;
								r_State <= s_STEP_HIGH;
							else
								r_Delay_Count <= r_Delay_Count + 1;
							end if;

						when s_STEP_HIGH =>

							r_Step <= '1';

							if r_Pulse_Count >= g_STEP_PULSE then
								r_Pulse_Count <= 0;
								r_State <= s_STEP_LOW;
							else
								r_Pulse_Count <= r_Pulse_Count + 1;
							end if;

						when s_STEP_LOW =>

							r_Step <= '0';
							r_State <= s_IDLE;

						when others =>

							r_State <= s_IDLE;

					end case;

				end if;

			end if;
	end process;

end Behavioral;

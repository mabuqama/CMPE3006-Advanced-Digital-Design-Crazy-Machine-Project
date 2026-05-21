LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

entity A4988_Stepper_Motor_Driver is
	generic(
		g_CLOCK_FREQUENCY : INTEGER := 50_000_000;
		g_STEP_RATE_HZ    : INTEGER := 1000;
		g_STEP_PULSE      : INTEGER := 100   -- safe default ~2 µs @ 50MHz
	);
	port(
		i_Clock     : in  STD_LOGIC;
		i_Enable    : in  STD_LOGIC;
		i_Direction : in  STD_LOGIC;

		o_Enable    : out STD_LOGIC;
		o_Direction : out STD_LOGIC;
		o_Step      : out STD_LOGIC
	);
end A4988_Stepper_Motor_Driver;

architecture Behavioral of A4988_Stepper_Motor_Driver is

	constant c_STEP_INTERVAL : INTEGER :=
		g_CLOCK_FREQUENCY / g_STEP_RATE_HZ;

	type t_State is (
		s_IDLE,
		s_STEP_HIGH,
		s_STEP_LOW
	);

	signal r_State : t_State := s_IDLE;

	signal r_Counter    : INTEGER range 0 to c_STEP_INTERVAL := 0;
	signal r_Step       : STD_LOGIC := '0';
	signal r_Direction  : STD_LOGIC := '0';

begin

	o_Enable    <= not i_Enable;
	o_Step      <= r_Step;
	o_Direction <= r_Direction;

process(i_Clock)
begin
	if rising_edge(i_Clock) then

		----------------------------------------------------------------
		-- DISABLE / RESET
		----------------------------------------------------------------
		if i_Enable = '0' then
			r_State      <= s_IDLE;
			r_Counter    <= 0;
			r_Step       <= '0';

		else

			case r_State is

				------------------------------------------------------------
				-- IDLE: start cycle cleanly
				------------------------------------------------------------
				when s_IDLE =>
					r_Counter   <= 0;
					r_Step      <= '0';
					r_State     <= s_STEP_HIGH;

				------------------------------------------------------------
				-- STEP HIGH PHASE
				------------------------------------------------------------
				when s_STEP_HIGH =>
					r_Step <= '1';

					if r_Counter >= g_STEP_PULSE then
						r_Counter <= 0;

						-- ✅ SAFE POINT: update direction ONLY here
						r_Direction <= i_Direction;

						r_State <= s_STEP_LOW;
					else
						r_Counter <= r_Counter + 1;
					end if;

				------------------------------------------------------------
				-- STEP LOW PHASE
				------------------------------------------------------------
				when s_STEP_LOW =>
					r_Step <= '0';

					if r_Counter >= c_STEP_INTERVAL then
						r_Counter <= 0;
						r_State   <= s_STEP_HIGH;
					else
						r_Counter <= r_Counter + 1;
					end if;

			end case;
		end if;

	end if;
end process;

end Behavioral;

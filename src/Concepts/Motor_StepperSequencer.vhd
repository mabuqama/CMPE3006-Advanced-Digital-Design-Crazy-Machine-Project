LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

entity Motor_StepperSequencer is
	generic(
		g_CLOCK_FREQUENCY : INTEGER := 125_000_000;
		g_MIN_DELAY	   : INTEGER := 100_000;
		g_MAX_DELAY	   : INTEGER := 5_000_000;
		g_STEPS_PER_REV   : INTEGER := 4096
	);
	Port(
		i_Clock : in STD_LOGIC;
		i_Enable : in STD_LOGIC;
		i_Direction : in STD_LOGIC;
		i_Speed : in STD_LOGIC_VECTOR (7 downto 0);
		o_Coils : out STD_LOGIC_VECTOR (3 downto 0)
	);
end Motor_StepperSequencer;

architecture Behavioral of Motor_StepperSequencer is

	type t_Motor_Step_State is (s_A, s_B, s_C, s_D);
	signal r_Step_State : t_Motor_Step_State := s_A;

	type t_Mode is (s_FREE, s_HOLD, s_RUN);
	signal r_Mode : t_Mode := s_FREE;

	signal r_Counter : INTEGER range 0 to g_MAX_DELAY := 0;
	signal r_Delay   : INTEGER range g_MIN_DELAY to g_MAX_DELAY := g_MIN_DELAY;

	signal r_Coils   : STD_LOGIC_VECTOR(3 downto 0) := "0000";

	begin

		o_Coils <= r_Coils;
		p_Stepper_Sequence : process(i_Clock) begin
			if rising_edge(i_Clock) then

				if i_Enable = '0' then
					r_Mode <= s_FREE;

				elsif i_Speed = "00000000" then
					r_Mode <= s_HOLD;

				else
					r_Mode <= s_RUN;
				end if;

				r_Delay <= g_MIN_DELAY +
						  (to_integer(unsigned(i_Speed)) *
						  (g_MAX_DELAY - g_MIN_DELAY)) / 255;

				case r_Mode is
					when s_FREE =>
						r_Counter <= 0;
						r_Coils <= "0000";

					when s_HOLD =>
						r_Counter <= 0;
						case r_Step_State is
							when s_A => r_Coils <= "1000";
							when s_B => r_Coils <= "0100";
							when s_C => r_Coils <= "0010";
							when s_D => r_Coils <= "0001";
						end case;

					when s_RUN =>
						if r_Counter < r_Delay then
							r_Counter <= r_Counter + 1;
						else
							r_Counter <= 0;
							if i_Direction = '0' then
								case r_Step_State is
									when s_A => r_Step_State <= s_B;
									when s_B => r_Step_State <= s_C;
									when s_C => r_Step_State <= s_D;
									when s_D => r_Step_State <= s_A;
								end case;
							else
								case r_Step_State is
									when s_A => r_Step_State <= s_D;
									when s_D => r_Step_State <= s_C;
									when s_C => r_Step_State <= s_B;
									when s_B => r_Step_State <= s_A;
								end case;
							end if;
						end if;

						case r_Step_State is
							when s_A => r_Coils <= "1000";
							when s_B => r_Coils <= "0100";
							when s_C => r_Coils <= "0010";
							when s_D => r_Coils <= "0001";
						end case;

				end case;

			end if;
		end process p_Stepper_Sequence;

end Behavioral;

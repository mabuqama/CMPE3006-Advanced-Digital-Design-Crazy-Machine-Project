library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity VGA_Rainbow is
	Generic(
		g_CLOCK_FREQUENCY : INTEGER := 25_000_000;

		g_PIXEL_CLOCK : INTEGER := 25_000_000;

		g_H_LEFT_BORDER : INTEGER := 8;
		g_H_BACK_PORCH : INTEGER := 40;
		g_H_ACTIVE_VIDEO : INTEGER := 640;
		g_H_FRONT_PORCH : INTEGER := 8;
		g_H_RIGHT_BORDER : INTEGER := 8;
		g_H_SYNC : INTEGER := 96;

		g_V_TOP_BORDER : INTEGER := 8;
		g_V_BACK_PORCH : INTEGER := 25;
		g_V_ACTIVE_VIDEO : INTEGER := 480;
		g_V_FRONT_PORCH : INTEGER := 2;
		g_V_BOTTOM_BORDER : INTEGER := 8;
		g_V_SYNC : INTEGER := 2;

		g_ANIMATION_SPEED : INTEGER := 1024
	);
	Port(
		i_Clock : in STD_LOGIC;

		o_VGA_R : out STD_LOGIC_VECTOR (3 downto 0);
		o_VGA_G : out STD_LOGIC_VECTOR (3 downto 0);
		o_VGA_B : out STD_LOGIC_VECTOR (3 downto 0);
		o_VGA_Vsync : out STD_LOGIC;
		o_VGA_Hsync : out STD_LOGIC
	);
end VGA_Rainbow;

architecture Behavioral of VGA_Rainbow is

	signal r_Shift : INTEGER range 0 to g_ANIMATION_SPEED - 1 := 0;

	signal w_Pixel_H : INTEGER range 0 to g_H_ACTIVE_VIDEO - 1 := 0;
	signal w_Pixel_V : INTEGER range 0 to g_V_ACTIVE_VIDEO - 1 := 0;
	signal w_Active : STD_LOGIC;

	signal r_RGB_R : STD_LOGIC_VECTOR (3 downto 0) := (others => '0');
	signal r_RGB_G : STD_LOGIC_VECTOR (3 downto 0) := (others => '0');
	signal r_RGB_B : STD_LOGIC_VECTOR (3 downto 0) := (others => '0');

	begin

		VGA_init : entity work.VideoGraphicsArray
			generic map(
				g_PIXEL_CLOCK => g_PIXEL_CLOCK,
				g_H_LEFT_BORDER => g_H_LEFT_BORDER,
				g_H_BACK_PORCH => g_H_BACK_PORCH,
				g_H_ACTIVE_VIDEO => g_H_ACTIVE_VIDEO,
				g_H_FRONT_PORCH => g_H_FRONT_PORCH,
				g_H_RIGHT_BORDER => g_H_RIGHT_BORDER,
				g_H_SYNC => g_H_SYNC,

				g_V_TOP_BORDER => g_V_TOP_BORDER,
				g_V_BACK_PORCH => g_V_BACK_PORCH,
				g_V_ACTIVE_VIDEO => g_V_ACTIVE_VIDEO,
				g_V_FRONT_PORCH => g_V_FRONT_PORCH,
				g_V_BOTTOM_BORDER => g_V_BOTTOM_BORDER,
				g_V_SYNC => g_V_SYNC
			)
			port map(
				i_Clock => i_Clock,

				i_VGA_R => r_RGB_R,
				i_VGA_G => r_RGB_G,
				i_VGA_B => r_RGB_B,

				o_VGA_R => o_VGA_R,
				o_VGA_G => o_VGA_G,
				o_VGA_B => o_VGA_B,

				o_VGA_Vsync => o_VGA_Vsync,
				o_VGA_Hsync => o_VGA_Hsync,
				o_Pixel_H => w_Pixel_H,
				o_Pixel_V => w_Pixel_V,
				o_Active => w_Active
		);

	process(i_Clock)
		variable v_val : INTEGER;
	begin
		if rising_edge(i_Clock) then

			r_Shift <= (r_Shift + 1) mod g_ANIMATION_SPEED;

			if w_Active = '1' then

				v_val := (w_Pixel_H + w_Pixel_V + r_Shift) mod 256;

				if v_val < 85 then
					r_RGB_R <= std_logic_vector(to_unsigned(v_val * 3 / 2, 4));
					r_RGB_G <= std_logic_vector(to_unsigned(255 - v_val * 3, 4));
					r_RGB_B <= std_logic_vector(to_unsigned(v_val, 4));

				elsif v_val < 170 then
					r_RGB_R <= std_logic_vector(to_unsigned(255 - v_val, 4));
					r_RGB_G <= std_logic_vector(to_unsigned(v_val * 2, 4));
					r_RGB_B <= std_logic_vector(to_unsigned(255 - v_val * 2, 4));

				else
					r_RGB_R <= std_logic_vector(to_unsigned(v_val, 4));
					r_RGB_G <= std_logic_vector(to_unsigned(255 - v_val, 4));
					r_RGB_B <= std_logic_vector(to_unsigned(v_val * 2, 4));
				end if;

			else
				r_RGB_R <= (others => '0');
				r_RGB_G <= (others => '0');
				r_RGB_B <= (others => '0');
			end if;

		end if;
	end process;

end Behavioral;

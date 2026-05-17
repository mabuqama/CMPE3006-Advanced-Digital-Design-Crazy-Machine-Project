library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- This is based upon the https://file.hstatic.net/1000180878/file/latest_vesa_vga_standard.pdf

entity VideoGraphicsArray is
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
		g_V_SYNC : INTEGER := 2
	);
	Port(
		i_Clock : in STD_LOGIC;

		i_VGA_R : in STD_LOGIC_VECTOR (3 downto 0);
		i_VGA_G : in STD_LOGIC_VECTOR (3 downto 0);
		i_VGA_B : in STD_LOGIC_VECTOR (3 downto 0);

		o_VGA_R : out STD_LOGIC_VECTOR (3 downto 0);
		o_VGA_G : out STD_LOGIC_VECTOR (3 downto 0);
		o_VGA_B : out STD_LOGIC_VECTOR (3 downto 0);

		o_VGA_Vsync : out STD_LOGIC;
		o_VGA_Hsync : out STD_LOGIC;

		o_Pixel_H : out INTEGER range 0 to g_H_ACTIVE_VIDEO - 1;
		o_Pixel_V : out INTEGER range 0 to g_V_ACTIVE_VIDEO - 1;
		o_Active  : out STD_LOGIC
	);
end VideoGraphicsArray;

architecture Behavioral of VideoGraphicsArray is

	constant c_CLOCK_PER_PIXELS : INTEGER := g_CLOCK_FREQUENCY / g_PIXEL_CLOCK;

	constant c_H_LEFT_BORDER_TICKS : INTEGER := ( c_CLOCK_PER_PIXELS * g_H_LEFT_BORDER ) - 1;
	constant c_H_BACK_PORCH_TICKS : INTEGER := ( c_CLOCK_PER_PIXELS * g_H_BACK_PORCH ) - 1;
	constant c_H_ACTIVE_VIDEO_TICKS : INTEGER := ( c_CLOCK_PER_PIXELS * g_H_ACTIVE_VIDEO ) - 1;
	constant c_H_FRONT_PORCH_TICKS : INTEGER := ( c_CLOCK_PER_PIXELS * g_H_FRONT_PORCH ) - 1;
	constant c_H_RIGHT_BORDER_TICKS : INTEGER := ( c_CLOCK_PER_PIXELS * g_H_RIGHT_BORDER ) - 1;
	constant c_H_SYNC_TICKS : INTEGER := ( c_CLOCK_PER_PIXELS * g_H_SYNC ) - 1;

	type t_H_State is(
		s_LEFT_BORDER, s_BACK_PORCH, s_ACTIVE_VIDEO,
		s_FRONT_PORCH, s_RIGHT_BORDER, s_H_SYNC,
		s_IDLE
	);

	type t_V_State is(
		s_TOP_BORDER, s_BACK_PORCH, s_ACTIVE_VIDEO,
		s_FRONT_PORCH, s_BOTTOM_BORDER, s_V_SYNC,
		s_IDLE
	);


	signal r_H_State : t_H_State := s_IDLE;
	signal r_V_State : t_V_State := s_IDLE;

	signal r_H_Count : INTEGER := 0;
	signal r_V_Count : INTEGER := 0;

	signal r_Active  : STD_LOGIC := '0';
	signal r_Pixel_H : INTEGER range 0 to g_H_ACTIVE_VIDEO - 1 := 0;
	signal r_Pixel_V : INTEGER range 0 to g_V_ACTIVE_VIDEO - 1 := 0;

	begin

	p_VideoGraphicsArray : process(i_Clock) begin
		if rising_edge(i_Clock) then
			o_VGA_Hsync <= '1';
			o_VGA_Vsync <= '1';

			if r_H_State = s_H_SYNC and r_H_Count = c_H_SYNC_TICKS then
				if r_V_State /= s_IDLE then
					r_V_Count <= r_V_Count + 1;
				end if;
			end if;

			if r_H_State = s_IDLE and r_H_Count = 0 then
				r_H_State <= s_LEFT_BORDER;
				r_H_Count <= 0;
			end if;

			if r_V_State = s_IDLE and r_V_Count = 0 then
				r_V_State <= s_TOP_BORDER;
				r_V_Count <= 0;
			end if;

			case r_H_State is
				when s_LEFT_BORDER =>
					if r_H_Count = c_H_LEFT_BORDER_TICKS then
						r_H_State <= s_BACK_PORCH;
						r_H_Count <= 0;
					else
						r_H_Count <= r_H_Count + 1;
					end if;

				when s_BACK_PORCH =>
					if r_H_Count = c_H_BACK_PORCH_TICKS then
						r_H_State <= s_ACTIVE_VIDEO;
						r_H_Count <= 0;
					else
						r_H_Count <= r_H_Count + 1;
					end if;

				when s_ACTIVE_VIDEO =>
					if r_H_Count = c_H_ACTIVE_VIDEO_TICKS then
						r_H_State <= s_FRONT_PORCH;
						r_H_Count <= 0;
					else
						r_H_Count <= r_H_Count + 1;
					end if;

				when s_FRONT_PORCH =>
					if r_H_Count = c_H_FRONT_PORCH_TICKS then
						r_H_State <= s_RIGHT_BORDER;
						r_H_Count <= 0;
					else
						r_H_Count <= r_H_Count + 1;
					end if;

				when s_RIGHT_BORDER =>
					if r_H_Count = c_H_RIGHT_BORDER_TICKS then
						r_H_State <= s_H_SYNC;
						r_H_Count <= 0;
					else
						r_H_Count <= r_H_Count + 1;
					end if;

				when s_H_SYNC =>
					o_VGA_Hsync <= '0';
					if r_H_Count = c_H_SYNC_TICKS then
						r_H_State <= s_LEFT_BORDER;
						r_H_Count <= 0;
					else
						r_H_Count <= r_H_Count + 1;
					end if;

				when s_IDLE =>
					r_H_Count <= 0;
			end case;

			case r_V_State is
				when s_TOP_BORDER =>
					if r_V_Count >= g_V_TOP_BORDER - 1 then
						r_V_State <= s_BACK_PORCH;
						r_V_Count <= 0;
					end if;

				when s_BACK_PORCH =>
					if r_V_Count >= g_V_BACK_PORCH - 1 then
						r_V_State <= s_ACTIVE_VIDEO;
						r_V_Count <= 0;
					end if;

				when s_ACTIVE_VIDEO =>
					if r_V_Count >= g_V_ACTIVE_VIDEO - 1 then
						r_V_State <= s_FRONT_PORCH;
						r_V_Count <= 0;
					end if;

				when s_FRONT_PORCH =>
					if r_V_Count >= g_V_FRONT_PORCH - 1 then
						r_V_State <= s_BOTTOM_BORDER;
						r_V_Count <= 0;
					end if;

				when s_BOTTOM_BORDER =>
					if r_V_Count >= g_V_BOTTOM_BORDER - 1 then
						r_V_State <= s_V_SYNC;
						r_V_Count <= 0;
					end if;

				when s_V_SYNC =>
					o_VGA_Vsync <= '0';
					if r_V_Count >= g_V_SYNC - 1 then
						r_V_State <= s_TOP_BORDER;
						r_V_Count <= 0;
					end if;

				when s_IDLE =>
					r_V_Count <= 0;
			end case;

			if r_H_State = s_ACTIVE_VIDEO and r_V_State = s_ACTIVE_VIDEO then
				o_VGA_R <= i_VGA_R;
				o_VGA_G <= i_VGA_G;
				o_VGA_B <= i_VGA_B;
				r_Active <= '1';

				if r_Pixel_H = g_H_ACTIVE_VIDEO - 1 then
					r_Pixel_H <= 0;
					if r_Pixel_V = g_V_ACTIVE_VIDEO - 1 then
						r_Pixel_V <= 0;
					else
						r_Pixel_V <= r_Pixel_V + 1;
					end if;
				else
					r_Pixel_H <= r_Pixel_H + 1;
				end if;

			else
				o_VGA_R <= (others => '0');
				o_VGA_G <= (others => '0');
				o_VGA_B <= (others => '0');
				r_Active <= '0';
			end if;
		end if;
	end process p_VideoGraphicsArray;

	o_Pixel_H <= r_Pixel_H;
	o_Pixel_V <= r_Pixel_V;
	o_Active <= r_Active;

end Behavioral;

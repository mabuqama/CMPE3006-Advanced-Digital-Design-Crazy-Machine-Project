library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity top_module is
	port (
		i_Clock	 : in  STD_LOGIC;
		i_Reset	: in  STD_LOGIC;
		i_Button	: in  STD_LOGIC;
		i_Switch	: in  STD_LOGIC_VECTOR (9 downto 0);

		i_Section_01_Sensor   : in  STD_LOGIC;
		i_Section_02_Sensor   : in  STD_LOGIC;
		i_Section_03_Sensor   : in  STD_LOGIC;
		o_Speaker   : out  STD_LOGIC;
		i_End_Stop_X : in STD_LOGIC_VECTOR (1 downto 0);
		i_End_Stop_Z : in STD_LOGIC_VECTOR (1 downto 0);

		o_Driver_A_A_S1  : out STD_LOGIC; 
		o_Driver_A_B_S1  : out STD_LOGIC;
		o_Driver_B_A_S2  : out STD_LOGIC; 
		o_Driver_B_B_S2  : out STD_LOGIC;
		o_Driver_A_A_S3  : out STD_LOGIC; 
		o_Driver_A_B_S3  : out STD_LOGIC;
		o_Stepper_Motor_X : out STD_LOGIC_VECTOR (3 downto 0);
		o_Stepper_Motor_Z : out STD_LOGIC_VECTOR (3 downto 0);

		o_VGA_R : out  STD_LOGIC_VECTOR (3 downto 0);
		o_VGA_G : out  STD_LOGIC_VECTOR (3 downto 0);
		o_VGA_B : out  STD_LOGIC_VECTOR (3 downto 0);
		o_VGA_Hsync : out STD_LOGIC;
		o_VGA_Vsync : out STD_LOGIC;
		o_LEDR	  : out STD_LOGIC_VECTOR (9 downto 0);
		o_Stepper_Motor_Enable   : out STD_LOGIC;
		o_Stepper_Motor_Direction   : out  STD_LOGIC;
		o_Stepper_Motor_Step   : out STD_LOGIC

	);
end top_module;

architecture Behavioral of top_module is

	constant c_CLOCK_FREQUENCY : INTEGER := 50_000_000;

	constant c_DC_Motor_PWM_FREQUENCY : INTEGER := 200_000;

	constant c_TWO_SECONDS : INTEGER := 100_000_000;

	constant c_X_RIGHT : STD_LOGIC := '1';
	constant c_X_LEFT : STD_LOGIC := '0';

	constant c_Z_LIFT : STD_LOGIC := '1';
	constant c_Z_LOWER : STD_LOGIC := '0';

	constant c_DONT_CARE : STD_LOGIC := '-';
	constant c_OFF : STD_LOGIC := '0';
	constant c_ON : STD_LOGIC := '1';

	type t_Section_01 is (
			s_IDLE, s_BALL_DELAY, s_ACTIVE
		);

	type t_Section_02 is (
			s_IDLE, s_BALL_DELAY, s_Z_LIFT, s_X_RIGHT, s_Z_LOWER, s_X_LEFT
		);


	signal r_Section_01 : t_Section_01 := s_IDLE;
	signal r_Section_02 : t_Section_02 := s_IDLE;
	signal r_Section_03 : t_Section_01 := s_IDLE;

	signal r_Counter_Section_01 : INTEGER range 0 to c_TWO_SECONDS := 0;
	signal r_Counter_Section_02 : INTEGER range 0 to c_TWO_SECONDS := 0;
	signal r_Counter_Section_03 : INTEGER range 0 to c_TWO_SECONDS := 0;

	signal r_StepperEnableX : STD_LOGIC := '0';
	signal r_StepperEnableZ : STD_LOGIC := '0';

	signal r_StepperSpeedX : STD_LOGIC := '0';
	signal r_StepperSpeedZ : STD_LOGIC := '0';

	signal r_StepperDirectionX : STD_LOGIC := '0';
	signal r_StepperDirectionZ : STD_LOGIC := '0';

	signal w_Actuator_S01 : STD_LOGIC := '0';
	signal w_Motor_S03 : STD_LOGIC := '0';
	signal w_ElectroMagnet : STD_LOGIC := '0';

	signal w_Reset : STD_LOGIC := '0';

	begin
		----------------------------------------------------------------------------------
		-- Static assignment
		----------------------------------------------------------------------------------
		w_Reset <= not i_Reset;

		o_LEDR(5) <= o_Driver_A_A_S3;
		o_LEDR(4) <= o_Driver_B_A_S2;
		o_LEDR(3) <= o_Driver_A_A_S1;
		o_LEDR(2) <= o_Stepper_Motor_Enable;
		o_LEDR(1) <= o_Stepper_Motor_Direction;
		o_LEDR(0) <= o_Stepper_Motor_Step;

		----------------------------------------------------------------------------------
		-- Component decleration
		----------------------------------------------------------------------------------
		A4988_Stepper_Motor_Driver_init : entity work.A4988_Stepper_Motor_Driver
			generic map(
				g_CLOCK_FREQUENCY => c_CLOCK_FREQUENCY,
				g_STEP_RATE_HZ => 2500,
				g_STEP_PULSE => 200
			)
			port map (
				i_Clock => i_Clock,
				i_Enable  => i_Switch(9),
				i_Direction => i_Switch(8),
				
				o_Enable => o_Stepper_Motor_Enable,
				o_Direction => o_Stepper_Motor_Direction,
				o_Step => o_Stepper_Motor_Step
				
			);


end Behavioral;

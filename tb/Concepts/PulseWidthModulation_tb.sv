`timescale 1ns / 1ps

module PulseWidthModulation_tb();
	reg r_Clock;
	reg [7:0] r_Duty_Cycle;
	wire w_PWM_Signal;

	// =========================================================
	// DUT CONFIG (must match VHDL scaling assumptions)
	// =========================================================
	localparam c_CLOCK_FREQUENCY = 1_000_000;	// must be >= 1 MHz or scaling breaks
	localparam c_PULSE_WIDTH_MAX = 2100;		// microseconds
	localparam c_PULSE_WIDTH_MIN = 900;		// microseconds
	localparam c_FRAME = 20000;			// microseconds

	localparam c_RESOLUTION = 255;
	localparam c_NUMBER_OF_TESTS = 20;

	// =========================================================
	// Derived tick values
	// =========================================================
	localparam c_US_TO_TICKS = (c_CLOCK_FREQUENCY / 1_000_000);

	localparam c_MIN_TICKS = c_US_TO_TICKS * c_PULSE_WIDTH_MIN;
	localparam c_MAX_TICKS = c_US_TO_TICKS * c_PULSE_WIDTH_MAX;
	localparam c_FRAME_TICKS = c_US_TO_TICKS * c_FRAME;

	int i, j;
	int highCount;
	int expected;

	// =========================================================
	// Control clock
	// =========================================================
	task t_Step_Clock();
	begin
		r_Clock = 0; #1;
		r_Clock = 1; #1;
	end
	endtask

	// =========================================================
	// DUT
	// =========================================================
	PWM #(
		.g_CLOCK_FREQUENCY(c_CLOCK_FREQUENCY),
		.g_PULSE_WIDTH_MAX(c_PULSE_WIDTH_MAX),
		.g_PULSE_WIDTH_MIN(c_PULSE_WIDTH_MIN),
		.g_FRAME(c_FRAME)
	) dut (
		.i_Clock(r_Clock),
		.i_Duty_Cycle(r_Duty_Cycle),
		.o_PWM_Signal(w_PWM_Signal)
	);

	// =========================================================
	// Testbench
	// =========================================================
	initial begin

		r_Clock = 0;
		r_Duty_Cycle = 0;

		$display("\n=== PWM SELF-CHECK START ===\n");

		for (i = 0; i < c_NUMBER_OF_TESTS; i++) begin

			// sweep duty cycle
			r_Duty_Cycle = (i * c_RESOLUTION) / (c_NUMBER_OF_TESTS - 1);

			highCount = 0;

			// wait for a full frame worth of cycles
			for (j = 0; j < c_FRAME_TICKS; j++) begin
				t_Step_Clock();
				if (w_PWM_Signal)
					highCount++;
			end

			// expected pulse width in ticks
			expected =
				c_MIN_TICKS +
				(r_Duty_Cycle * (c_MAX_TICKS - c_MIN_TICKS)) / c_RESOLUTION;

			// tolerance (1 tick)
			if ( (highCount >= expected - 1) &&
				 (highCount <= expected + 1) ) begin

				$display("\033[0;32m[PASS]\033[0m Test %0d Duty=%0d High=%0d Expected=%0d",
						 i, r_Duty_Cycle, highCount, expected);
			end
			else begin

				$display("\033[0;31m[FAIL]\033[0m Test %0d Duty=%0d High=%0d Expected=%0d",
						 i, r_Duty_Cycle, highCount, expected);
			end

		end

		$display("\n=== TEST COMPLETE ===\n");
		$finish;
	end

endmodule

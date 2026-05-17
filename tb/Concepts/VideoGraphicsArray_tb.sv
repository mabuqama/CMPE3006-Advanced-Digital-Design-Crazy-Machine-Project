`timescale 1ns / 1ps

module VideoGraphicsArray_tb();
	reg r_Clock;
	reg [3:0] r_VGA_R;
	reg [3:0] r_VGA_G;
	reg [3:0] r_VGA_B;

	wire [3:0] w_VGA_R;
	wire [3:0] w_VGA_G;
	wire [3:0] w_VGA_B;

	wire o_VGA_Vsync;
	wire o_VGA_Hsync;

	reg r_Flag = 1'b1;
	reg [7:0] r_Result = 8'h0;

	localparam c_CLOCK_FREQUENCY = 25_000_000;
	localparam c_PIXEL_CLOCK = 25_000_000;

	localparam c_H_LEFT_BORDER = 8;
	localparam c_H_BACK_PORCH = 40;
	localparam c_H_ACTIVE_VIDEO = 640;
	localparam c_H_FRONT_PORCH = 8;
	localparam c_H_RIGHT_BORDER = 8;
	localparam c_H_SYNC = 96;

	localparam c_V_TOP_BORDER = 8;
	localparam c_V_BACK_PORCH = 25;
	localparam c_V_ACTIVE_VIDEO = 480;
	localparam c_V_FRONT_PORCH = 2;
	localparam c_V_BOTTOM_BORDER = 8;
	localparam c_V_SYNC = 2;

	int i;

	task t_Step_Clock();
	begin
		r_Clock = ~r_Clock;
		#5;
		r_Clock = ~r_Clock;
		#5;
	end
	endtask

	task t_Horzantal_Wait();
		int j;
	begin
		for(j = 0; j < (
			(((c_CLOCK_FREQUENCY / c_PIXEL_CLOCK) * c_H_LEFT_BORDER) +
			((c_CLOCK_FREQUENCY / c_PIXEL_CLOCK) * c_H_BACK_PORCH) +
			((c_CLOCK_FREQUENCY / c_PIXEL_CLOCK) * c_H_ACTIVE_VIDEO) +
			((c_CLOCK_FREQUENCY / c_PIXEL_CLOCK) * c_H_FRONT_PORCH) +
			((c_CLOCK_FREQUENCY / c_PIXEL_CLOCK) * c_H_RIGHT_BORDER) +
			((c_CLOCK_FREQUENCY / c_PIXEL_CLOCK) * c_H_SYNC))
		); j = j + 1) begin
			t_Step_Clock();
		end
	end
	endtask

	VideoGraphicsArray #(
		.g_CLOCK_FREQUENCY(c_CLOCK_FREQUENCY),
		.g_PIXEL_CLOCK(c_PIXEL_CLOCK),
		.g_H_LEFT_BORDER(c_H_LEFT_BORDER),
		.g_H_BACK_PORCH(c_H_BACK_PORCH),
		.g_H_ACTIVE_VIDEO(c_H_ACTIVE_VIDEO),
		.g_H_FRONT_PORCH(c_H_FRONT_PORCH),
		.g_H_RIGHT_BORDER(c_H_RIGHT_BORDER),
		.g_H_SYNC(c_H_SYNC),
		.g_V_TOP_BORDER(c_V_TOP_BORDER),
		.g_V_BACK_PORCH(c_V_BACK_PORCH),
		.g_V_ACTIVE_VIDEO(c_V_ACTIVE_VIDEO),
		.g_V_FRONT_PORCH(c_V_FRONT_PORCH),
		.g_V_BOTTOM_BORDER(c_V_BOTTOM_BORDER),
		.g_V_SYNC(c_V_SYNC)
	) dut (
		.i_Clock(r_Clock),
		.i_VGA_R(r_VGA_R),
		.i_VGA_G(r_VGA_G),
		.i_VGA_B(r_VGA_B),
		.o_VGA_R(w_VGA_R),
		.o_VGA_G(w_VGA_G),
		.o_VGA_B(w_VGA_B),
		.o_VGA_Vsync(o_VGA_Vsync),
		.o_VGA_Hsync(o_VGA_Hsync),
		.o_Pixel_H(),
		.o_Pixel_V(),
		.o_Active()
	);

	initial begin
		r_Clock = 1'b0;
		r_VGA_R = 4'hF;
		r_VGA_G = 4'hF;
		r_VGA_B = 4'hF;

		t_Step_Clock();

		for(i = 0; i < (
			(c_V_TOP_BORDER + c_V_BACK_PORCH + c_V_ACTIVE_VIDEO + c_V_FRONT_PORCH + c_V_BOTTOM_BORDER + c_V_SYNC) * 2
		); i++) begin
			t_Horzantal_Wait();
		end

		$display("The VGA module has %s\033[0m the \033[38;5;214mTest\033[0m.",
			r_Flag ? "\033[0;32mPASSED" : "\033[0;31mFAILED"
		);

		$finish;
	end
endmodule

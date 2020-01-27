//==============================================================================
// Simon Module for Simon Project
//==============================================================================

`include "ButtonDebouncer.v"
`include "SimonControl.v"
`include "SimonDatapath.v"

module Simon(
	input        sysclk,
	input        pclk,
	input        rst,
	input        level,
	input  [3:0] pattern,

	output [3:0] pattern_leds,
	output [2:0] mode_leds
);

	// Declare local connections here
	wire i_lt_last;     // i < last
	wire arr_full;      // All 64 address in the register file are used
	wire correct_pat;   // High when correct pattern on pattern switches
	wire legal;         // A legal pattern reflected on pattern
	wire last_inc;      // Increment last register when high
	wire i_inc;         // Increment i register when high
	wire i_clr;         // Clear i register when high
	wire mem_ld;        // Load memory when high
	wire s_led_eq_pat;  // When high, pattern_leds reflect what is on pattern

	//============================================
	// Button Debouncer Section
	//============================================

	//--------------------------------------------
	// IMPORTANT!!!! If simulating, use this line:
	//--------------------------------------------
	// wire uclk = pclk;
	//--------------------------------------------
	// IMPORTANT!!!! If using FPGA, use this line:
	//--------------------------------------------
	wire uclk;
	ButtonDebouncer debouncer(
		.sysclk(sysclk),
		.noisy_btn(pclk),
		.clean_btn(uclk)
	);

	//============================================
	// End Button Debouncer Section
	//============================================

	// Datapath -- Add port connections
	SimonDatapath dpath(
		.clk      	(uclk),
		.level    	(level),
		.pattern 	(pattern),
		.rst		(rst),
		.last_inc	(last_inc),
		.i_inc		(i_inc),
		.i_clr		(i_clr),
		.mem_ld		(mem_ld),
		.s_led_eq_pat(s_led_eq_pat),
		.i_lt_last	(i_lt_last),
		.arr_full	(arr_full),
		.correct_pat(correct_pat),
		.legal		(legal),
		.pattern_leds(pattern_leds)
	);

	// Control -- Add port connections
	SimonControl ctrl(
		.clk       	(uclk),
		.rst      	(rst),
		.i_lt_last	(i_lt_last),
		.arr_full	(arr_full),
		.correct_pat(correct_pat),
		.legal		(legal),
		.last_inc	(last_inc),
		.i_inc		(i_inc),
		.i_clr		(i_clr),
		.mem_ld		(mem_ld),
		.s_led_eq_pat(s_led_eq_pat),
		.mode_leds	(mode_leds)
	);

endmodule

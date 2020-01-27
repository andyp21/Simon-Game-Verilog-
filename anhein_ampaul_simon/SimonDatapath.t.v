//===============================================================================
// Testbench Module for Simon Datapath
//===============================================================================
`timescale 1ns/100ps

`include "SimonDatapath.v"

// Print an error message (MSG) if value ONE is not equal
// to value TWO.
`define ASSERT_EQ(ONE, TWO, MSG)               \
	begin                                      \
		if ((ONE) !== (TWO)) begin             \
			$display("\t[FAILURE]:%s", (MSG)); \
		end                                    \
	end #0

// Set the variable VAR to the value VALUE, printing a notification
// to the screen indicating the variable's update.
// The setting of the variable is preceded and followed by
// a 1-timestep delay.
`define SET(VAR, VALUE) $display("Setting %s to %s...", "VAR", "VALUE"); #1; VAR = (VALUE); #1

// Cycle the clock up and then down, simulating
// a button press.
`define CLOCK $display("Pressing uclk..."); #1; clk = 1; #1; clk = 0; #1

module SimonDatapathTest;

	// Local Vars
	reg clk = 1'b0;
	reg level = 1'b0;
	reg [3:0] pattern = 4'b0000;
	reg rst = 1'b0;
	reg last_inc = 1'b0;
	reg i_inc = 1'b0;
	reg i_clr = 1'b0;
	reg mem_ld = 1'b0;
	reg s_led_eq_pat = 1'b0;
	wire i_lt_last;
	wire arr_full;
	wire correct_pat;
	wire legal;
	wire [3:0] pattern_leds;

	// VCD Dump
	integer idx;
	initial begin
		$dumpfile("SimonDatapathTest.vcd");
		$dumpvars;
		for (idx = 0; idx < 64; idx = idx + 1) begin
			$dumpvars(0, dpath.mem.mem[idx]);
		end
	end

	// Simon datapath Module
	SimonDatapath dpath(
		.clk     (clk),
		.level   (level),
		.pattern (pattern),
		.rst(rst),
		.last_inc(last_inc),      
		.i_inc(i_inc),        
		.i_clr(i_clr),         
		.mem_ld(mem_ld),       
		.s_led_eq_pat(s_led_eq_pat),
		.i_lt_last(i_lt_last),  
		.arr_full(arr_full),    
		.correct_pat(correct_pat),   
		.legal(legal),       
 		.pattern_leds(pattern_leds)
	);

	// Main Test Logic
	initial begin

		// Reset, with level = 1.
		`SET(rst, 1);
		`SET(level, 1);
		`CLOCK;
		`SET(rst, 1'b0);

		// Test a legal input.
		`SET(pattern, 4'b0001);
		`ASSERT_EQ(legal, 1'b1, "0001 is a legal hard mode input.");

		// Test a legal input.
		`SET(pattern, 4'b1111);
		`ASSERT_EQ(legal, 1'b1, "1111 is a legal hard mode input.");

		// Test that patterns_leds = patterns_led
		`SET(s_led_eq_pat, 1'b1);
		`ASSERT_EQ(pattern, pattern_leds, "leds should match pattern when s_led_eq_pat is high.");

		// continue with hard mode, proceed to playback, store 1111 in memory
		`SET(i_clr, 1'b1);
		`SET(mem_ld, 1'b1);
		`CLOCK;
		`SET(mem_ld, 1'b0);

		// test playback stage, proceed to repeat
		`SET(i_inc, 1);
		`SET(s_led_eq_pat, 1'b0);
		`SET(pattern, 4'b0000);
		`ASSERT_EQ(i_lt_last, 1'b0, "First iteration, i_lt_last is not true because i = last = 0");
		`ASSERT_EQ(4'b1111, pattern_leds, "leds should match mem[i] when s_led_eq_pat is low.");
		`CLOCK;

		// test repeat stage, proceed to done
		`SET(i_inc, 1'b1);
		`SET(s_led_eq_pat, 1'b1);
		`SET(pattern, 4'b0001); // incorrect guess
		`ASSERT_EQ(correct_pat, 1'b0, "0001 is not the pattern in memory, which is 1111.");
		`SET(i_clr, 1'b1);
		`ASSERT_EQ(pattern, pattern_leds, "leds should match pattern when s_led_eq_pat is high.");
		`ASSERT_EQ(i_lt_last, 1'b0, "First iteration, i_lt_last is not true because i = last = 0");
		`ASSERT_EQ(arr_full, 1'b0, "Not full be because last << 63");
		`CLOCK;

		// test done stage
		`SET(i_inc, 1'b1);
		`SET(s_led_eq_pat, 1'b0);
		`ASSERT_EQ(4'b1111, pattern_leds, "leds should match mem[i] when s_led_eq_pat is low.");
		`CLOCK;
		`ASSERT_EQ(4'b1111, pattern_leds, "leds should match mem[i] when s_led_eq_pat is low.");
		`CLOCK;
		`ASSERT_EQ(4'b1111, pattern_leds, "leds should match mem[i] when s_led_eq_pat is low.");
		`CLOCK;
				
		// Reset, with level = 0. MORE COMPLETE PLAYTHROUGH
		`SET(rst, 1'b1);
		`SET(level, 1'b0);
		`CLOCK;
		`SET(rst, 1'b0);

		// Test an illegal input.
		`SET(pattern, 4'b1111);
		`ASSERT_EQ(legal, 1'b0, "1111 is not a legal easy mode input.");
		`CLOCK;		

		// Test a legal input.
		`SET(pattern, 4'b0001);
		`ASSERT_EQ(legal, 1'b1, "0001 is a legal easy mode input.");
		
		// Store legal easy input, proceed to playback.
		`SET(i_clr, 1'b1);
		`SET(mem_ld, 1'b1);
		`CLOCK;
		`SET(mem_ld, 1'b0);
		`SET(i_clr, 1'b0);

		// test playback stage, proceed to repeat
		`SET(i_inc, 1);
		`SET(s_led_eq_pat, 1'b0);
		`ASSERT_EQ(i_lt_last, 1'b0, "First iteration, i_lt_last is not true because i = last = 0");
		`ASSERT_EQ(4'b0001, pattern_leds, "leds should match mem[i] when s_led_eq_pat is low.");
		`CLOCK;

		// test repeat stage, proceed to INPUT
		`SET(i_inc, 1'b1);
		`SET(s_led_eq_pat, 1'b1);
		`SET(pattern, 4'b0001); // correct guess
		`ASSERT_EQ(correct_pat, 1'b1, "0001 is the pattern in memory.");
		`SET(i_clr, 1'b0);
		`ASSERT_EQ(pattern, pattern_leds, "leds should match pattern when s_led_eq_pat is high.");
		`ASSERT_EQ(i_lt_last, 1'b0, "First iteration, i_lt_last is not true because i = last = 0");
		`ASSERT_EQ(arr_full, 1'b0, "Not full be because last << 63");
		`SET(last_inc, 1'b1);
		`CLOCK;
		`SET(last_inc, 1'b0);

		// Test an illegal input.
		`SET(i_clr, 1'b1);
		`SET(mem_ld, 1'b1);
		`SET(s_led_eq_pat, 1'b1);
		`SET(pattern, 4'b0011);
		`ASSERT_EQ(legal, 1'b0, "0011 is not a legal easy mode input.");
		`ASSERT_EQ(pattern, pattern_leds, "leds should match pattern when s_led_eq_pat is high.");
		`CLOCK;
		$display("HERE");
		// Store legal easy input, proceed to playback.
		`SET(i_clr, 1'b1);
		`SET(mem_ld, 1'b1);
		`SET(s_led_eq_pat, 1'b1);
		`SET(pattern, 4'b0010);
		`ASSERT_EQ(legal, 1'b1, "0010 is a legal easy mode input.");
		`ASSERT_EQ(pattern, pattern_leds, "leds should match pattern when s_led_eq_pat is high.");
		`CLOCK;
		`SET(mem_ld, 1'b0);
		`SET(i_clr, 1'b0);
		`SET(s_led_eq_pat, 1'b0);

		// test playback stage with two in memory, proceed to repeat
		`SET(i_inc, 1);
		`SET(s_led_eq_pat, 1'b0);
		`ASSERT_EQ(i_lt_last, 1'b1, "First iteration, i_lt_last is true because i < last = 1");
		`ASSERT_EQ(4'b0001, pattern_leds, "leds should match mem[i] when s_led_eq_pat is low.");
		`CLOCK;
		`ASSERT_EQ(i_lt_last, 1'b0, "Second iteration, i_lt_last is false because i = last = 1");
		`ASSERT_EQ(4'b0010, pattern_leds, "leds should match mem[i] when s_led_eq_pat is low.");
		`SET(i_inc, 1);
		`SET(s_led_eq_pat, 1'b1);
		`CLOCK;

		// test repeat stage, proceed to repeat
		`SET(i_inc, 1'b1);
		`SET(s_led_eq_pat, 1'b1);
		`SET(pattern, 4'b0001); // correct guess
		`ASSERT_EQ(correct_pat, 1'b1, "0001 is the pattern in memory.");
		`SET(i_clr, 1'b0);
		`ASSERT_EQ(pattern, pattern_leds, "leds should match pattern when s_led_eq_pat is high.");
		`ASSERT_EQ(i_lt_last, 1'b1, "First iteration, i_lt_last is true because i = last = 0");
		`ASSERT_EQ(arr_full, 1'b0, "Not full be because last << 63");
		`CLOCK;	

		// test repeat stage, proceed to DONE
		`SET(i_inc, 1'b1);
		`SET(s_led_eq_pat, 1'b1);
		`SET(pattern, 4'b0100); // incorrect guess
		`ASSERT_EQ(correct_pat, 1'b0, "0010 is the pattern in memory, current pattern on switches is 0100");
		`SET(i_clr, 1'b1);
		`ASSERT_EQ(pattern, pattern_leds, "leds should match pattern when s_led_eq_pat is high.");
		`ASSERT_EQ(i_lt_last, 1'b0, "Second iteration, i_lt_last is false because i = last = 1");
		`ASSERT_EQ(arr_full, 1'b0, "Not full be because last << 63");
		`CLOCK;	
		`SET(i_clr, 1'b0);

		// test done stage
		`SET(i_inc, 1'b1);
		`SET(s_led_eq_pat, 1'b0);
		`ASSERT_EQ(4'b0001, pattern_leds, "leds should match mem[i] when s_led_eq_pat is low.");
		`CLOCK;
		`ASSERT_EQ(4'b0010, pattern_leds, "leds should match mem[i] when s_led_eq_pat is low.");
		`CLOCK;
		`ASSERT_EQ(4'b0001, pattern_leds, "leds should match mem[i] when s_led_eq_pat is low.");
		`CLOCK;
		`ASSERT_EQ(4'b0010, pattern_leds, "leds should match mem[i] when s_led_eq_pat is low.");
		`CLOCK;

		$finish;
	end

endmodule

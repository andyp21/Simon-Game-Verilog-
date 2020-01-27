//===============================================================================
// Testbench Module for Simon
//===============================================================================
`timescale 1ns/100ps

`include "Simon.v"

`define ASSERT_EQ(ONE, TWO, MSG)               \
	begin                                      \
		if ((ONE) !== (TWO)) begin             \
			$display("\t[FAILURE]:%s", (MSG)); \
			errors = errors + 1;               \
		end                                    \
	end #0

`define SET(VAR, VALUE) $display("Setting %s to %s...", "VAR", "VALUE"); #1; VAR = (VALUE); #1

`define CLOCK $display("Pressing uclk..."); #1; clk = 1; #1; clk = 0; #1

`define SHOW_MODE(MODE) $display("\nEntering Mode: %s\n-----------------------------------", MODE)

module SimonTest;

	// Local Vars
	reg clk = 0;
	reg sysclk = 0;
	reg rst = 0;
	reg level = 0;
	reg [3:0] pattern = 4'd0;
	wire [2:0] mode_leds;
	wire [3:0] pattern_leds;

	// Error Counts
	reg [7:0] errors = 0;

	// LED Light Parameters
	localparam LED_MODE_INPUT    = 3'b001;
	localparam LED_MODE_PLAYBACK = 3'b010;
	localparam LED_MODE_REPEAT   = 3'b100;
	localparam LED_MODE_DONE     = 3'b111;

	// VCD Dump
	integer idx;
	initial begin
		$dumpfile("SimonTest.vcd");
		$dumpvars;
		for (idx = 0; idx < 64; idx = idx + 1) begin
			$dumpvars(0, simon.dpath.mem.mem[idx]);
		end
	end

	// Simon Module
	Simon simon(
		.sysclk       (sysclk),
		.pclk         (clk),
		.rst          (rst),
		.level        (level),
		.pattern      (pattern),

		.pattern_leds (pattern_leds),
		.mode_leds    (mode_leds)
	);

	// Main Test Logic
	initial begin
		 
	// Reset the game
       `SHOW_MODE("Unknown");
       `SET(rst, 1);
	`SET(level, 0); // easy game
       `CLOCK;
 
       //-----------------------------------------------
       // Input Mode
       // ----------------------------------------------
       `SHOW_MODE("Input EASY");
       `SET(rst, 0);
	`SET(level, 1); // doesn’t change anything
       `ASSERT_EQ(mode_leds, LED_MODE_INPUT, "Mode should be input after reset!");
       `ASSERT_EQ(pattern_leds, pattern, "Pattern LEDs should match switches in input mode!");
 
       // Modify Switches
       `SET(pattern, 4'b0110);	// illegal pattern
       `ASSERT_EQ(pattern_leds, pattern, "Pattern LEDs should match switches in input mode!");
 
       // Insert Pattern
       `CLOCK;
 
	// Still input, no change because illegal.
	`SHOW_MODE("Input");
	`ASSERT_EQ(mode_leds, LED_MODE_INPUT, "Mode should be input after illegal patter.");
	`ASSERT_EQ(pattern_leds, pattern, "Pattern LEDs should match switches in input mode!");
 
	// New input that is legal.
	`SET(pattern, 4'b0100);	// illegal pattern
       `ASSERT_EQ(pattern_leds, pattern, "Pattern LEDs should match switches in input mode!");
 
	// Insert pattern.
	`CLOCK;
 
       //-----------------------------------------------
       // Playback Mode
       // ----------------------------------------------
       `SHOW_MODE("Playback");
       `ASSERT_EQ(mode_leds, LED_MODE_PLAYBACK, "Mode should go to playback after input!");
 
       // Modify Switches
       `SET(pattern, 4'b1111);
       `ASSERT_EQ(pattern_leds, 4'b0100, "Pattern LEDs should show first pattern in sequence!");
 
	`SET(level, 0); // doesn’t do anything
	
`SET(pattern, 4'b0101);
       `ASSERT_EQ(pattern_leds, 4'b0100, "Pattern LEDs should show first pattern in sequence!");
 
       // Advance
       `CLOCK;
 
       //-----------------------------------------------
       // Repeat Mode
       // ----------------------------------------------
       `SHOW_MODE("Repeat");
       `ASSERT_EQ(mode_leds, LED_MODE_REPEAT, "Mode should go to repeat after playback has ended!");
 
       // Modify Switches
       `SET(pattern, 4'b0100);	// this is correct
       `ASSERT_EQ(pattern_leds, pattern, "Pattern LEDs should match switches in repeat mode");
 
       // Insert Guess
       `CLOCK;
 
       //-----------------------------------------------
       // Input Mode
       // ----------------------------------------------
       `SHOW_MODE("Input");
       `ASSERT_EQ(mode_leds, LED_MODE_INPUT, "Mode should be input after successful repeat!");
 
       // Modify level during game
       `SET(level, 1);
 
       // Modify Switches
       `SET(pattern, 4'b0011);
 
       // Attempt to Insert Pattern
       `CLOCK;
 
       // Mode should stay input
       `ASSERT_EQ(mode_leds, LED_MODE_INPUT, "Mode should remain in input if pattern invalid!");
 
       // Modify Switches
       `SET(pattern, 4'b0001);
 
       // Attempt to Insert Pattern
       `CLOCK;
 
       //-----------------------------------------------
       // Playback Mode
       // ----------------------------------------------
       `SHOW_MODE("Playback");
       `ASSERT_EQ(mode_leds, LED_MODE_PLAYBACK, "Mode should go to playback after input!");
 
       // Modify Switches
       `SET(pattern, 4'b0000);
       `ASSERT_EQ(pattern_leds, 4'b0100, "Pattern LEDs should show first pattern in sequence!");
 
       // Go to next pattern
       `CLOCK;
`SET(pattern, 4'b1111);
       `ASSERT_EQ(pattern_leds, 4'b0001, "Pattern LEDs should show second pattern in sequence!");
 
       // Go to repeat
       `CLOCK;
 
       //-----------------------------------------------
       // Repeat Mode
       // ----------------------------------------------
       `SHOW_MODE("Repeat");
       `ASSERT_EQ(mode_leds, LED_MODE_REPEAT, "Mode should go to repeat after playback has ended!");
 
       // Insert first guess
       `SET(pattern, 4'b0100); //correct
`ASSERT_EQ(pattern_leds, pattern, "Pattern LEDs should match switches in repeat mode");
       `CLOCK;
       `ASSERT_EQ(mode_leds, LED_MODE_REPEAT, "Mode should remain in repeat after first successful guess!");
 
       // Insert second guess
       `SET(pattern, 4'b0001); //correct
`ASSERT_EQ(pattern_leds, pattern, "Pattern LEDs should match switches in repeat mode");
       `CLOCK;
 
//-----------------------------------------------
       // Input Mode
       // ----------------------------------------------
       `SHOW_MODE("Input");
       `ASSERT_EQ(mode_leds, LED_MODE_INPUT, "Mode should be input after successful repeat!");
 
       // Modify Switches
       `SET(pattern, 4'b1001);
 
       // Attempt to Insert Pattern
       `CLOCK;
 
       // Mode should stay input
       `ASSERT_EQ(mode_leds, LED_MODE_INPUT, "Mode should remain in input if pattern invalid!");
 
       // Modify Switches
       `SET(pattern, 4'b1000);
 
       // Attempt to Insert Pattern
       `CLOCK;
 
       //-----------------------------------------------
       // Playback Mode
       // ----------------------------------------------
       `SHOW_MODE("Playback");
       `ASSERT_EQ(mode_leds, LED_MODE_PLAYBACK, "Mode should go to playback after input!");
 
       // Modify Switches
       `SET(pattern, 4'b1011);
       `ASSERT_EQ(pattern_leds, 4'b0100, "Pattern LEDs should show first pattern in sequence!");
 
       // Go to next pattern
       `CLOCK;
`SET(pattern, 4'b1111);
       `ASSERT_EQ(pattern_leds, 4'b0001, "Pattern LEDs should show second pattern in sequence!");
 
		// Go to next pattern
       	`CLOCK;
		`SET(pattern, 4'b0111);
       	`ASSERT_EQ(pattern_leds, 4'b1000, "Pattern LEDs should show second pattern in sequence!");
 
       // Go to repeat
       `CLOCK;
 
    	//-----------------------------------------------
    	// Repeat Mode
    	// ----------------------------------------------
    	`SHOW_MODE("Repeat");
       	`ASSERT_EQ(mode_leds, LED_MODE_REPEAT, "Mode should go to repeat after playback has ended!");
 
       	// Insert first guess
       	`SET(pattern, 4'b0100); //correct
		`ASSERT_EQ(pattern_leds, pattern, "Pattern LEDs should match switches in repeat mode");
       	`CLOCK;
       	`ASSERT_EQ(mode_leds, LED_MODE_REPEAT, "Mode should remain in repeat after first successful guess!");
 
       	// Insert second guess
       	`SET(pattern, 4'b0001); //correct
		`ASSERT_EQ(pattern_leds, pattern, "Pattern LEDs should match switches in repeat mode");
       	`CLOCK;
 
		// Insert second guess
       	`SET(pattern, 4'b1000); //correct
		`ASSERT_EQ(pattern_leds, pattern, "Pattern LEDs should match switches in repeat mode");
		`CLOCK;
 
		//-----------------------------------------------
       // Input Mode
       // ----------------------------------------------
       `SHOW_MODE("Input");
       `ASSERT_EQ(mode_leds, LED_MODE_INPUT, "Mode should be input after successful repeat!");
 
       // Modify Switches
       `SET(pattern, 4'b0010);
 
       // Attempt to Insert Pattern
       `CLOCK;
 
       //-----------------------------------------------
       // Playback Mode
       // ----------------------------------------------
       `SHOW_MODE("Playback");
       `ASSERT_EQ(mode_leds, LED_MODE_PLAYBACK, "Mode should go to playback after input!");
 
       // Modify Switches
       `SET(pattern, 4'b1010);
       `ASSERT_EQ(pattern_leds, 4'b0100, "Pattern LEDs should show first pattern in sequence!");
 
       // Go to next pattern
       `CLOCK;
		`SET(pattern, 4'b0110);
       `ASSERT_EQ(pattern_leds, 4'b0001, "Pattern LEDs should show second pattern in sequence!");
 
		// Go to next pattern
       `CLOCK;
		`SET(pattern, 4'b0100);
       `ASSERT_EQ(pattern_leds, 4'b1000, "Pattern LEDs should show second pattern in sequence!");
 
		// Go to next pattern
       `CLOCK;
		`SET(pattern, 4'b1101);
       `ASSERT_EQ(pattern_leds, 4'b0010, "Pattern LEDs should show second pattern in sequence!");
 
       // Go to repeat
       `CLOCK;
 
       //-----------------------------------------------
       // Repeat Mode
       // ----------------------------------------------
       `SHOW_MODE("Repeat");
       `ASSERT_EQ(mode_leds, LED_MODE_REPEAT, "Mode should go to repeat after playback has ended!");
 
       // Insert first guess
       `SET(pattern, 4'b0100); //correct
		`ASSERT_EQ(pattern_leds, pattern, "Pattern LEDs should match switches in repeat mode");
       `CLOCK;
       `ASSERT_EQ(mode_leds, LED_MODE_REPEAT, "Mode should remain in repeat after first successful guess!");
 
       // Insert second guess
       `SET(pattern, 4'b0001); //correct
		`ASSERT_EQ(pattern_leds, pattern, "Pattern LEDs should match switches in repeat mode");
       `CLOCK;
 
		// Insert second guess
       `SET(pattern, 4'b1000); //correct
		`ASSERT_EQ(pattern_leds, pattern, "Pattern LEDs should match switches in repeat mode");
		`CLOCK;
 
		// Insert second guess
       `SET(pattern, 4'b1110); //incorrect
		`ASSERT_EQ(pattern_leds, pattern, "Pattern LEDs should match switches in repeat mode");
		`CLOCK;
 
       //-----------------------------------------------
       // Done Mode
       // ----------------------------------------------
       `SHOW_MODE("Done");
       `ASSERT_EQ(mode_leds, LED_MODE_DONE, "Mode should go to done after failed guess!");
 
       // Modify Switches
       `SET(pattern, 4'b0110);
       `ASSERT_EQ(pattern_leds, 4'b0100, "Pattern LEDs should show first pattern in sequence!");
	   `CLOCK;
 
       // Go to next pattern
       `ASSERT_EQ(pattern_leds, 4'b0001, "Pattern LEDs should show second pattern in sequence!");
 
		`ASSERT_EQ(mode_leds, LED_MODE_DONE, "Mode should stay in done after failed guess!");
		
 
    	// Next pattern.
       `CLOCK;
       `ASSERT_EQ(pattern_leds, 4'b1000, "Pattern LEDs should show first pattern in sequence!");
 
		// Next pattern.
       `CLOCK;
       `ASSERT_EQ(pattern_leds, 4'b0010, "Pattern LEDs should show second pattern in sequence!");
 
		`ASSERT_EQ(mode_leds, LED_MODE_DONE, "Mode should stay in done after failed guess!");
 
		// Wrap around.
       `CLOCK;
       `ASSERT_EQ(pattern_leds, 4'b0100, "Pattern LEDs should show second pattern in sequence!");
       `ASSERT_EQ(mode_leds, LED_MODE_DONE, "Mode should stay in done after failed guess!");

	// Reset the game
       `SET(rst, 1);
	   `SET(level, 1); // hard game
       `CLOCK;
 
       //-----------------------------------------------
       // Input Mode
       // ----------------------------------------------
       `SHOW_MODE("Input HARD");
       `SET(rst, 0);
		`SET(level, 1); // doesn’t change anything
       `ASSERT_EQ(mode_leds, LED_MODE_INPUT, "Mode should be input after reset!");
       `ASSERT_EQ(pattern_leds, pattern, "Pattern LEDs should match switches in input mode!");
 
       // Modify Switches
       `SET(pattern, 4'b1111);	// legal pattern
       `ASSERT_EQ(pattern_leds, pattern, "Pattern LEDs should match switches in input mode!");
 
       // Insert Pattern
       `CLOCK;
 
       //-----------------------------------------------
       // Playback Mode
       // ----------------------------------------------
       `SHOW_MODE("Playback");
       `ASSERT_EQ(mode_leds, LED_MODE_PLAYBACK, "Mode should go to playback after input!");
 
       // Modify Switches
       `SET(pattern, 4'b0000);
       `ASSERT_EQ(pattern_leds, 4'b1111, "Pattern LEDs should show first pattern in sequence!");
 
		`SET(level, 0); // doesn’t do anything
	
		`SET(pattern, 4'b0111);
       `ASSERT_EQ(pattern_leds, 4'b1111, "Pattern LEDs should show first pattern in sequence!");
 
       // Advance
       `CLOCK;
 
       //-----------------------------------------------
       // Repeat Mode
       // ----------------------------------------------
       `SHOW_MODE("Repeat");
       `ASSERT_EQ(mode_leds, LED_MODE_REPEAT, "Mode should go to repeat after playback has ended!");
 
       // Modify Switches
       `SET(pattern, 4'b1111);	// this is correct
       `ASSERT_EQ(pattern_leds, pattern, "Pattern LEDs should match switches in repeat mode");
 
       // Insert Guess
       `CLOCK;
 
       //-----------------------------------------------
       // Input Mode
       // ----------------------------------------------
       `SHOW_MODE("Input");
       `ASSERT_EQ(mode_leds, LED_MODE_INPUT, "Mode should be input after successful repeat!");
 
       // Modify level during game
       `SET(level, 1);
 
       // Modify Switches
       `SET(pattern, 4'b1110);
 
       // Attempt to Insert Pattern
       `CLOCK;
 
       //-----------------------------------------------
       // Playback Mode
       // ----------------------------------------------
       `SHOW_MODE("Playback");
       `ASSERT_EQ(mode_leds, LED_MODE_PLAYBACK, "Mode should go to playback after input!");
 
       // Modify Switches
       `SET(pattern, 4'b0101);
       `ASSERT_EQ(pattern_leds, 4'b1111, "Pattern LEDs should show first pattern in sequence!");
 
       // Go to next pattern
       `CLOCK;
		`SET(pattern, 4'b1111);
       `ASSERT_EQ(pattern_leds, 4'b1110, "Pattern LEDs should show second pattern in sequence!");
 
       // Go to repeat
       `CLOCK;
 
       //-----------------------------------------------
       // Repeat Mode
       // ----------------------------------------------
       `SHOW_MODE("Repeat");
       `ASSERT_EQ(mode_leds, LED_MODE_REPEAT, "Mode should go to repeat after playback has ended!");
 
       // Insert first guess
       `SET(pattern, 4'b1111); //correct
`ASSERT_EQ(pattern_leds, pattern, "Pattern LEDs should match switches in repeat mode");
       `CLOCK;
       `ASSERT_EQ(mode_leds, LED_MODE_REPEAT, "Mode should remain in repeat after first successful guess!");
 
       // Insert second guess
       `SET(pattern, 4'b1110); //correct
`ASSERT_EQ(pattern_leds, pattern, "Pattern LEDs should match switches in repeat mode");
       `CLOCK;
 
//-----------------------------------------------
       // Input Mode
       // ----------------------------------------------
       `SHOW_MODE("Input");
       `ASSERT_EQ(mode_leds, LED_MODE_INPUT, "Mode should be input after successful repeat!");
 
       // Modify Switches
       `SET(pattern, 4'b1101);
 
       // Attempt to Insert Pattern
       `CLOCK;
 
       //-----------------------------------------------
       // Playback Mode
       // ----------------------------------------------
       `SHOW_MODE("Playback");
       `ASSERT_EQ(mode_leds, LED_MODE_PLAYBACK, "Mode should go to playback after input!");
 
       // Modify Switches
       `SET(pattern, 4'b1101);
       `ASSERT_EQ(pattern_leds, 4'b1111, "Pattern LEDs should show first pattern in sequence!");
 
       // Go to next pattern
       `CLOCK;
		`SET(pattern, 4'b1111);
       `ASSERT_EQ(pattern_leds, 4'b1110, "Pattern LEDs should show second pattern in sequence!");
 
		// Go to next pattern
       	`CLOCK;
		`SET(pattern, 4'b1110);
       	`ASSERT_EQ(pattern_leds, 4'b1101, "Pattern LEDs should show second pattern in sequence!");
 
       // Go to repeat
       `CLOCK;
 
    	//-----------------------------------------------
    	// Repeat Mode
    	// ----------------------------------------------
    	`SHOW_MODE("Repeat");
       	`ASSERT_EQ(mode_leds, LED_MODE_REPEAT, "Mode should go to repeat after playback has ended!");
 
       	// Insert first guess
       	`SET(pattern, 4'b1111); //correct
		`ASSERT_EQ(pattern_leds, pattern, "Pattern LEDs should match switches in repeat mode");
       	`CLOCK;
       	`ASSERT_EQ(mode_leds, LED_MODE_REPEAT, "Mode should remain in repeat after first successful guess!");
 
       	// Insert second guess
       	`SET(pattern, 4'b1110); //correct
		`ASSERT_EQ(pattern_leds, pattern, "Pattern LEDs should match switches in repeat mode");
       	`CLOCK;
 
		// Insert second guess
       	`SET(pattern, 4'b1101); //correct
		`ASSERT_EQ(pattern_leds, pattern, "Pattern LEDs should match switches in repeat mode");
		`CLOCK;
 
		//-----------------------------------------------
       // Input Mode
       // ----------------------------------------------
       `SHOW_MODE("Input");
       `ASSERT_EQ(mode_leds, LED_MODE_INPUT, "Mode should be input after successful repeat!");
 
       // Modify Switches
       `SET(pattern, 4'b0000);
 
       // Attempt to Insert Pattern
       `CLOCK;
 
       //-----------------------------------------------
       // Playback Mode
       // ----------------------------------------------
       `SHOW_MODE("Playback");
       `ASSERT_EQ(mode_leds, LED_MODE_PLAYBACK, "Mode should go to playback after input!");
 
       // Modify Switches
       `SET(pattern, 4'b1001);
       `ASSERT_EQ(pattern_leds, 4'b1111, "Pattern LEDs should show first pattern in sequence!");
 
       // Go to next pattern
       `CLOCK;
		`SET(pattern, 4'b0111);
       `ASSERT_EQ(pattern_leds, 4'b1110, "Pattern LEDs should show second pattern in sequence!");
 
		// Go to next pattern
       `CLOCK;
		`SET(pattern, 4'b0110);
       `ASSERT_EQ(pattern_leds, 4'b1101, "Pattern LEDs should show second pattern in sequence!");
 
		// Go to next pattern
       `CLOCK;
		`SET(pattern, 4'b1011);
       `ASSERT_EQ(pattern_leds, 4'b0000, "Pattern LEDs should show second pattern in sequence!");
 
       // Go to repeat
       `CLOCK;
 
       //-----------------------------------------------
       // Repeat Mode
       // ----------------------------------------------
       `SHOW_MODE("Repeat");
       `ASSERT_EQ(mode_leds, LED_MODE_REPEAT, "Mode should go to repeat after playback has ended!");
 
       // Insert first guess
       `SET(pattern, 4'b1111); //correct
		`ASSERT_EQ(pattern_leds, pattern, "Pattern LEDs should match switches in repeat mode");
       `CLOCK;
       `ASSERT_EQ(mode_leds, LED_MODE_REPEAT, "Mode should remain in repeat after first successful guess!");
 
       // Insert second guess
       `SET(pattern, 4'b1110); //correct
		`ASSERT_EQ(pattern_leds, pattern, "Pattern LEDs should match switches in repeat mode");
       `CLOCK;
 
		// Insert second guess
       `SET(pattern, 4'b1101); //correct
		`ASSERT_EQ(pattern_leds, pattern, "Pattern LEDs should match switches in repeat mode");
		`CLOCK;
 
		// Insert second guess
       `SET(pattern, 4'b1100); //incorrect
		`ASSERT_EQ(pattern_leds, pattern, "Pattern LEDs should match switches in repeat mode");
		`CLOCK;
 
       //-----------------------------------------------
       // Done Mode
       // ----------------------------------------------
       `SHOW_MODE("Done");
       `ASSERT_EQ(mode_leds, LED_MODE_DONE, "Mode should go to done after failed guess!");
 
       // Modify Switches
       `SET(pattern, 4'b0001);
       `ASSERT_EQ(pattern_leds, 4'b1111, "Pattern LEDs should show first pattern in sequence!");
	   `CLOCK;
 
       // Go to next pattern
       `ASSERT_EQ(pattern_leds, 4'b1110, "Pattern LEDs should show second pattern in sequence!");
 
		`ASSERT_EQ(mode_leds, LED_MODE_DONE, "Mode should stay in done after failed guess!");
		
 
    	// Next pattern.
       `CLOCK;
       `ASSERT_EQ(pattern_leds, 4'b1101, "Pattern LEDs should show first pattern in sequence!");
 
		// Next pattern.
       `CLOCK;
       `ASSERT_EQ(pattern_leds, 4'b0000, "Pattern LEDs should show second pattern in sequence!");
 
		`ASSERT_EQ(mode_leds, LED_MODE_DONE, "Mode should stay in done after failed guess!");
 
		// Wrap around.
       `CLOCK;
       `ASSERT_EQ(pattern_leds, 4'b1111, "Pattern LEDs should show second pattern in sequence!");
       `ASSERT_EQ(mode_leds, LED_MODE_DONE, "Mode should stay in done after failed guess!");

       $display("\nTESTS COMPLETED (%d FAILURES)", errors);
       $finish;

	end

endmodule

//===============================================================================
// Testbench Module for Simon Controller
//===============================================================================
`timescale 1ns/100ps
 
`include "SimonControl.v"
 
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
 
module SimonControlTest;
 
   // Local Vars
   reg clk;
   reg rst;
   reg i_lt_last;     // i < last
   reg arr_full;      // All 64 address in the register file are used
   reg correct_pat;   // High when correct pattern on pattern switches
   reg legal;         // A legal pattern reflected on pattern
   wire last_inc;      // Increment last register when high
   wire i_inc;         // Increment i register when high
   wire i_clr;         // Clear i register when high
   wire mem_ld;        // Load memory when high
   wire s_led_eq_pat;  // When high, pattern_leds reflect what is on pattern
   wire[2:0] mode_leds; // Led shows what state you are in.
 
 
   // LED Light Parameters
   localparam LED_MODE_INPUT    = 3'b001;
   localparam LED_MODE_PLAYBACK = 3'b010;
   localparam LED_MODE_REPEAT   = 3'b100;
   localparam LED_MODE_DONE     = 3'b111;
 
 
   // VCD Dump
   initial begin
       $dumpfile("SimonControlTest.vcd");
       $dumpvars;
   end
 
   // Simon Control Module
   SimonControl ctrl(
       .clk (clk),
       .rst (rst),
        .i_lt_last(i_lt_last),     // i < last
        .arr_full(arr_full),      // All 64 address in the register file are used
        .correct_pat(correct_pat),   // High when correct pattern on pattern switches
        .legal(legal),
        .last_inc(last_inc),      // Increment last register when high
        .i_inc(i_inc),         // Increment i register when high
        .i_clr(i_clr),         // Clear i register when high
        .mem_ld(mem_ld),        // Load memory when high
        .s_led_eq_pat(s_led_eq_pat),  // When high, pattern_leds reflect what pattern
        .mode_leds(mode_leds)   // Led shows what state you are in.
 
   );
 
   // Main Test Logic
   initial begin
       // Reset the game
        `SET(rst, 1);
        `CLOCK;
        `SET(rst, 0);
        `SET(legal,1);
        `SET(arr_full,0);
 
        `CLOCK;
        `ASSERT_EQ(mode_leds,LED_MODE_PLAYBACK, "State should transition to Playback if input legal is true.");
        `ASSERT_EQ(i_inc,1,"Incrementer for i should be 1 during Playback State.");
        `CLOCK;
        
        `SET(i_lt_last,1);
        `CLOCK;
        `ASSERT_EQ(mode_leds, LED_MODE_PLAYBACK, "State should remain in playback until i_lt_last is 0.");
        `SET(i_lt_last,0);
 
        `CLOCK;
        `ASSERT_EQ(mode_leds, LED_MODE_REPEAT, "State should transition to repeat state since playback has ended.")
    
        `SET(correct_pat,1);
        `CLOCK;
        `ASSERT_EQ(mode_leds, LED_MODE_INPUT, "State should transition to input given the opponent guessed the right paths.");
        `ASSERT_EQ(i_clr, 1 , "i should be cleared on repeat transition to input")
        `ASSERT_EQ(mem_ld, 1, "Memory load should be high after transition to input")
        `CLOCK;
        `SET(i_lt_last,0);
        `CLOCK;
 
        `ASSERT_EQ(mode_leds, LED_MODE_REPEAT, "State should transition to repeat state since playback has ended.")
        `SET(correct_pat,0);
 
        `CLOCK;
        `CLOCK;
        `ASSERT_EQ(mode_leds, LED_MODE_DONE, "User has gotten pattern wrong and program should go to done state.") 
        `CLOCK; 
       $finish;
   end
 
endmodule

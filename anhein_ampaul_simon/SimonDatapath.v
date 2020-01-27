//==============================================================================
// Datapath for Simon Project
//==============================================================================
 
`include "Memory.v"

module SimonDatapath(
   // External Inputs
   input        clk,           // Clock
   input        level,         // Switch for setting level
   input  [3:0] pattern,       // Switches for creating pattern
   input		    rst,		       // Reset
 
   // Datapath Control Signals
   input        last_inc,      // Increment last register when high
   input        i_inc,         // Increment i register when high
   input        i_clr,         // Clear i register when high
   input        mem_ld,        // Load memory when high
   input        s_led_eq_pat,  // When high, pattern_leds reflect what is on pattern
 
   // Datapath Outputs to Control
   output      i_lt_last,     // i < last
   output      arr_full,      // All 64 address in the register file are used
   output      correct_pat,   // High when correct pattern on pattern switches
   output      legal,         // A legal pattern reflected on pattern
 
   // External Outputs
   output reg [3:0] pattern_leds  // LED outputs for pattern
);
 
   // Declare Local Vars Here
   reg [5:0] i;	// Really a counter, counting implemented on a higher level.
   reg [5:0] last;  // Keeps pointer on the most recent entry
   reg saved_level;       // Keeps the level of the game.	
   
 
 
 
 
   //----------------------------------------------------------------------
   // Internal Logic -- Manipulate Registers, ALU's, Memories Local to
   // the Datapath
   //----------------------------------------------------------------------
 
   always @(posedge clk) begin
       // Sequential Internal Logic Here
	if (i_inc && !(i_clr)) begin 
		i <= i+1; // Really a counter, counting implemented on a higher level.
	end
	if (last_inc && !(rst)) begin 
		last <= last + 1; // Increment last register. 
	end
	if (i_clr && i_lt_last) begin
		i <= 0; // Clear the i register.
	end
	if (!i_lt_last) begin
		i <= 0; // Clear the i register.
	end
	if (rst) begin
		saved_level<= level; // Load the level.
		last<=0; // Clear the last register.
		i <= 0;
	end 		
   end
 
   // 64-entry 4-bit memory (from Memory.v) -- Fill in Ports!
   Memory mem(
       .clk     (clk),
       .rst     (1'b0),
       .r_addr  (i),
       .w_addr  (last),
       .w_data  (pattern),
       .w_en    (mem_ld),
       .r_data  ()
   );
 
   //----------------------------------------------------------------------
   // Output Logic -- Set Datapath Outputs
   //----------------------------------------------------------------------
 
   always @( * ) begin
       // Output Logic Here
	if (s_led_eq_pat) begin
        pattern_leds[3:0]=pattern[3:0];
	end
	else begin 
   		pattern_leds[3:0]=mem.r_data;
	end
   end
 
   // Some output done on wires (i.e. continuous output).
   assign i_lt_last = (i < last);
   assign arr_full = (last == 6'b111111);
   assign correct_pat = (pattern == mem.r_data);
   assign legal = (((pattern==4'b0001) || (pattern== 4'b0010) || (pattern == 4'b0100)   
   || (pattern ==4'b1000)) && (saved_level == 0)) || (saved_level == 1);
   
 
 
 
endmodule
 



//==============================================================================
// Control Module for Simon Project
//==============================================================================
 
module SimonControl(
   // External Inputs
   input        clk,           // Clock
   input        rst,           // Reset
 
   // Datapath Inputs
   input      i_lt_last,     // i < last
   input      arr_full,      // All 64 address in the register file are used
   input      correct_pat,   // High when correct pattern on pattern switches
   input      legal,         // A legal pattern reflected on pattern
 
   // Datapath Control Outputs
   output        last_inc,      // Increment last register when high
   output        i_inc,         // Increment i register when high
   output        i_clr,         // Clear i register when high
   output        mem_ld,        // Load memory when high
   output        s_led_eq_pat,  // When high, pattern_leds reflect what is on pattern
 
   // External Outputs
   output reg [2:0] mode_leds // Led shows what state you are in.
 
);
 
   // Declare Local Vars Here
   reg [1:0] state;
   reg [1:0] next_state;
 
   // LED Light Parameters
   localparam LED_MODE_INPUT    = 3'b001;
   localparam LED_MODE_PLAYBACK = 3'b010;
   localparam LED_MODE_REPEAT   = 3'b100;
   localparam LED_MODE_DONE     = 3'b111;
 
   // Declare State Names Here
   localparam STATE_INPUT       = 2'd0;
   localparam STATE_PLAYBACK    = 2'd1;
   localparam STATE_REPEAT      = 2'd2;
   localparam STATE_DONE        = 2'd3;
 
   // Output Combinational Logic
   always @( * ) begin
       // Set defaults
    mode_leds = 3'b000;
 
    // Handle mode leds.
    case (state) 
        STATE_INPUT: begin 
        mode_leds = LED_MODE_INPUT; 
        end 
        STATE_PLAYBACK: begin 
        mode_leds = LED_MODE_PLAYBACK; 
        end
        STATE_REPEAT: begin 
        mode_leds = LED_MODE_REPEAT; 
        end
        STATE_DONE: begin 
        mode_leds =LED_MODE_DONE; 
        end
        endcase
   end
 
   assign last_inc = (state==STATE_REPEAT) && !(arr_full) && !(i_lt_last) && (correct_pat); 
   assign i_inc = (state==STATE_PLAYBACK) || ((state==STATE_REPEAT)&&(correct_pat)) || (state==STATE_DONE);
   assign i_clr = (state==STATE_INPUT) || ((state==STATE_REPEAT) && !(correct_pat));
   assign mem_ld = (state==STATE_INPUT);
   assign s_led_eq_pat = (state==STATE_INPUT)|| (state== STATE_REPEAT);
 
   // Next State Combinational Logic
   always @( * ) begin
       next_state = state; 
 
    case (state) 
        STATE_INPUT: begin 
            if (legal) begin
            next_state = STATE_PLAYBACK;
            end 
            else begin
            next_state = STATE_INPUT;
            end 
        end
        
        STATE_PLAYBACK: begin 
            if (!i_lt_last) begin
                next_state = STATE_REPEAT;
            end
            else begin
                next_state = STATE_PLAYBACK;
            end
        end
 
        STATE_REPEAT: begin 
            if ((!correct_pat) || (correct_pat && !i_lt_last && arr_full)) begin
                next_state = STATE_DONE; 
            end
            else if (correct_pat && !i_lt_last && !arr_full) begin
                next_state = STATE_INPUT;
            end
            else begin
                next_state = STATE_REPEAT;
            end

        end
 
        STATE_DONE: begin
        next_state = STATE_DONE; 
        end 
        
endcase
 
   end
 
   // State Update Sequential Logic
   always @(posedge clk) begin
       if (rst) begin
           // Update state to reset state
           state <= STATE_INPUT;
       end
       else begin
           // Update state to next state
           state <= next_state;
       end
   end
 
endmodule

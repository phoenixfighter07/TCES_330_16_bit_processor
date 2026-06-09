/*
 * TCES 330
 * Robert Cromer and Landon Wardle
 * 6/4/2026
 * Top-level project file for the processor
 */ 

/*
 * The top-level interface for the processor that interacts with the DE2 board
 *
 * HEX3, 2, 1, and 0 always display the current contents of the IR
 * SW[17:15] determine the information displayed on the hex displays.
 * 	SW[17:15] = 0; HEX7, HEX6 = PC, HEX5, HEX4 = Current State
 * 	SW[17:15] = 1; HEX7, 6, 5, 4 = ALU_A (A-side input to ALU)
 * 	SW[17:15] = 2; HEX7, 6, 5, 4 = ALU_B (B-side input to ALU)
 * 	SW[17:15] = 3; HEX7, 6, 5, 4 = ALU_Out (ALU output)
 * 	SW[17:15] = 4; HEX7 = Next State, HEX6, 5, 4 = 0;
 * 	SW[17:15] = 5-7; Unused
 * 
 * KEY[1] acts as a synchronous system reset
 * KEY[2] acts as the system clock
 *
 * CLOCK_50 is the 50 MHz clock built-in to the DE2
 */
module Project(SW, LEDR, LEDG, KEY, HEX7, HEX6, HEX5, HEX4, HEX3, HEX2, HEX1, HEX0, CLOCK_50);
	input [17:0] SW;
	input [3:0] KEY;
	input CLOCK_50;
	
	output [17:0] LEDR;
	output [3:0] LEDG;
	output [0:6] HEX7, HEX6, HEX5, HEX4, HEX3, HEX2, HEX1, HEX0;

	// Match LEDs to switch states
	assign LEDR = SW;
	assign LEDG = ~KEY;

	// Wires
	logic D_wr, RF_s, RF_W_en;
	logic [6:0] D_addr, PC_OUT; 
	logic [3:0] RF_W_addr, RF_Ra_Addr, RF_Rb_Addr, State, NextState;
	logic [2:0] ALU_s0;
	logic [15:0] ALU_inA, ALU_inB, ALU_out, IR_OUT;

	logic KEY_2_OUT, KEY_2_OUT_FILTERED;
	logic [15:0] MuxOUT;

	localparam LOW = 4'h0;

	logic[2:0] S;
	
	assign S = SW[17:15];

	ButtonSynchronizer synch1 ( .Clk(CLOCK_50), .bi(KEY[2]), .bo(KEY_2_OUT), .StateOut());
	KeyFilter filter1 (.Clk(CLOCK_50), .In(KEY_2_OUT), .Out(KEY_2_OUT_FILTERED));

    Processor processor( 
		.Clk(KEY_2_OUT_FILTERED), 
		.ResetN(KEY[1]),
		.IR_Out(IR_OUT), 
		.PC_Out(PC_OUT), 
		.State(State), 
		.NextState(NextState), 
		.ALU_A(ALU_inA),
		.ALU_B(ALU_inB), 
		.ALU_Out(ALU_out)
	);

	// module Decoder (Hex, V);
	Decoder decoder7 (.Hex(HEX7), .V(MuxOUT[15:12]));
	Decoder decoder6 (.Hex(HEX6), .V(MuxOUT[11:8]));
	Decoder decoder5 (.Hex(HEX5), .V(MuxOUT[7:4]));
	Decoder decoder4 (.Hex(HEX4), .V(MuxOUT[3:0]));
	
	Decoder decoder3 (.Hex(HEX3), .V(IR_OUT[15:12]));
	Decoder decoder2 (.Hex(HEX2), .V(IR_OUT[11:8]));
	Decoder decoder1 (.Hex(HEX1), .V(IR_OUT[7:4]));
	Decoder decoder0 (.Hex(HEX0), .V(IR_OUT[3:0]));

	// MuxnW_8to1(M, R, T, U, V, W, X, Y, Z, S);

	MuxnW_8to1 Mux (
		.M(MuxOUT), 
		.R({{1'b0, PC_OUT[6:4]}, PC_OUT[3:0], LOW, State}), 
		.T(ALU_inA), 
		.U(ALU_inB), 
		.V(ALU_out), 
		.W({4'h0, NextState, 8'h0}), 
		.X(16'h0), 
		.Y(16'h0), 
		.Z(16'h0), 
		.S(S)
	);
endmodule
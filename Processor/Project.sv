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
module Project(SW, LEDR, KEY, HEX7, HEX6, HEX5, HEX4, HEX3, HEX2, HEX1, HEX0, CLOCK_50);
	input [17:0] SW;
	input [2:1] KEY;
	input CLOCK_50;
	
	output [17:0] LEDR;
	output [0:6] HEX7, HEX6, HEX5, HEX4, HEX3, HEX2, HEX1, HEX0;

	// Match LEDs to switch states
	assign LEDR = SW;

	// Wires
	logic D_wr, RF_s, RF_W_en;
	logic [7:0] D_addr, PC_OUT; 
	logic [3:0] RF_W_addr, RF_Ra_Addr, RF_Rb_Addr, State, NextState;
	logic [2:0] ALU_s0;
	logic [15:0] ALU_inA, ALU_inB, ALU_out, IR_OUT;

	logic KEY_1_OUT, KEY_1_OUT_FILTERED, KEY_2_OUT, KEY_2_OUT_FILTERED;
	logic [3:0] HEX7MuxOut, HEX6MuxOut, HEX5MuxOut, HEX4MuxOut;

	localparam LOW = 4'h0;

	logic[2:0] S;
	
	assign S = SW[17:15];

	ButtonSynchronizer synch1 ( .Clk(CLOCK_50), .bi(KEY[1]), .bo(KEY_1_OUT), .StateOut());
	KeyFilter filter1 (.Clk(CLOCK_50), .In(KEY_1_OUT), .Out(KEY_1_OUT_FILTERED));

	ButtonSynchronizer synch2 ( .Clk(CLOCK_50), .bi(KEY[2]), .bo(KEY_2_OUT), .StateOut());
	KeyFilter filter2 (.Clk(CLOCK_50), .In(KEY_2_OUT), .Out(KEY_2_OUT_FILTERED));

    Processor processor( 
		.Clk(KEY_2_OUT_FILTERED), 
		.ResetN(KEY_1_OUT_FILTERED),
		.IR_Out(IR_OUT), 
		.PC_Out(PC_OUT), 
		.State(State), 
		.NextState(NextState), 
		.ALU_A(ALU_inA),
		.ALU_B(ALU_inB), 
		.ALU_Out(ALU_out)
	);

	// module Decoder (Hex, V);
	Decoder decoder7 (.Hex(HEX7), .V(HEX7MuxOut));
	Decoder decoder6 (.Hex(HEX6), .V(HEX6MuxOut));
	Decoder decoder5 (.Hex(HEX5), .V(HEX5MuxOut));
	Decoder decoder4 (.Hex(HEX4), .V(HEX4MuxOut));
	
	Decoder decoder3 (.Hex(HEX3), .V(IR_OUT[15:12]));
	Decoder decoder2 (.Hex(HEX2), .V(IR_OUT[11:8]));
	Decoder decoder1 (.Hex(HEX1), .V(IR_OUT[7:4]));
	Decoder decoder0 (.Hex(HEX0), .V(IR_OUT[3:0]));

	//MuxnW_8to1(M, R, T, U, V, W, X, Y, Z, S);
	MuxnW_8to1 HEX7Mux (.M(HEX7MuxOut), .R(PC_OUT[7:4]), .T(ALU_inA[15:12]), .U(ALU_inB[15:12]), .V(ALU_inB[15:12]), .W(NextState), .X(LOW), .Y(LOW), .Z(LOW), .S(S));
	MuxnW_8to1 HEX6Mux (.M(HEX6MuxOut), .R(PC_OUT[3:0]), .T(ALU_inA[11:8]), .U(ALU_inB[11:8]), .V(ALU_inB[11:8]), .W(LOW), .X(LOW), .Y(LOW), .Z(LOW), .S(S));
	MuxnW_8to1 HEX5Mux (.M(HEX5MuxOut), .R(LOW), .T(ALU_inA[7:4]), .U(ALU_inB[7:4]), .V(ALU_inB[7:4]), .W(LOW), .X(LOW), .Y(LOW), .Z(LOW), .S(S));
	MuxnW_8to1 HEX4Mux (.M(HEX4MuxOut), .R(State), .T(ALU_inA[3:0]), .U(ALU_inB[3:0]), .V(ALU_inB[3:0]), .W(LOW), .X(LOW), .Y(LOW), .Z(LOW), .S(S));
endmodule
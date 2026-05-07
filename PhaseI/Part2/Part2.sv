// Robert Cromer and Landon Wardle
// Spring 2026
// TCES 330
// This file contains the code for testing the ALU module on an Altera DE2-115

module Part2(SW, HEX0, LEDR);
	input [17:7] SW;
	output [17:7] LEDR;
	output [0:6] HEX0;
	logic [3:0] encodedNumber;
	
	// module ALU (A, B, Sel, Q)
	ALU #(.bits(4)) DUT(SW[14:11], SW[10:7], SW[17:15], encodedNumber);
	
	// module Decoder (Hex, V);
	Decoder (HEX0, encodedNumber);
	
	assign LEDR = SW;
endmodule
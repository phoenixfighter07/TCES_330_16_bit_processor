/*
 * TCES 330
 * Landon Wardle
 * 4/23/2026
 * Module for an n bit 8 to 1 Multiplexer and its testbench
 */
module MuxnW_8to1(M, R, T, U, V, W, X, Y, Z, S);
	parameter n = 4;

	output logic [(n - 1):0] M;
	input [(n - 1):0] R, T, U, V, W, X, Y, Z;
	input [2:0] S;

	always_comb begin
		case (S)
			0: M = R; 
			1: M = T; 
			2: M = U; 
			3: M = V; 
			4: M = W; 
			5: M = X; 
			6: M = Y; 
			7: M = Z; 
		endcase
	end
endmodule

`ifdef MODEL_TECH
module MuxnW_8to1_testbench();
	localparam n = 4;

	logic [(n - 1):0] M, R, T, U, V, W, X, Y, Z;
	logic [2:0] S;

	MuxnW_8to1 DUT(M, R, T, U, V, W, X, Y, Z, S); // Design under test

	initial begin
		// Assign different values to each signal to test mux
		R = 0;
		T = 1;
		U = 2;
		V = 3;
		W = 4;
		X = 5;
		Y = 6;
		Z = 7;

		// Set up modelsim debug
		$display("R\tT\tU\tV\tW\tX\tY\tZ\tS\tM");
		$monitor("%h\t%h\t%h\t%h\t%h\t%h\t%h\t%h\t%h\t%h", R, T, U, V, W, X, Y, Z, S, M);

		// Test that the mux can switch between the fixed eight signals
		for (int i = 0; i < 8; i++) begin
			{S} = i; #5;
		end

		// Test that the mux can allow signals to vary

		S = 0; // Reset to read signal U

		for (int i = 0; i < 8; i++) begin
			{U} = i; #5;
		end

		// Edgecase 1, all signals are 000
		R = 0;
		T = 1;
		U = 2;
		V = 3;
		W = 4;
		X = 5;
		Y = 6;
		Z = 7;

		// Test that the mux can switch between the fixed eight signals
		for (int i = 0; i < 8; i++) begin
			{S} = i; #5;
		end

		// Edgecase 2, all signals are 111
		R = 0;
		T = 1;
		U = 2;
		V = 3;
		W = 4;
		X = 5;
		Y = 6;
		Z = 7;

		// Test that the mux can switch between the fixed eight signals
		for (int i = 0; i < 8; i++) begin
			{S} = i; #5;
		end
	end
endmodule
`endif
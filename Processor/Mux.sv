/*
 * TCES 330
 * Robert Cromer and Landon Wardle
 * 6/2/2026
 * Module for a 16-bit 2 to 1 mux.
 */

/*
 * A 16-bit 2 to 1 mux. 
 *
 * M is the selected signal.
 * X is the first input signal. 
 * Y is the second input signal.
 * S is the selecting signal.
 */
module Mux(M, X, Y, S);
	output logic [15:0] M;
	input [15:0] X, Y;
	input S;

	assign M = S ? Y : X;
endmodule

/* Utility task for debugging */
task Validate(input M, input X, input Y, input S);
	localparam string ASSERT_MESSAGE = "Incorrect Mux output! S = %b, so expected M = %h (%s), got M = %h.";

	if (S == 1'b0) begin
		assert(M == X)
		else $error(ASSERT_MESSAGE, S, X, "X", M);
	end else if (S == 1'b1) begin
		assert(M == Y)
		else $error(ASSERT_MESSAGE, S, Y, "Y", M);
	end else begin
		$error("S value not bound to 0 or 1. Got S = %b.", S);
	end
endtask

module Mux_tb();
	localparam RANDOM_CASE_COUNT = 67;

	logic [15:0] M, X, Y;
	logic S;

	Mux DUT(M, X, Y, S); 

	initial begin
		// Assign different values to each signal to test mux
		X = 16'h0000;
		Y = 16'h0000;
		S = 1'b0;

		// Set up monitor
		$timeformat(-12, 0, "", 5);
		$display("time\tX\tY\tS\tM");
		$monitor("%t\t%h\t%h\t%h\t%b", $time, M, X, Y, S);

		// Test that the mux can switch between the fixed eight signals
		for (int i = 0; i < 2; i++) begin
			{S} = i; #5;
			Validate(M, X, Y, S);
		end

		// Test that the mux can allow signals to vary

		S = 0; // Reset to read signal X

		for (int i = 0; i < 2; i++) begin
			{X} = i; #5;
			Validate(M, X, Y, S);
		end

		// Edgecase 1, all signals are 0
		X = 16'h0000;
		Y = 16'h0000;
		S = 1'b0;

		// Test that the mux can switch between the fixed eight signals
		for (int i = 0; i < 2; i++) begin
			{S} = i; #5;
			Validate(M, X, Y, S);
		end

		// Edgecase 2, all signals are 1
		X = 16'h1111;
		Y = 16'h1111;
		S = 1'b1;

		// Test that the mux can switch between the fixed eight signals
		for (int i = 0; i < 2; i++) begin
			{S} = i; #5;
			Validate(M, X, Y, S);
		end

		// Test various random cases

		for (int i = 0; i < RANDOM_CASE_COUNT; i++) begin
			{X, Y, S} = {$random, $random}; #5;
			Validate(M, X, Y, S);
		end
	end
endmodule
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
 */
module Project(SW, LEDR, KEY, HEX7, HEX6, HEX5, HEX4, HEX3, HEX2, HEX1, HEX0);
	input [17:0] SW;
	input [2:1] KEY;
	output [17:0] LEDR;

	// Match LEDs to switch states
	assign LEDR = SW;

	
endmodule
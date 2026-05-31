/*
 * TCES 330
 * Landon Wardle
 * 5/28/2026
 * 16-Bit Processor Project Phase V
 */ 

/*
 * The FSM for the CPU's control unit.
 *
 * Clk is the input clock signal.
 * ResetN is the active-low reset signal to send the FSM back to the initialization state.
 * Instruction is the instruction coming in to the FSM
 */
typedef enum logic [3:0] 
{ 
	Init, 
	Fetch,
	Decode,
	NOOP,
	LOAD_A,
	STORE, 
	ADD,
	HALT,
	SUB,
	LOAD_B
} state;

module ControlUnit(
	Clk, 
	ResetN, 
	Instruction,
	PC_clr,
	PC_up,
	IR_ld,
	D_addr,
	D_wr, 
	RF_s, 
	RF_Ra_addr, 
	RF_Rb_addr, 
	RF_W_en, 
	RF_W_addr, 
	ALU_s0);

	input Clk, ResetN;
	input [15:0] Instruction;
	output logic PC_up,
		   IR_ld,
		   D_wr, 
		   PC_clr,
		   RF_s, 
		   RF_W_en,  
		   ALU_s0;
	output logic [3:0] RF_W_addr, 
		   RF_Ra_addr, 
		   RF_Rb_addr;
	output logic [7:0] D_addr;

	state currentState, nextState;

	// Combinational portion
	always_comb begin
		if (ResetN) begin
			case(currentState)
				Init: begin
					PC_clr = 1;
					nextState = Fetch;
				end
				Fetch: begin
					PC_clr = 0;
					PC_up = 0;
					IR_ld = 1;
					D_addr = 0;
					D_wr = 0;
					RF_s = 0;
					RF_Ra_addr = 0;
					RF_Rb_addr = 0;
					RF_W_en = 0;
					RF_W_addr = 0;
					ALU_s0 = 0;
					PC_up = 0;
					nextState = Decode;
				end
				Decode: begin
					// Extract Opcode
					case(Instruction[15:12])
						4'd0: nextState = NOOP;
						4'd1: nextState = STORE;
						4'd2: nextState = LOAD_A;
						4'd3: nextState = ADD;
						4'd4: nextState = SUB;
						4'd5: nextState = HALT;
					endcase
				end
				ADD: begin
					RF_W_addr = Instruction[3:0];
					RF_W_en = 1;
					RF_Ra_addr = Instruction[11:8];
					RF_Rb_addr = Instruction[7:4];
					ALU_s0 = 1;
					nextState = Fetch;
				end
				SUB: begin
					RF_W_addr = Instruction[3:0];
					RF_W_en = 1;
					RF_Ra_addr = Instruction[11:8];
					RF_Rb_addr = Instruction[7:4];
					ALU_s0 = 2;
					nextState = Fetch;
				end
				STORE: begin
					D_addr = Instruction[7:0];
					D_wr = 1;
					RF_Ra_addr = Instruction[11:8];
					nextState = Fetch;
				end
				LOAD_A: begin
					D_addr = Instruction[11:4];
					RF_s = 1;
					RF_W_addr = Instruction[3:0];
					nextState = LOAD_B;
				end
				LOAD_B: begin
					D_addr = Instruction[11:4];
					RF_s = 1;
					RF_W_addr = Instruction[3:0];
					RF_W_en = 1;
					nextState = Fetch;
				end
				NOOP: nextState = Fetch;
				HALT: nextState = HALT;
				default: nextState = Init;
			endcase
		end else begin
			nextState = Init;
		end
	end

	// Sequential portion
	always_ff @( posedge Clk ) begin
		currentState <= nextState;
	end
endmodule

module ControlUnit_tb();
	logic Clk, ResetN;
	logic [15:0] Instruction;
	logic PC_up,
		   IR_ld,
		   D_wr, 
		   RF_s, 
		   RF_W_en,  
		   ALU_s0;
	logic [3:0] RF_W_Add, 
		   RF_Ra_addr, 
		   RF_Rb_addr;
	logic [7:0] D_addr;

    localparam CLK_CYCLE_TIME = 10;

    // Initialize the clock
	always begin
		#(CLK_CYCLE_TIME / 2) Clk = 0;
		#(CLK_CYCLE_TIME / 2) Clk = 1;
	end

	ControlUnit DUT (
		Clk, 
		ResetN, 
		Instruction,
		PC_clr,
		PC_up,
		IR_ld,
		D_addr,
		D_wr, 
		RF_s, 
		RF_Ra_addr, 
		RF_Rb_addr, 
		RF_W_en, 
		RF_W_addr, 
		ALU_s0);

	// Wait n clock cycles
	task automatic WaitCycles(input [31:0] n);
		repeat (n) begin
			@(posedge Clk);
		end
	endtask

	// Resets the FSM
	task automatic ResetFSM();
		ResetN = 0;

		WaitCycles(1);

		ResetN = 1;

		WaitCycles(1);
	endtask

	initial begin
		WaitCycles(1);

		$timeformat(-12, 0, "", 5);
		$display("Time\tClk\tResetN\tInstruction\tPC_clr\tPC_up\tIR_ld\tD_addr\tD_wr\tRF_s\tRF_Ra_addr\tRF_Rb_addr\tRF_W_en\tRF_W_addr\tALU_s0");
		$monitor("%t\t%b\t%b\t%h\t%b\t%b\t%b\t%h\t%b\t%b\t%h\t%h\t%b\t%h\t%b", $realtime, 		
			Clk, 
			ResetN, 
			Instruction,
			PC_clr,
			PC_up,
			IR_ld,
			D_addr,
			D_wr, 
			RF_s, 
			RF_Ra_addr, 
			RF_Rb_addr, 
			RF_W_en, 
			RF_W_addr, 
			ALU_s0);

		// Set FSM to predictable state.
		ResetFSM();

		// Test all the instruction control signals

		// Set instruction to NOOP
		Instruction = 16'h0000;

		assert(PC_clr) 
		else $error("PC_clr not asserted when reset! Got PC_clr = %b, expected PC_clr = %b.", PC_clr, 1);

		// Enter Fetch
		WaitCycles(1);

		assert(~PC_clr) 
		else $error("PC_clr not deasserted when in fetch! Got PC_clr = %b, expected PC_clr = %b.", PC_clr, 0);

		assert(PC_up) 
		else $error("PC_up not asserted when in fetch! Got PC_up = %b, expected PC_up = %b.", PC_up, 1);

		assert(IR_ld) 
		else $error("IR_ld not asserted when in fetch! Got IR_ld = %b, expected IR_ld = %b.", IR_ld, 1);

		// Enter Decode
		WaitCycles(1);

		ResetFSM();

		// Set instruction to STORE from register B to address A1
		Instruction = 16'h1BA1;

		WaitCycles(3);

		assert(D_addr == Instruction[7:0]) 
		else $error("D_addr did not take on the correct value! Got D_addr = %h, expected D_addr = %h.", D_addr, Instruction[7:0]);

		assert(D_wr) 
		else $error("D_wr not asserted when in store! Got D_wr = %b, expected D_wr = %b.", D_wr, 1);

		assert(RF_Ra_addr == Instruction[11:8]) 
		else $error("RF_Ra_addr did not take on the correct value! Got RF_Ra_addr = %h, expected RF_Ra_addr = %h.", RF_Ra_addr, Instruction[11:8]);

		// Return to fetch
		WaitCycles(1);

		ResetFSM();

		// Set instruction to LOAD from Address CD to register 2
		Instruction = 16'h2CD2; 

		WaitCycles(3);

		assert(D_addr == Instruction[11:4]) 
		else $error("D_addr did not take on the correct value! Got D_addr = %h, expected D_addr = %h.", D_addr, Instruction[11:4]);

		assert(RF_s) 
		else $error("RF_s not asserted when in load_a! Got RF_s = %b, expected RF_s = %b.", RF_s, 1);

		assert(RF_W_addr == Instruction[3:0]) 
		else $error("RF_W_addr did not take on the correct value! Got RF_W_addr = %h, expected RF_W_addr = %h.", RF_W_addr, Instruction[3:0]);

		WaitCycles(1);

		assert(D_addr == Instruction[11:4]) 
		else $error("D_addr did not hold the correct value! Got D_addr = %h, expected D_addr = %h.", D_addr, Instruction[11:4]);

		assert(RF_s) 
		else $error("RF_s did not stay asserted when in load_b! Got RF_s = %b, expected RF_s = %b.", RF_s, 1);

		assert(RF_W_en) 
		else $error("RF_W_en did not assert when in load_b! Got RF_W_en = %b, expected RF_W_en = %b.", RF_W_en, 1);

		assert(RF_W_addr == Instruction[3:0]) 
		else $error("RF_W_addr did not hold the correct value! Got RF_W_addr = %h, expected RF_W_addr = %h.", RF_W_addr, Instruction[3:0]);

		// Return to fetch
		WaitCycles(1);

		ResetFSM();

		// Set instruction to ADD, add register F and register 1, then store into register 3
		Instruction = 16'h3F13; 

		WaitCycles(3);

		assert(RF_s) 
		else $error("RF_s did not stay asserted when in load_b! Got RF_s = %b, expected RF_s = %b.", RF_s, 1);

		assert(RF_W_en) 
		else $error("RF_W_en did not assert when in load_b! Got RF_W_en = %b, expected RF_W_en = %b.", RF_W_en, 1);

		assert(RF_W_addr == Instruction[3:0]) 
		else $error("RF_W_addr did not hold the correct value! Got RF_W_addr = %h, expected RF_W_addr = %h.", RF_W_addr, Instruction[3:0]);

		assert(RF_Ra_addr == Instruction[11:8]) 
		else $error("RF_Ra_addr did not take on the correct value! Got RF_Ra_addr = %h, expected RF_Ra_addr = %h.", RF_Ra_addr, Instruction[11:8]);

		assert(RF_Rb_addr == Instruction[7:4]) 
		else $error("RF_Rb_addr did not take on the correct value! Got RF_Rb_addr = %h, expected RF_Rb_addr = %h.", RF_Rb_addr, Instruction[7:4]);

		assert(ALU_s0 == 1) 
		else $error("ALU_s0 is not the correct operation! Got ALU_s0 = %h, expected ALU_s0 = %h.", ALU_s0, 1);

		// Return to fetch
		WaitCycles(1);

		ResetFSM();

		// Set instruction to SUB, subtract register E, register 3, then store into register 2
		Instruction = 16'h4E32; 

		WaitCycles(3);

		assert(RF_s) 
		else $error("RF_s did not stay asserted when in load_b! Got RF_s = %b, expected RF_s = %b.", RF_s, 1);

		assert(RF_W_en) 
		else $error("RF_W_en did not assert when in load_b! Got RF_W_en = %b, expected RF_W_en = %b.", RF_W_en, 1);

		assert(RF_W_addr == Instruction[3:0]) 
		else $error("RF_W_addr did not hold the correct value! Got RF_W_addr = %h, expected RF_W_addr = %h.", RF_W_addr, Instruction[3:0]);

		assert(RF_Ra_addr == Instruction[11:8]) 
		else $error("RF_Ra_addr did not take on the correct value! Got RF_Ra_addr = %h, expected RF_Ra_addr = %h.", RF_Ra_addr, Instruction[11:8]);

		assert(RF_Rb_addr == Instruction[7:4]) 
		else $error("RF_Rb_addr did not take on the correct value! Got RF_Rb_addr = %h, expected RF_Rb_addr = %h.", RF_Rb_addr, Instruction[7:4]);

		assert(ALU_s0 == 2) 
		else $error("ALU_s0 is not the correct operation! Got ALU_s0 = %h, expected ALU_s0 = %h.", ALU_s0, 2);

		// Return to fetch
		WaitCycles(1);

		// Set instruction to HALT
		Instruction = 16'h5EFF; 

		WaitCycles(4);

		assert(DUT.currentState == HALT) 
		else $error("Control unit not in halt state! Got currentState = %h, expected currentState = %h.", DUT.currentState, HALT);
		
		WaitCycles(4);

		assert(DUT.currentState == HALT) 
		else $error("Control did not maintain halt state! Got currentState = %h, expected currentState = %h.", DUT.currentState, HALT);

		$stop;
	end
endmodule
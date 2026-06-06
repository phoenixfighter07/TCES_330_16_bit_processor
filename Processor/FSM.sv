/*
 * TCES 330
 * Robert Cromer and Landon Wardle
 * 5/28/2026
 * 16-Bit Processor Project Phase V
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


/*
 * The FSM for the CPU's control unit.
 *
 * Clk is the input clock signal.
 * ResetN is the active-low reset signal to send the FSM back to the initialization state.
 * Instruction is the 16-bit instruction coming in to the FSM
 * PC_clr is the clear signal for the program counter
 * PC_up is the increment signal for the program counter
 * IR_ld is the load signal for the instruction register
 * D_addr is the 8-bit address in RAM to operate on
 * D_wr is the write signal for the RAM
 * RF_s is the selecting signal for the mux leading in to the register file, 0 = ALU, 1 = RAM
 * RF_Ra_Addr is the 4-bit address of register A in the register file
 * RF_Rb_Addr is the 4-bit address of register B in the register file
 * RF_W_en is the write signal for the register file
 * RF_W_addr is the 4-bit address of the register to write to in the register file
 * ALU_s0 is the 3-bit operation signal feeding into the ALU
 * CurrentState is the 4-bit output signal of the FSM's current state
 * NextState is the 4-bit output signal of the FSM's next state
 */
module FSM(
	Clk, 
	ResetN, 
	Instruction,
	PC_clr,
	PC_up,
	IR_ld,
	D_addr,
	D_wr, 
	RF_s, 
	RF_Ra_Addr, 
	RF_Rb_Addr, 
	RF_W_en, 
	RF_W_addr, 
	ALU_s0,
	CurrentState_out,
	NextState_out);

	input Clk, ResetN;
	input [15:0] Instruction;
	output logic PC_up,
		   IR_ld,
		   D_wr, 
		   PC_clr,
		   RF_s, 
		   RF_W_en;
	output logic [3:0] RF_W_addr, 
		   RF_Ra_Addr, 
		   RF_Rb_Addr;
	output logic [7:0] D_addr;
	output logic [2:0] ALU_s0;

	state CurrentState, NextState;

	output state CurrentState_out, NextState_out;

	assign CurrentState_out = CurrentState;
	assign NextState_out = NextState;

	always_comb begin
		// Default signal values
		PC_clr = 0;
		PC_up = 0;
		IR_ld = 0;
		D_addr = 0;
		D_wr = 0;
		RF_s = 0;
		RF_Ra_Addr = 0;
		RF_Rb_Addr = 0;
		RF_W_en = 0;
		RF_W_addr = 0;
		ALU_s0 = 0;

		case(CurrentState)
			Init: begin
				PC_clr = 1;
			end
			Fetch: begin
				PC_clr = 0;
				PC_up = 1;
				IR_ld = 1;
				D_addr = 0;
				D_wr = 0;
				RF_s = 0;
				RF_Ra_Addr = 0;
				RF_Rb_Addr = 0;
				RF_W_en = 0;
				RF_W_addr = 0;
				ALU_s0 = 0;
			end
			Decode: begin
				// Nothing
			end
			ADD: begin
				RF_W_addr = Instruction[3:0];
				RF_W_en = 1;
				RF_Ra_Addr = Instruction[11:8];
				RF_Rb_Addr = Instruction[7:4];
				ALU_s0 = 1;
			end
			SUB: begin
				RF_W_addr = Instruction[3:0];
				RF_W_en = 1;
				RF_Ra_Addr = Instruction[11:8];
				RF_Rb_Addr = Instruction[7:4];
				ALU_s0 = 2;
			end
			STORE: begin
				D_addr = Instruction[7:0];
				D_wr = 1;
				RF_Ra_Addr = Instruction[11:8];
			end
			LOAD_A: begin
				D_addr = Instruction[11:4];
				RF_s = 1;
				RF_W_addr = Instruction[3:0];
			end
			LOAD_B: begin
				D_addr = Instruction[11:4];
				RF_s = 1;
				RF_W_addr = Instruction[3:0];
				RF_W_en = 1;
			end
			default: begin
				// Nothing
			end
		endcase
	end

	// Combinational portion
	always_comb begin
		if (ResetN) begin
			case(CurrentState)
				Init: NextState = Fetch;
				Fetch: NextState = Decode;
				Decode: begin
					// Extract Opcode
					case(Instruction[15:12])
						4'd0: NextState = NOOP;
						4'd1: NextState = STORE;
						4'd2: NextState = LOAD_A;
						4'd3: NextState = ADD;
						4'd4: NextState = SUB;
						4'd5: NextState = HALT;
						default: NextState = Init;
					endcase
				end
				ADD: NextState = Fetch;
				SUB: NextState = Fetch;
				STORE: NextState = Fetch;
				LOAD_A: NextState = LOAD_B;
				LOAD_B: NextState = Fetch;
				NOOP: NextState = Fetch;
				HALT: NextState = HALT;
				default: NextState = Init;
			endcase
		end else begin
			NextState = Init;
		end
	end

	// Sequential portion
	always_ff @( posedge Clk ) begin
		CurrentState <= NextState;
	end
endmodule

module FSM_tb();
	logic Clk, ResetN;
	logic [15:0] Instruction;
	logic PC_up,
		   IR_ld,
		   D_wr, 
		   PC_clr,
		   RF_s, 
		   RF_W_en;
	logic [3:0] RF_W_addr, 
		   RF_Ra_Addr, 
		   RF_Rb_Addr;
	logic [7:0] D_addr;
	logic [2:0] ALU_s0;

	logic [3:0] CurrentState, NextState;

    localparam CLK_CYCLE_TIME = 20;

    // Initialize the clock
	always begin
		#(CLK_CYCLE_TIME / 2) Clk = 0;
		#(CLK_CYCLE_TIME / 2) Clk = 1;
	end

	FSM DUT (
		Clk, 
		ResetN, 
		Instruction,
		PC_clr,
		PC_up,
		IR_ld,
		D_addr,
		D_wr, 
		RF_s, 
		RF_Ra_Addr, 
		RF_Rb_Addr, 
		RF_W_en, 
		RF_W_addr, 
		ALU_s0,
		CurrentState,
		NextState);

	// Wait n clock cycles
	task automatic WaitCycles(input [31:0] n);
		repeat (n) begin
			@(negedge Clk);
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
		$timeformat(-12, 0, "", 5);
		$display("Time\tClk\tResetN\tInst\tPC_clr\tPC_up\tIR_ld\tD_addr\tD_wr\tRF_s\tRF_Ra_Addr\tRF_Rb_Addr\tRF_W_en\tRF_W_addr\tALU_s0");
		$monitor("%t\t%b\t%b\t%h\t%b\t%b\t%b\t%h\t%b\t%b\t%h\t%h\t%b\t%h\t%b",
			$realtime, 		
			Clk, 
			ResetN, 
			Instruction,
			PC_clr,
			PC_up,
			IR_ld,
			D_addr,
			D_wr, 
			RF_s, 
			RF_Ra_Addr, 
			RF_Rb_Addr, 
			RF_W_en, 
			RF_W_addr, 
			ALU_s0);

		// Set FSM to predictable state.
		ResetFSM();

		// Test all the instruction control signals

		// Set instruction to NOOP
		Instruction = 16'h0000;

		assert(PC_clr) 
		else $error("PC_clr not asserted when reset! Expected PC_clr = %b, got PC_clr = %b.", 1'b1, PC_clr);

		// Enter Fetch
		WaitCycles(1);

		assert(~PC_clr) 
		else $error("PC_clr not deasserted when in fetch! Expected PC_clr = %b, got PC_clr = %b.", 1'b0, PC_clr);

		assert(PC_up) 
		else $error("PC_up not asserted when in fetch! Expected PC_up = %b, got PC_up = %b.", 1'b1, PC_up);

		assert(IR_ld) 
		else $error("IR_ld not asserted when in fetch! Expected IR_ld = %b, got IR_ld = %b.", 1'b1, IR_ld);

		// Enter Decode
		WaitCycles(1);

		ResetFSM();

		// Set instruction to STORE from register B to address A1
		Instruction = 16'h1BA1;

		WaitCycles(2);

		assert(D_addr == Instruction[7:0]) 
		else $error("D_addr did not take on the correct value! Expected D_addr = %h, got D_addr = %h.", Instruction[7:0], D_addr);

		assert(D_wr) 
		else $error("D_wr not asserted when in store! Expected D_wr = %b, got D_wr = %b.", 1'b1, D_wr);

		assert(RF_Ra_Addr == Instruction[11:8]) 
		else $error("RF_Ra_Addr did not take on the correct value! Expected RF_Ra_Addr = %h, got RF_Ra_Addr = %h.", Instruction[11:8], RF_Ra_Addr);

		// Return to fetch
		WaitCycles(1);

		ResetFSM();

		// Set instruction to LOAD from Address CD to register 2
		Instruction = 16'h2CD3; 

		WaitCycles(2);

		assert(D_addr == Instruction[11:4]) 
		else $error("D_addr did not take on the correct value! Expected D_addr = %h, got D_addr = %h.", Instruction[11:4], D_addr);

		assert(RF_s) 
		else $error("RF_s not asserted when in load_a! Expected RF_s = %b, got RF_s = %b.", 1'b1, RF_s);

		assert(RF_W_addr == Instruction[3:0]) 
		else $error("RF_W_addr did not take on the correct value! Expected RF_W_addr = %h, got RF_W_addr = %h.", Instruction[3:0], RF_W_addr);

		WaitCycles(1);

		assert(D_addr == Instruction[11:4]) 
		else $error("D_addr did not hold the correct value! Expected D_addr = %h, got D_addr = %h.", Instruction[11:4], D_addr);

		assert(RF_s) 
		else $error("RF_s did not stay asserted when in load_b! Expected RF_s = %b, got RF_s = %b.", 1'b1, RF_s);

		assert(RF_W_en) 
		else $error("RF_W_en did not assert when in load_b! Expected RF_W_en = %b, got RF_W_en = %b.", 1'b1, RF_W_en);

		assert(RF_W_addr == Instruction[3:0]) 
		else $error("RF_W_addr did not hold the correct value! Expected RF_W_addr = %h, got RF_W_addr = %h.", Instruction[3:0], RF_W_addr);

		// Return to fetch
		WaitCycles(1);

		ResetFSM();

		// Set instruction to ADD, add register F and register 1, then store into register 3
		Instruction = 16'h3F13; 

		WaitCycles(2);

		assert(RF_W_en) 
		else $error("RF_W_en did not assert when in add! Expected RF_W_en = %b, got RF_W_en = %b.", 1'b1, RF_W_en);

		assert(RF_W_addr == Instruction[3:0]) 
		else $error("RF_W_addr did not hold the correct value! Expected RF_W_addr = %h, got RF_W_addr = %h.", Instruction[3:0], RF_W_addr);

		assert(RF_Ra_Addr == Instruction[11:8]) 
		else $error("RF_Ra_Addr did not take on the correct value! Expected RF_Ra_Addr = %h, got RF_Ra_Addr = %h.", Instruction[11:8], RF_Ra_Addr);

		assert(RF_Rb_Addr == Instruction[7:4]) 
		else $error("RF_Rb_Addr did not take on the correct value! Expected RF_Rb_Addr = %h, got RF_Rb_Addr = %h.", Instruction[7:4], RF_Rb_Addr);

		assert(ALU_s0 == 1) 
		else $error("ALU_s0 is not the correct operation! Expected ALU_s0 = %h, got ALU_s0 = %h.", 4'h1, ALU_s0);

		// Return to fetch
		WaitCycles(1);

		ResetFSM();

		// Set instruction to SUB, subtract register E, register 3, then store into register 2
		Instruction = 16'h4E32; 

		WaitCycles(2);

		assert(RF_W_en) 
		else $error("RF_W_en did not assert when in sub! Expected RF_W_en = %b, got RF_W_en = %b.", 1'b1, RF_W_en);

		assert(RF_W_addr == Instruction[3:0]) 
		else $error("RF_W_addr did not hold the correct value! Expected RF_W_addr = %h, got RF_W_addr = %h.", Instruction[3:0], RF_W_addr);

		assert(RF_Ra_Addr == Instruction[11:8]) 
		else $error("RF_Ra_Addr did not take on the correct value! Expected RF_Ra_Addr = %h, got RF_Ra_Addr = %h.", Instruction[11:8], RF_Ra_Addr);

		assert(RF_Rb_Addr == Instruction[7:4]) 
		else $error("RF_Rb_Addr did not take on the correct value! Expected RF_Rb_Addr = %h, got RF_Rb_Addr = %h.", Instruction[7:4], RF_Rb_Addr);

		assert(ALU_s0 == 2) 
		else $error("ALU_s0 is not the correct operation! Expected ALU_s0 = %h, got ALU_s0 = %h.", 4'h2, ALU_s0);

		// Return to fetch
		WaitCycles(1);

		// Set instruction to HALT
		Instruction = 16'h5EFF; 

		WaitCycles(4);

		assert(DUT.CurrentState == HALT) 
		else $error("Control unit not in halt state! Expected CurrentState = %h, got CurrentState = %h.", DUT.CurrentState, HALT);
		
		WaitCycles(4);

		assert(DUT.CurrentState == HALT) 
		else $error("Control did not maintain halt state! Expected CurrentState = %h, got CurrentState = %h.", DUT.CurrentState, HALT);

		$stop;
	end
endmodule
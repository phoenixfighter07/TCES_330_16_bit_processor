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
typedef enum logic [3:0] data_type 
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
};

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
	RF_W_Addr, 
	ALU_s0);

	input Clk, ResetN;
	input [15:0] Instruction;
	output PC_up,
		   IR_ld,
		   D_wr, 
		   RF_s, 
		   RF_W_en,  
		   ALU_s0;
	output [3:0] RF_W_Add, 
		   RF_Ra_addr, 
		   RF_Rb_addr;
	output [7:0] D_addr;

	logic [3:0] currentState, nextState;

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
					RF_W_Addr = 0;
					ALU_s0 = 0;
					PC_up = 0;
					nextState = Decode;
				end
				Decode: begin
					// Extract Opcode
					case(Instruction[15:12])
						4'd0: nextState = NOOP:
						4'd1: nextState = STORE;
						4'd2: nextState = LOAD;
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
					D_addr = Instruction[11:4]
					RF_s = 1
					RF_W_addr = Instruction[3:0]
					nextState = LOAD_B;
				end
				LOAD_B: begin
					D_addr = Instruction[11:4]
					RF_s = 1
					RF_W_addr = Instruction[3:0]
					RF_W_en = 1
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
		RF_W_Addr, 
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

		WaitCycles(2);

		ResetN = 1;
	endtask

	initial begin
		@(negedge Clk);

		$timeformat(-12, 0, "", 5);
		$display("Time\tClk\tResetN\tInstruction\tPC_clr\tPC_up\tIR_ld\tD_addr\tD_wr\tRF_s\tRF_Ra_addr\tRF_Rb_addr\tRF_W_en\tRF_W_Addr\tALU_s0");
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
			RF_W_Addr, 
			ALU_s0);

		// Set FSM to predictable state.
		ResetFSM();
	end
endmodule
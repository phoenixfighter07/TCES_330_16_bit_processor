/*
 * TCES 330
 * Robert Cromer and Landon Wardle
 * 6/2/2026
 * Module for the datapath of the processor.
 */

/*
 * Datapath of the project processor, contains the RAM, Mux, ALU, and Register File
 *
 * D_addr the 8-bit address in RAM
 * D_wr is the write-enable signal for the RAM
 * RF_s is the select signal to choose between RAM or the ALU to read from into the reg file
 * RF_W_addr is the 4-bit address of the register in the reg file to write to
 * RF_W_en is the write-enable signal for the reg file
 * RF_Ra_addr is the 4-bit address of the first register to read from from the reg file
 * RF_Rb_addr is the 4-bit address of the second register to read from from the reg file
 * ALU_s0 is the 3-bit ALU selecting signal for which operation to do
 *
 */
module Datapath(
	Clk,
	D_addr,
	D_wr,
	RF_s,
	RF_W_addr,
	RF_W_en,
	RF_Ra_addr,
	RF_Rb_addr,
	ALU_s0,
	ALU_inA,
	ALU_inB, 
	ALU_out
	);

	// Define inputs and outputs
	input D_wr,
	RF_s,
	RF_W_en,
	Clk;

	input [3:0] RF_W_addr,
	RF_Ra_addr,
	RF_Rb_addr;

	input [2:0] ALU_s0;
	input [7:0] D_addr;

	output [15:0] ALU_inA, ALU_inB, ALU_out;
	logic [15:0] wire_ALU_inA, wire_ALU_inB, wire_ALU_out;

	// Assign output signals
	assign ALUinA = wire_ALU_inA;
	assign ALU_inB = wire_ALU_inB;
	assign ALU_out = wire_ALU_out;

	logic RAM_out;

	// Instantiate submodules
	DataMemory RAM (	
        .address(D_addr),
	    .clock(Clk),
	    .data(wire_ALU_inA),
	    .wren(D_wr),
	    .q(RAM_out)
    );

	Mux Mux (
		.M(Mux_out), 
		.X(wire_ALU_out), 
		.Y(RAM_out), 
		.S(RF_s)
	); 

	ALU ALU (
		.A(wire_ALU_inA), 
		.B(wire_ALU_inB), 
		.select(ALU_s0), 
		.Q(wire_ALU_out)
	);

	regfile16x16 RegFile (
        .clk(Clk),
        .write(RF_W_en),
        .wrAddr(RF_W_addr),
        .wrData(Mux_out),
        .rdAddrA(RF_Ra_addr),
        .rdDataA(RF_Rb_addr),
        .rdAddrB(wire_ALU_inA),
        .rdDataB(wire_ALU_inB)
    );
endmodule

module Datapath_tb();
	localparam REG_FILE_SIZE = 16;
	localparam RAM_SIZE = 256;
	localparam ClkCycleTime = 20;

	logic D_wr,
	RF_s,
	RF_W_en,
	Clk;

	logic [3:0] RF_W_addr,
	RF_Ra_addr,
	RF_Rb_addr;

	logic [2:0] ALU_s0;
	logic [7:0] D_addr;

	logic [15:0] ALU_inA, ALU_inB, ALU_out;

	logic [15:0] RF_data [7:0];

	// Initialize the clock
    always begin
        Clk = 0; #(ClkCycleTime/2);
        Clk = 1; #(ClkCycleTime/2);
    end

	/*
	 * Task to wait for n cycles
	 * 
	 * n a 32-bit integer of the number of cycles to wait for
	 */
	task automatic WaitCycles(input [31:0] n);
		repeat (n) begin
			@(negedge Clk);
		end
	endtask

	/* Task to reset all the signals to their default values */
	task automatic ResetSignals();
		D_wr = 0;
		RF_s = 0;
		RF_W_en = 0;
		RF_Ra_addr = 0;
		RF_Rb_addr = 0;
		ALU_S0 = 0;
		D_addr = 0;
		ALU_inA = 0;
		ALU_inB = 0;
		ALU_out = 0;
	endtask

	/* Task to reset all registers to random values */
	task automatic ResetRegisters();
		// Populate reg file with random values
		for (int i = 0; i < REG_FILE_SIZE; i++) begin
            wrAddr = i;
			RF_data[i] = $random;
			wrData = RF_data[i];

            WaitCycles(1);
        end
	endtask

	/*
	 * Task to sweep through an ALU operation with the datapath.
	 * 
	 * op is the operation the ALU is doing
	 * 	op = 0 is addition 
	 *  op = 1 is subtraction
	 * 
	 */
	task automatic ALUSweep(input op);
		ResetRegisters();

		for (int i = 0; i < REG_FILE_SIZE; i++) begin
			// Add
			ResetSignals();

			RF_W_addr = (i + 2) % REG_FILE_SIZE;
			RF_W_en = 1;
			RF_Ra_addr = i;
			RF_Rb_addr = (i + 1) % REG_FILE_SIZE;
			ALU_s0 = op + 1;

			// Let signals propagate
			#5;

			logic operand_a = ALU_inA;
			logic operand_b = ALU_inB;

			WaitCycles(1);

			RF_W_en = 0;
			RF_Ra_addr = RF_W_addr;

			// Let signals propagate
			#5;

			assert(op ? operand_a + operand_b == ALU_inA : operand_a - operand_b == ALU_inA)
			else $error("Incorrect subtraction result recieved! Expected %h, got %h.", op ? operand_a + operand_b == ALU_inA : operand_a - operand_b == ALU_inA);
		end
	endtask

	task automatic RAMSweep();
		ResetRegisters();

		for (int i = 0; i < RAM_SIZE; i++) begin
			D_addr = i;
			D_wr = 1;
			RF_Ra_addr = Instruction[11:8];

			WaitCycles(1);
        end
	endtask

	//RF_data

	Datapath DUT(
		Clk,
		D_addr,
		D_wr,
		RF_s,
		RF_W_addr,
		RF_W_en,
		RF_Ra_addr,
		RF_Rb_addr,
		ALU_s0,
		ALU_inA,
		ALU_inB, 
		ALU_out
		);

	initial begin
		// Set up monitor
        $timeformat(-12, 0, "", 5);
		$display("time\tClk\tD_addr\tD_wr\tRF_s\tRF_W_addr\tRF_W_en\tRF_Ra_addr\tRF_Rb_addr\tALU_s0\tALU_inA\tALU_inB\tALU_out");
		$monitor("%t\t%b\t%h\t%b\t%b\t%h\t%b\t%h\t%h\t%h\t%h\t%h\t%h", 
			$time, 
			Clk, 
			D_addr, 
			D_wr, 
			RF_s, 
			RF_W_addr, 
			RF_W_en, 
			RF_Ra_addr, 
			RF_Rb_addr, 
			ALU_s0, 
			ALU_inA, 
			ALU_inB, 
			ALU_out);

		// Test all instructions

		ALUSweep(0); // Test addition
		ALUSweep(1); // Test subtraction

		ResetSignals();


	end
endmodule
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
 * ALU_inA the signal going into the 'A' port of the ALU
 * ALU_inB the signal going into the 'B' port of the ALU
 * ALU_out the signal coming out of the ALU
 *
 */
 `timescale 1ps/1ps
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
	logic [15:0] wire_ALU_inA, wire_ALU_inB, wire_ALU_out, RAM_out, Mux_out;

	// Assign output signals
	assign ALU_inA = wire_ALU_inA;
	assign ALU_inB = wire_ALU_inB;
	assign ALU_out = wire_ALU_out;

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
		.Sel(ALU_s0), 
		.Q(wire_ALU_out)
	);

	regfile16x16 RegFile (
        .clk(Clk),
        .write(RF_W_en),
        .wrAddr(RF_W_addr),
        .wrData(Mux_out),
        .rdAddrA(RF_Ra_addr),
        .rdDataA(wire_ALU_inA),
        .rdAddrB(RF_Rb_addr),
        .rdDataB(wire_ALU_inB)
    );
endmodule

module Datapath_tb();
	// The data that should be in each RAM address
	localparam RAM_DATA = 16'hABCD;

	localparam REG_FILE_SIZE = 16;
	localparam RAM_SIZE = 16;
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

	logic operand_a;
	logic operand_b;

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

		RF_W_addr = 0;
		RF_Ra_addr = 0;
		RF_Rb_addr = 0;

		ALU_s0 = 0;
		D_addr = 0;
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

			operand_a = ALU_inA;
			operand_b = ALU_inA;

			WaitCycles(1);

			RF_W_en = 0;
			RF_Ra_addr = RF_W_addr;

			// Let signals propagate
			#5;

			assert(op ? operand_a + operand_b == ALU_inA : operand_a - operand_b == ALU_inA)
			else $error("Incorrect subtraction result recieved! Expected %h, got %h.", 
			op ? operand_a + operand_b == ALU_inA : operand_a - operand_b == ALU_inA, ALU_inA);
		end
	endtask

	/* Task to test load instruction */
	task automatic Load();
		// Load data from RAM
		for (int i = 0; i < RAM_SIZE; i++) begin
			ResetSignals();

			// LOAD_A
			D_addr = i;
			RF_s = 1;
			RF_W_addr = i % REG_FILE_SIZE;

			WaitCycles(1);

			// LOAD_B
			RF_W_en = 1;
			RF_Ra_addr = i % REG_FILE_SIZE;

			// TODO: Why is it 3 cycles???
			WaitCycles(3);

			assert(ALU_inA == RAM_DATA)
			else $error("Incorrect data loaded back from RAM. Expected %h, got %h.", RAM_DATA, ALU_inA);
        end
	endtask

	/* Test to test store instruction */
	task automatic Store();
		logic [15:0] data [(REG_FILE_SIZE - 1):0];

		// Store data from reg files into RAM
		for (int i = 0; i < RAM_SIZE; i++) begin
			ResetSignals();

			D_addr = i;
			D_wr = 1;
			RF_Ra_addr = i % REG_FILE_SIZE;

			WaitCycles(1);
        end
	endtask

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

		Load(); // Test load
			
		ALUSweep(0); // Test addition
		ALUSweep(1); // Test subtraction

		Store(); // Test save

		$stop();
	end
endmodule
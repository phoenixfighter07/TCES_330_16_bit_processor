/*
 * TCES 330
 * Robert Cromer and Landon Wardle
 * 6/4/2026
 * The programmable processor.
 */

/*
 * A 16-bit programmable processor with 128 words of ROM, and 256 words of RAM.
 * Supports 5 instructions of the general form <operation> <source> <destination>:
 * NOOP: No-operation; 
 *  Instruction: 0000 xxxx xxxx xxxx
 * STORE: Stores a value from a register 4-bit address r into an 8-bit RAM address d; 
 *  Instruction: 0001 rrrr dddddddd
 * LOAD: Loads a value from an 8-bit RAM address d to a register 4-bit address r; 
 *  Instruction: 0010 dddddddd rrrr
 * ADD: Adds the value of register A and the value of register B, stores in register C; 
 *  Instruction: 0011 aaaa bbbb cccc
 * SUBTRACT: Subtracts the value of register A and the value of register B, stores in register C; 
 *  Instruction: 0100 aaaa bbbb cccc
 * HALT: Stops the processor; 
 *  Instruction: 0101 xxxx xxxx xxxx
 *
 * Ports:
 * 
 * Clk the clock signal of the processor 
 * ResetN is the active-low system reset signal
 * IR_Out is the 16-bit content of the instruction register 
 * PC_Out is the 8-bit countent of the program counter
 * State is the 4-bit current state of the FSM that controls the processor
 * NextState is the 4-bit next state of the FSM that controls the processor
 * ALU_A is the 16-bit A-side input to the ALU
 * ALU_B is the 16-bit B-side input to the ALU
 * ALU_Out is the 16-bit output from the ALU
 *
 */
 `timescale 1ps/1ps
module Processor( 
    Clk, 
    ResetN,
    IR_Out, 
    PC_Out, 
    State, 
    NextState, 
    ALU_A,
    ALU_B, 
    ALU_Out);

    input Clk; // processor clock
    input ResetN; // system reset
    output [15:0] IR_Out; // Instruction register
    output [7:0] PC_Out; // Program counter
    output [3:0] State; // FSM current state
    output [3:0] NextState; // FSM next state (or 0 if you don’t use one)
    output [15:0] ALU_A; // ALU A-Side Input
    output [15:0] ALU_B; // ALU B-Side Input
    output [15:0] ALU_Out; // ALU current output

    logic [7:0] D_addr;
    logic D_wr, RF_s, RF_W_en;
    logic [3:0] RF_W_addr, RF_Ra_addr, RF_Rb_addr;
    logic [3:0] ALU_s0;

    Control control (
        .Clk(Clk),
        .D_addr(D_addr),
        .D_wr(D_wr),
        .RF_s(RF_s),
        .RF_W_addr(RF_W_addr),
        .RF_W_en(RF_W_en),
        .RF_Ra_addr(RF_Ra_addr),
        .RF_Rb_addr(RF_Rb_addr),
        .ALU_s0(ALU_s0)
    );

    Datapath datapath (
        .Clk(Clk),
        .D_addr(D_addr),
        .D_wr(D_wr),
        .RF_s(RF_s),
        .RF_W_addr(RF_W_addr),
        .RF_W_en(RF_W_en),
        .RF_Ra_addr(RF_Ra_addr),
        .RF_Rb_addr(RF_Rb_addr),
        .ALU_s0(ALU_s0),
        .ALU_inA(ALU_A),
        .ALU_inB(ALU_B), 
        .ALU_out(ALU_Out)
	);
endmodule
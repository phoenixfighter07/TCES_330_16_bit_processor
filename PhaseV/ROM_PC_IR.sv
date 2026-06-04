// Robert Cromer and Landon Wardle
// TCES 330 Spring 2026
// CLass Project
// This file tests the PC register, IR reguster, and the ROM working together. 
// In other words, the full control side is tested without the control unit. 
// The idea is to test 

/**
    Clk: The clock
    LD: The signal that tells the instruction register to update
    UP: Increments the PC
    ClrN: clears the PC
*/
module ROM_PC_IR(Clk, LD, IR_OUT, UP, Clr);
    input Clk, LD, UP, Clr;
    output [15:0] IR_OUT;
    logic [15:0] IR_IN;
    logic [6:0] PC_addr;

    // PC(Up, Clk, Clr, Q)
    PC programCounter(UP, Clk, Clr, PC_addr);

    // InstMemory (address,	clock, q);
    InstMemory ROM(PC_addr, Clk, IR_IN);

    // IR(Clk, Ld, DataIn, DataOut)
    IR instructionRegister(Clk, LD, IR_IN, IR_OUT);
endmodule






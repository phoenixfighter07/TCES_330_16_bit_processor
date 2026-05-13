/* 
 * Robert Cromer and Landon Wardle
 * Spring 2026
 * TCES 330
 *
 * This file combines the ALU and the register file and 
 * combines the two for preliminary testing.
*/



/* The testbench for the regALU module *//*
 * The module to test the ALU and register file together.
 * Note: All these definitions assume the paramater bits is equal to 16.
 * 
 * RF_W_addr: The 4-bit address the register file writes the ALU output to.
 * RF_W_en: 1-bit Enable signal for writing to RF_W_addr.
 * RF_Ra_addr: 4-bit address of the register A to read from.
 * RF_Rb_addr: 4-bit address of the register B to read from.
 * ALU_s0: 3-bit ALU operation signal.
 * Q: The 16-bit output signal for the ALU.
 * Clk: The clock signal for the Register File.
*/
module regALU(RF_W_addr, RF_W_en, RF_Ra_addr, RF_Rb_addr, ALU_s0, Q, Clk);
    parameter bits = 16;
    localparam logN = $clog2(bits);

    // Define inputs and outputs.
    input [(logN-1):0] RF_W_addr, RF_Ra_addr, RF_Rb_addr;
    input RF_W_en, Clk;
    input [2:0] ALU_s0;
    output [(bits-1):0] Q;
    
    logic [(bits-1):0] ALU_OUT;
    
    assign Q = ALU_OUT;

    regfile16x16 #(.bits(bits)) DUT (
        Clk,
        RF_W_en,
        RF_W_addr,
        ALU_OUT,
        RF_Ra_addr,
        rdDataA,
        RF_Rb_addr,
        rdDataB
    );

    ALU #(.bits(bits)) ALUunit (rdDataA, rdDataB, ALU_s0, ALU_OUT);
endmodule
module regALU_tb();
    localparam clkCycleTime = 10;
    logic Clk;

    // Initialize the clock
    always begin
        Clk = 0; #(clkCycleTime/2);
        Clk = 1; #(clkCycleTime/2);
    end
endmodule
    
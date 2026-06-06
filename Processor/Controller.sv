// Robert Cromer and Landon Wardle
// TCES 330
// Project Phase V
// This file tests the full control side of the processor. 

/**
    Clk: The clock
    ResetN: An active-low reset signal
    D_addr: The memory adress that is being read from  
    RF_s: Determines whether the register file write data comes from the ALU(0) or the Memory(1)
    RF_W_addr: the register file address being written to 
    RF_W_en: when equal to 1, it lets the register file be written to
    RF_Ra_Addr: The register address which data is read from to the RA_data
                port on the register file
    RF_Rb_Addr: The register address which data is read from to the RB_data port on the register
                file
    ALU_s0: The mode that the ALU is in
*/
module Controller(  Clk, 
                    ResetN, 
                    D_addr, 
                    D_wr,
                    RF_s, 
                    RF_W_addr, 
                    RF_W_en,
                    RF_Ra_Addr, 
                    RF_Rb_Addr, 
                    ALU_s0, 
                    State, 
                    NextState, 
                    IR_OUT);
    input Clk, ResetN;
    output RF_W_en, D_wr, RF_s;
    output [2:0] ALU_s0;
    output [3:0] RF_W_addr, RF_Ra_Addr, RF_Rb_Addr, State, NextState;
    output [7:0] D_addr;
    output [15:0] IR_OUT;
    logic LD, UP, Clr; 

    // ROM_PC_IR(Clk, LD, IR_OUT, UP, Clr);
    ROM_PC_IR instruction(.Clk(Clk), .LD(LD), .UP(UP), .Clr(Clr), .IR_OUT(IR_OUT));

    // FSM(Clk, ResetN, Instruction, PC_clr, PC_up, IR_ld, D_addr, D_wr, RF_s, RF_Ra_Addr, 
                // RF_Rb_Addr, RF_W_en, RF_W_addr, ALU_s0)
    FSM control(
        .Clk(Clk), 
        .Instruction(IR_OUT),
        .ResetN(ResetN),
        .PC_clr(Clr),
        .PC_up(UP),
        .IR_ld(LD),
        .D_addr(D_addr), 
        .D_wr(D_wr), 
        .RF_s(RF_s), 
        .RF_W_en(RF_W_en),
        .RF_W_addr(RF_W_addr), 
        .RF_Ra_Addr(RF_Ra_Addr),
        .RF_Rb_Addr(RF_Rb_Addr),
        .ALU_s0(ALU_s0), 
        .CurrentState(State), 
        .NextState(NextState));
endmodule

`ifdef MODEL_TECH
/**
    This module tests the controller unit. Since the ROM_PC_IR unit was already tested, the purpose
    of the testbench is to see whether the FSM communicates properly with al of the other 
    control units. 
*/
module Controller_tb();
    logic Clk, ResetN;
    logic [7:0] D_addr;
    logic [3:0] RF_W_addr, RF_Ra_Addr, RF_Rb_Addr, State, NextState;
    logic [2:0] ALU_s0;
    logic RF_W_en, D_wr;
    logic [16:0] IR_OUT;

    Controller DUT (
        Clk, 
        ResetN, 
        D_addr, 
        D_wr,
        RF_s, 
        RF_W_addr, 
        RF_W_en,
        RF_Ra_Addr, 
        RF_Rb_Addr, 
        ALU_s0, 
        State, 
        NextState, 
        IR_OUT);

    // always begin
    //     Clk = 1; #(clkTime / 2);
    //     Clk = 0; #(clkTime / 2);
    // end

    // initial begin   
    //     ResetN = 0;


    // end

    // task automatic waitCycles(input cycles)
endmodule
`endif
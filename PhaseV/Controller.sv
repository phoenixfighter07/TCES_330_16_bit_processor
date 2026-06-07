// Robert Cromer and Landon Wardle
// TCES 330
// Project Phase V
// This file tests the full control side of the processor. 

`timescale 1ps/1ps


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
                    IR_OUT, 
                    PC_OUT);
    input Clk, ResetN;
    output RF_W_en, D_wr, RF_s;
    output [2:0] ALU_s0;
    output [3:0] RF_W_addr, RF_Ra_Addr, RF_Rb_Addr, State, NextState;
    output [6:0] PC_OUT;
    output [7:0] D_addr;
    output [15:0] IR_OUT;
    logic LD, UP, Clr; 

    // state variable
    localparam	Init = 0, 
                Fetch = 1,
                Decode = 2,
                NOOP = 3,
                LOAD_A = 4,
                STORE = 5, 
                ADD = 6,
                HALT = 7,
                SUB = 8,
                LOAD_B = 9;
    // ROM_PC_IR(Clk, LD, IR_OUT, UP, Clr);
    ROM_PC_IR instruction(.Clk(Clk), .LD(LD), .UP(UP), .Clr(Clr), .IR_OUT(IR_OUT), .PC_OUT(PC_OUT));

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
        .CurrentState_out(State), 
        .NextState_out(NextState));
endmodule

`ifdef MODEL_TECH
/**
    This module tests the controller unit. Since the ROM_PC_IR unit was already tested, the purpose
    of the testbench is to see whether the FSM communicates properly with all of the other 
    control units. For example, This testbench is also supposed to be used with actual instruction sets in the rom such as 
    the one in the ROM_instruction.mif file.
*/
module Controller_tb();
    logic Clk, ResetN;
    logic RF_W_en, D_wr;
    logic [2:0] ALU_s0;
    logic [3:0] RF_W_addr, RF_Ra_Addr, RF_Rb_Addr, State, NextState;
    logic [6:0] PC_OUT, fetchCounter;
    logic [7:0] D_addr;
    logic [15:0] IR_OUT, IR_Tracker; 
    localparam clkTime = 20;


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
        IR_OUT,
        PC_OUT);

    always begin
        Clk = 1; #(clkTime / 2);
        Clk = 0; #(clkTime / 2);
    end

    initial begin   
        ResetN = 0; fetchCounter = 0;
        #clkTime;
        @(negedge Clk);
        testReset();
        ResetN = 1;

        // tests to see that PC and IR 
        while (State != DUT.HALT) begin
            @ (negedge Clk);
            testPC_OUT();
            testIR();
        end

        // Checks if reset works 
        ResetN = 0;
        waitCycles(2);
        testReset();
        ResetN = 1;
        // Checks if reset works in a random cycle
        waitCycles(10);
        ResetN = 0;
        waitCycles(2);
        testReset();
        $stop;
    end

    /** Waits for a certain number of clock cycles */
    task automatic waitCycles(input int cycles);
        repeat(cycles) begin
            @(negedge Clk);
        end
    endtask

    /** Tests the reset signal */
    task automatic testReset();
        IR_Tracker = 0;
        assert(State == DUT.Init)
        else $error("Problem with reset signal. Expected: Init; Actual: %s", getState(State));
        assert(IR_OUT == 0)
        else $error("Problem resetting the IR. Should be 0. Is %h", IR_OUT);
    endtask

    /** Tests the PC counter to see if it is incrementing at the correct time. */
    task automatic testPC_OUT();
        if (State == DUT.Decode) begin
            fetchCounter = fetchCounter + 1;
        end
        
        assert(PC_OUT == fetchCounter)
        else $error("PC_OUT not updating correctly. Expected %d, read %d", fetchCounter, PC_OUT);
    endtask

    task automatic testIR();
        if (State == DUT.Decode) begin
            IR_Tracker = IR_OUT;
        end

        assert(IR_OUT == IR_Tracker)
        else $error("IR ERROR. Expected %h. Recieved %h.", IR_Tracker, IR_OUT);
    endtask

    function string getState(input int state);
        case (state) 
            0: begin getState = "Init"; end
            1: begin getState = "Fetch"; end
            2: begin getState = "Decode"; end
            3: begin getState = "NOOP"; end
            4: begin getState = "LOAD"; end
            5: begin getState = "Store"; end
            6: begin getState = "ADD"; end
            7: begin getState = "HALT"; end
            8: begin getState = "SUB"; end
            9: begin getState = "LOAD_B"; end
        endcase
    endfunction

endmodule
`endif
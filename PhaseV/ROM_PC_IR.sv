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

/**
    This testbench tests to see if the connections between the non-controlFSM parts of the control
    section of the processor communicate with each other. It is already assumed that the modules 
    inside the ROM_PC_IR module have been tested and work. 
*/
module ROM_PC_IR_tb();
    logic Clk, LD, IR_OUT, UP, Clr;
    localparam clkTime = 20;

    ROM_PC_IR DUT(Clk, LD, IR_OUT, UP, Clr);

    always begin
        Clk = 0; #(clkTime/2);
        Clk = 1; #(clkTime/2);
    end

    initial begin
        Clr = 1; LD = 1; UP = 1; 
        waitCycles(1);
        assertClear();

        // Tests if value loads from ROM to IR to Output
        for(int i = 0; i < 256; i++) begin
            waitCycles(2); // 1 cycle to update teh PC, another to update the 
            assertIR();
            assert(DUT.IR_IN == i)
            else ("Error with ROM connection. Expected ROM output to be %d. Recieved %d", i, DUT.IR_IN);
        end
    end

    // waits for a number fo cycles
    task automatic waitCycles(input cycles);
        repeat (cycles) begin
            @(negedge Clk);
        end 
    endtask

    // Checks if the clear signal works. It is implied that the clear signal was already running for a 
    // few cycles. 
    task automatic assertClear();
        assert(ROM_PC_IR.PC_addr == 0)
        else $error("Problem clearing PC Counter. Expected 0, got %d", IR_OUT)
    endtask

    task automatic assertIR();
        assert(IR_OUT == DUT.IR_IN)
        else $error("Problem with IR. IR_IN: %d. IR_OUT: %d", DUT.IR_IN, IR_OUT);
    endtask

endmodule
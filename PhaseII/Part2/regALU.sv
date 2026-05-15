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
    
    logic [(bits-1):0] ALU_OUT, rdDataA, rdDataB;
    
    assign Q = ALU_OUT;

    regfile16x16 #(.bits(bits)) Registers (
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
    localparam bits = 16;
    logic Clk;
    logic RF_W_en;
    logic [3:0] RF_W_addr, RF_Ra_addr, RF_Rb_addr;
    logic [2:0] ALU_s0;
    logic [bits - 1:0] Q;
    
    regALU #(.bits(bits)) DUT (RF_W_addr, RF_W_en, RF_Ra_addr, RF_Rb_addr, ALU_s0, Q, Clk);
    // Initialize the clock
    always begin
        Clk = 0; #(clkCycleTime/2);
        Clk = 1; #(clkCycleTime/2);
    end

    initial begin
        // put data in registers. 16 is used as the upper cap becasue is it the number of registers in the register file.
        RF_W_en = 1; 
        ALU_s0 = 0; // writes 0 to every register 
        RF_Ra_addr = 0; RF_Rb_addr = 0; // assigned so hat they have a value
        #1;
        for (int i = 0; i < 16; i++) begin
            RF_W_addr = i;
            #clkCycleTime;
            assert((DUT.Registers.regfile[i]) == (Q)) 
            else $error("Error with writing 0 to register %g. Register value is %g. \t MATRIX: %m", Q, DUT.Registers.regfile[i]);
        end

        // Checks if write can be turned off while incrementing
        // Assumes that all registers equal 1 because of the previous for loop
        RF_W_en = 0;
        ALU_s0 = 7; // Is set to increment for the next few variables
        for (int j = 0; j < 16; j++) begin
            RF_Ra_addr = j;
            RF_W_addr = j;
            #clkCycleTime;
            assert(DUT.Registers.regfile[j] == 0) 
            else $error("Register write enable not working for register %g. Expected value is 0. Actual value is %g", j, DUT.Registers.regfile[j]);
        end

        // checks if increment works
        RF_W_en = 1;
        for (int i = 1; i <= 2; i++) begin
            for (int j = 0; j < 16; j++) begin
                RF_Ra_addr = j;
                RF_W_addr = j;
                #clkCycleTime;
                assert(DUT.Registers.regfile[j] == i) 
                else $error("Increment error. Register %d should equal %d. Actual value: %d", j, i, DUT.Registers.regfile[j]);
            end
        end


        // Checks if addition works and if data can effectively be read from both registers
        // increment loop so each register has a unique value
        // ALU still in increment mode
        for (int i = 0; i < 16; i++) begin
            for (int j = 0; j < i; j++) begin
                RF_Ra_addr = i;
                RF_W_addr = i;
                #clkCycleTime;
            end
        end

        // checks addition and subtraction
        RF_W_addr = 0; // turns off writeback. We will be testing Q for the next few values
        for (int i = 1; i <= 2; i++) begin
            ALU_s0 = i;
            for (int j = 0; j < 16; j++) begin
                RF_Ra_addr = j;
                for (int k = 0; k < 16; k++) begin
                    RF_Rb_addr = k;
                    #clkCycleTime;
                    if (i == 1) begin
                        assert(Q == DUT.Registers.regfile[k] + DUT.Registers.regfile[j])
                        else $error("Addition error. A register #: %d; B register #: %d; Expected Q: %d; Actual Q: %d", 
                            j, k, (DUT.Registers.regfile[k] + DUT.Registers.regfile[j]), Q);
                    end else begin
                        assert(Q == DUT.Registers.regfile[j] - DUT.Registers.regfile[k])
                        else $error(" Subtraction error. A register #: %d; B register #: %d; Expected Q: %d; Actual Q: %d", 
                            j, k, (DUT.Registers.regfile[j] - DUT.Registers.regfile[k]), Q);
                    end
                end
            end
        end

        // checks pass-through
        ALU_s0 =  3;
        for(int i = 0; i < 16; i++) begin
            RF_Ra_addr = i;
            #clkCycleTime;
            assert(Q == DUT.Registers.regfile[i])
            else $error("Pass-through not working for register %d. Expected: %d; Actual: %d", i, DUT.Registers.regfile[i], Q);
        end

        // checks bitwise operators
        for (int i = 4; i <=6; i++) begin
            ALU_s0 = i;
            for (int j = 0; j < 16; j++) begin
                RF_Ra_addr = j;
                for (int k = 0; k < 16; k++) begin
                    RF_Rb_addr = k;
                    #clkCycleTime;
                    if (i == 4) begin // XOR
                        assert(Q == (DUT.Registers.regfile[j] ^ DUT.Registers.regfile[k]))
                        else $error("Problem with bitwise XOR of registers %d and %d. Register values were %b and %b. Expected: %b; Actual: %b",
                            j, k, DUT.Registers.regfile[j], DUT.Registers.regfile[k], DUT.Registers.regfile[j] ^ DUT.Registers.regfile[k], Q);
                    end else if (i == 5) begin // OR
                        assert(Q == (DUT.Registers.regfile[j] | DUT.Registers.regfile[k]))
                        else $error("Problem with bitwise OR of registers %d and %d. Register values were %b and %b. Expected: %b; Actual: %b",
                            j, k, DUT.Registers.regfile[j], DUT.Registers.regfile[k], DUT.Registers.regfile[j] | DUT.Registers.regfile[k], Q);
                    end else begin
                        assert(Q == (DUT.Registers.regfile[j] & DUT.Registers.regfile[k]))
                        else $error("Problem with bitwise AND of registers %d and %d. Register values were %b and %b. Expected: %b; Actual: %b",
                            j, k, DUT.Registers.regfile[j], DUT.Registers.regfile[k], DUT.Registers.regfile[j] & DUT.Registers.regfile[k], Q);
                    end
                end
            end
        end
        $stop;
    end
endmodule
    
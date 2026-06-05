/* 
 * Robert Cromer and Landon Wardle
 * Spring 2026
 * TCES 330
 *
 * This file contains the regfile16x16 module and its testbench. 
 * The default bit size that it will be programmed in is 16, but a parameter is included so that
 * the module can be tested qwith less bits. 
*/

/*
 * The module for the regfile16x16 that is used in the processor.
 *
 * clk: the system clock.
 * write: the write enable signal.
 * wrAddr: the address of the register to write to.
 * wrData: the data being written.
 * rdAddrA: A-side read address.
 * rdDataA: A-side read data.
 * rdAddrB: B-side read address.
 * rdDataB: B-sdie read data.
*/
module regfile16x16
    (clk,
    write,
    wrAddr,
    wrData,
    rdAddrA,
    rdDataA,
    rdAddrB,
    rdDataB );

    // used to make testing easier, specifies the bit sizes of the inputs and output.
    parameter bits = 16;
    localparam logBits = $clog2(bits);

    // Store to reduce duplicated code.
    localparam maxBits = bits - 1;
    localparam maxLogBits = logBits -1;

    // Define inputs.
    input clk;
    input write;
    input [maxLogBits:0] wrAddr;
    input [maxBits:0] wrData;
    input [maxLogBits:0] rdAddrA;
    output [maxBits:0] rdDataA;
    input [maxLogBits:0] rdAddrB;
    output [maxBits:0] rdDataB;

    // Define registers in an array of vectors.
    logic [maxBits:0] regfile [maxBits:0];

    assign rdDataA = regfile[rdAddrA];
    assign rdDataB = regfile[rdAddrB];

    always_ff @( negedge clk ) begin
        if (write) begin
            regfile[wrAddr] <= wrData;
        end
    end
endmodule

/* The testbench for the regfile16x16 module */
module regfile16x16_tb();
    localparam clkCycleTime = 10;
    localparam testBits = 16;

    localparam logBits = $clog2(testBits);

    // Store to reduce duplicated code.
    localparam maxBits = testBits - 1;
    localparam maxLogBits = logBits -1;

    // Define inputs.
    logic clk;
    logic write;
    logic [maxLogBits:0] wrAddr;
    logic [maxBits:0] wrData;
    logic [maxLogBits:0] rdAddrA;
    logic [maxBits:0] rdDataA;
    logic [maxLogBits:0] rdAddrB;
    logic [maxBits:0] rdDataB;

    regfile16x16 #(.bits(testBits)) DUT (
        clk,
        write,
        wrAddr,
        wrData,
        rdAddrA,
        rdDataA,
        rdAddrB,
        rdDataB
    );

    // Initialize the clock
    always begin
        clk = 0; #(clkCycleTime/2);
        clk = 1; #(clkCycleTime/2);
    end
    
    initial begin
        write = 0;
        wrAddr = 0;
        wrData = 0;
        rdAddrA = 0;
        rdDataA = 0;
        rdAddrB = 0;
        rdDataB = 0;

        // Offset from clock
        #1;

        // Start by writing data to each register:
        write = 1;

        for (int i = 0; i < testBits; i++) begin
            wrAddr = i;
            wrData = $random;

            #(clkCycleTime);
        end

        write = 0;

        // Test that each register can be read from on A port:
        for (int i = 0; i < testBits; i++) begin 
            rdAddrA = i;

            #(clkCycleTime/2);

            assert(rdDataA == DUT.regfile[rdAddrA]) 
            else 
            $error("Data from register %d at data A incorrect! Expected %h, got %h.", i, DUT.regfile[rdAddrA], rdDataA);
        end

        // Test that each register can be read from on B port:
        for (int i = 0; i < testBits; i++) begin 
            rdAddrB = i;

            #(clkCycleTime/2);

            assert(rdDataB == DUT.regfile[rdAddrB]) 
            else 
            $error("Data from register %d at data B incorrect! Expected %h, got %h.", i, DUT.regfile[rdAddrB], rdDataB);
        end

        // Test that both ports read the same
        for (int i = 0; i < testBits; i++) begin 
            rdAddrA = i;
            rdAddrB = i;

            #(clkCycleTime/2);

            assert(DUT.regfile[rdAddrA] == DUT.regfile[rdAddrB]) 
            else 
            $error("Data A and Data B are incorrect! Expected Data A (%h) to be equal to Data B(%h).", i, DUT.regfile[rdAddrA], DUT.regfile[rdAddrB]);
        end

        #100;

        $stop;
    end
endmodule
    
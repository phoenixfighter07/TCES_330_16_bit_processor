/*
 * TCES 330
 * Robert Cromer and Landon Wardle
 * 6/1/2026
 * Testbench for the RAM generated in Quartus.
 */ 

/*
 * 16-bit 256 word RAM generated using Quartus.
 *
 * Note: All inputs are latched for one cycle before being written.
 *
 * address is the 8-bit location in memory being either written to or read
 * clock is the clock signal to the RAM
 * data is the input to write to address
 * q is the 16-bit value at address
 * wren is the write enable signal
 */

 /*
 * NOTE: The asserts in this testbench WILL fail unless the 
 * .mif file matches the contents of the data array.
 * NOTE: When testing modify the DataMemory.v file to read from RAM_test.mif 
 * instead of RAM_processor.mif!
 */  

 `timescale 1ps / 1ps
module DataMemory_tb();
    localparam TEST_DATA = 16'h6767;

    localparam ClkCycleTime = 20;

    logic
	clock,
	wren;

    logic [7:0] address;
    logic [15:0] data, q;

    logic [15:0] randData [255:0];

    // Initialize the clock
    always begin
        clock = 0; #(ClkCycleTime/2);
        clock = 1; #(ClkCycleTime/2);
    end

    DataMemory DUT (	
        address,
	    clock,
	    data,
	    wren,
	    q
    );

    // Wait n clock cycles
	task automatic WaitCycles(input [31:0] n);
		repeat (n) begin
			@(negedge clock);
		end
	endtask

    initial begin
        // Set up monitor
        $timeformat(-12, 0, "", 5);
		$display("time\taddr\tclk\tdata\twren\tq");
		$monitor("%t\t%h\t%b\t%h\t%b\t%h", $time, address, clock, data, wren, q);

        // Wait a few cycles
        WaitCycles(4);

        // Write 6767 to address 0A
        address = 8'h0A;
        data = TEST_DATA;
        wren = 1;

        WaitCycles(2);

        wren = 0;
        assert(q == TEST_DATA) 
        else $error("Data at address %h is incorrect. Expected %h got %h.", address, TEST_DATA, q);

        WaitCycles(1);

        // Write to 0 to 128 addresses
        wren = 1;
        for (int i = 0; i < 128; i++) begin
            address = i;
            data = 16'h0000;
            WaitCycles(1);
        end

        WaitCycles(1);

        // Write random data to the same 128 addresses

        wren = 1;
        for (int i = 0; i < 128; i++) begin
            address = i;
            data = $random;
            randData[i] = data;
            WaitCycles(1);
        end

        WaitCycles(1);

        // Read random data from the same 128 addresses
        wren = 0;
        for (int i = 0; i < 128; i++) begin
            for (int j = 0; j < 4; j++) begin
                address = i;
                WaitCycles(1);
                assert(q == randData[i]) 
                else $error("Data at address %h is incorrect. Expected %h got %h.", address, randData[i], q); 
            end
        end

        $stop;
    end
endmodule


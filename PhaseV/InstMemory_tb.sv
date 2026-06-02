/*
 * TCES 330
 * Robert Cromer and Landon Wardle
 * 6/2/2026
 * Testbench for the ROM generated in Quartus.
 */ 

/*
 * 16-bit 128 word ROM generated using Quartus.
 *
 * Note: All inputs are latched for one cycle before being written.
 *
 * address is the 8-bit location in memory being either written to or read
 * clock is the clock signal to the RAM
 * q is the 16-bit value at address
 */

/*
 * NOTE: The asserts in this testbench WILL fail unless the 
 * .mif file matches the contents of the data array.
 */  

 `timescale 1ps / 1ps
module InstMemory_tb();
    localparam ClkCycleTime = 20;

    logic clock;

    logic [7:0] address;
    logic [15:0] q;

    // Write in the data for the first 16 entries to check against.
    logic [15:0] data [15:0];

    initial begin
        data = '{default: 16'hABCD};
    end

    // Initialize the clock
    always begin
        clock = 0; #(ClkCycleTime/2);
        clock = 1; #(ClkCycleTime/2);
    end

    InstMemory DUT (	
        address,
	    clock,
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
		$display("time\taddr\tclk\tq");
		$monitor("%t\t%h\t%b\t%h", $time, address, clock, q);

        // Wait a few cycles
        WaitCycles(2);

        // Read data from 16 addresses
        for (int i = 0; i < 16; i++) begin
            for (int j = 0; j < 4; j++) begin
                address = i;
                WaitCycles(1);
                assert(q == data[i]) 
                else $error("Data at address %h is incorrect. Expected %h got %h.", address, data[i], q); 
            end
        end

        $stop;
    end
endmodule


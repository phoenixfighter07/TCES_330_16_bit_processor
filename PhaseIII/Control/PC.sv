/*
 * TCES 330
 * Landon Wardle
 * 5/27/2026
 * 16-Bit Processor Project Phase III
 */ 

/*
 * A 7-bit program counter.
 *
 * Clk is the clock signal board's clock signal
 * Up is the enable signal for the counter
 * Clr is a high-driven clear signal
 * Q is the value of the progam counter
 */
module PC(Up, Clk, Clr, Q);
    parameter n = 7; // 128 words maximum  
    localparam maxValue = (2 ** n) - 1;

    input Clr, Clk, Up;
    output logic [n-1:0] Q;

    // Asynchronous reset
    always_ff @( posedge Clk, negedge Clr ) begin
        if (!Clr || (Up && Q >= maxValue)) begin
            // Sizecast the binary 0 to be the size of the parameter n
            Q <= (n)'(1'b0);
        end else if (Up && Q < maxValue) begin
            Q <= Q + 1'b1;
        end
    end
endmodule

/*
 * Testbench for the above module. 
 * Runs a predetermined waveform to drive 
 * the output to test the decoder.
*/
module PC_tb();
    // number of bits to test
    localparam test_bits = 4;
    localparam string ASSERT_MESSAGE = "Incorrect output in sequence! Expected Q = %6b, got Q = %6b.";

    logic Clr, Clk, Up;
    logic [test_bits - 1:0] Q;

    localparam ClkCycleTime = 10;

    // Initialize the clock
    always begin
        Clk = 0; #(ClkCycleTime/2);
        Clk = 1; #(ClkCycleTime/2);
    end

    PC #(.n(test_bits)) DUT (Up, Clk, Clr, Q);

    initial begin
        // Set up monitor
        $timeformat(-12, 0, "", 5);
		$display("time\tClk\tE\tResetN\tQ");
		$monitor("%t\t%b\t%b\t%b\t%d", $time, Clk, Up, Clr, Q);
        // Reset high
        Up = 0;
        Clr = 0; 

        #(ClkCycleTime + 1);

        // Enable the counter
        Up = 1; 
        Clr = 1; 

        // Let counter count up, check each value
        for (int i = 0; i < 2 ** test_bits; i++) begin
            assert(Q == i) else $error(ASSERT_MESSAGE, i, Q); 
            #(ClkCycleTime);
        end

        // Reset counter again
        Up = 0;
        Clr = 0; 

        #(ClkCycleTime * 2);

        // Enable the counter
        Up = 1; 
        Clr = 1; 

        // Let counter count up halfway
        for (int i = 0; i < 2 ** (test_bits - 1); i++) begin
            assert(Q == i) else $error(ASSERT_MESSAGE, i, Q); 
            #(ClkCycleTime);
        end

        // Disable counter
        Up = 0;

        // Hold for 10 cycles
        #(ClkCycleTime * 10);

        assert(Q == 2 ** (test_bits - 1))
        else 
        $error("Counter did not hold half value! Expected Q = %6b, got Q = %6b.", 2 ** (test_bits), Q);

        // Reset counter again
        Up = 0;
        Clr = 0; 

        #(ClkCycleTime * 2);

        Up = 1;
        Clr = 1;

        // Let counter count up fully, then hold
        for (int i = 0; i < 2 ** (test_bits) - 1; i++) begin
            assert(Q == i) else $error(ASSERT_MESSAGE, i, Q); 
            #(ClkCycleTime);
        end

        // Disable counter
        Up = 0;

        // Hold for 10 cycles
        #(ClkCycleTime * 10);

        assert(Q == 2 ** (test_bits) - 1)
        else 
        $error("Counter did not hold max value! Expected Q = %6b, got Q = %6b.", 2 ** (test_bits) - 1, Q);

        $stop;
    end
endmodule


/*
 * TCES 330
 * Robert Cromer and Landon Wardle
 * 5/28/2026
 * 16-Bit Processor Project Phase V
 */ 

/*
 * A 16-bit instruction register module.
 *
 * Clk is the clock signal board's clock signal
 * Clr is a high-driven reset signal
 * Ld is the enable signal to load DataIn
 * DataIn is the data being fed in to the IR
 * DataOut is the data coming out of the IR
 */
module IR(Clk, Ld, DataIn, DataOut, Clr);
    input Clk, Ld, Clr;
    input [15:0] DataIn;
    output logic [15:0] DataOut;

    always_ff @( posedge Clk ) begin
        if (Clr) begin
            DataOut <= 16'h0000;
        end else begin
            if (Ld) begin
                DataOut <= DataIn;
            end else begin
                DataOut <= DataOut;
            end
        end
    end
endmodule

/* Testbench for the above module. */
module IR_tb();
    logic Clk, Ld, Clr;
    logic [15:0] DataIn, DataOut;

    // number of bits to test
    localparam string ASSERT_MESSAGE = "Expected DataOut = %h, got DataOut = %h.";

    localparam TEST_VALUE = 16'h5231;
    localparam HOLD_CYCLES = 5;

    localparam ClkCycleTime = 10;

    // Initialize the clock
    always begin
        Clk = 0; #(ClkCycleTime/2);
        Clk = 1; #(ClkCycleTime/2);
    end

    IR DUT (.Clk(Clk), .Ld(Ld), .DataIn(DataIn), .DataOut(DataOut), .Clr(Clr));

    initial begin
        // Set up monitor
        $timeformat(-12, 0, "", 5);
		$display("time\tClk\tLd\tDataIn\tDataOut");
		$monitor("%t\t%b\t%b\t%h\t%h", $time, Clk, Ld, DataIn, DataOut);

        // Reset IR
        Ld = 1;
        DataIn = 16'h0;

        @(negedge Clk);

        assert(DataOut == 16'h0) else $error({"IR did not reset! ", ASSERT_MESSAGE}, DataOut, 1'b0);

        Ld = 1;
        DataIn = TEST_VALUE;

        @(negedge Clk);

        assert(DataOut == TEST_VALUE) else $error({"IR did not take on new value! ", ASSERT_MESSAGE}, TEST_VALUE, DataOut);

        Ld = 0;

        repeat(HOLD_CYCLES) begin
            @(negedge Clk);
        end

        assert(DataOut == TEST_VALUE) else $error({"IR did not hold current value! ", ASSERT_MESSAGE}, TEST_VALUE, DataOut);

        Clr = 1;

        @(posedge Clk);
        #2;

        assert(DataOut == 16'h0000) else $error({"IR did not reset its contents! ", ASSERT_MESSAGE}, 1'b0, DataOut);

        $stop;
    end
endmodule


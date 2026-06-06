// Robert Cromer
// Spring 2026
// TCES 330
// This file contains the code for the Decoder.sv module

module Decoder (Hex, V);
    input [3:0] V;
    output logic [0:6] Hex;
    
    always @(V) begin
        case (V)
            0: Hex = 7'b0000001;
            1: Hex = 7'b1001111;
            2: Hex = 7'b0010010;
            3: Hex = 7'b0000110;
            4: Hex = 7'b1001100;
            5: Hex = 7'b0100100;
            6: Hex = 7'b0100000;
            7: Hex = 7'b0001111;
            8: Hex = 7'b0000000;
            9: Hex = 7'b0000100;
            10: Hex = 7'b0001000;
            11: Hex = 7'b1100000;
            12: Hex = 7'b0110001;
            13: Hex = 7'b1000010;
            14: Hex = 7'b0110000;
            15: Hex = 7'b0111000;
            // default not needed since all cases defined
        endcase
    end
endmodule

module Decoder_tb ();
    logic [3:0] V;
    logic [0:6] Hex;

    Decoder DUT(Hex, V);

    initial begin
        $display("%s\t%s", "V", "7-segment output");

        for(int i = 0; i < 16; i++) begin
            V = i[3:0];
            #0;
            $display("%d\t%b", V, Hex);
            #10;
        end
    end
endmodule


    

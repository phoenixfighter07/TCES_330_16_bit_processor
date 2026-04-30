// Robert Cromer and Landon Wardle
// Spring 2026
// TCES 330
// This file contains the ALU module and testbench for the 16-bit processor. 
// The default bit size that it will be programmed in is 16, but a parameter is included so that
// the module can be tested qwith less bits. 



// The module for te ALU that is used in the processor
module ALU (A, B, Sel, Q);
    parameter bits = 16; // used to make testing easier, specifies the bit sizes of the inputs and output
    input [bits - 1:0] A, B;
    input [2:0] Sel;
    output logic [bits - 1:0] Q;


    always_comb begin
        case(Sel) 
            0: Q = 0; // zeroes
            1: Q = A + B; // adition
            2: Q = A - B; // subtraction
            3: Q = A; // A pass-through
            4: Q = A ^ B; // bitwise XOR
            5: Q = A | B; // bitwise OR
            6: Q = A & B; // bitwise AND
            7: Q = A + 1; // increment
        endcase
    end
endmodule


// The testbench for the ALU module
module ALU_tb();
    localparam test_bits = 4;
    logic  [test_bits - 1: 0] A, B, Q;
    logic [2:0] select;

    ALU DUT .bits(test_bits) (A, B, select, Q)
    
    initial begin
        for (int i = 0; i < 2 ** (test_bits * 2 + 3); i++) begin
            {select, A, B} = i;
            assert((select == 0 && Q == 0) || (select == 1 && Q == A + B) ||
                (select == 2 && Q == A - B) || (select == 3 && Q == A) ||
                (select == 4 || Q == A ^ B) || (select == 5 && Q == A | B) ||
                (select == 6 && Q == A & B) || (select == 7 && Q == A + 1))
            else $error("Problem with computation. select: %d; A: %d; B: %d; Q: %d;", select, A, B, Q);
        end
    end
endmodule
    
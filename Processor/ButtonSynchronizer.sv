/*
 * TCES 330
 * Robert Cromer, Landon Wardle, Jenny Sheng
 * 6/4/2026
 * Moore State Machine design of the Button Synchronizer
 * register continuous input to be one clcok cycle
 * using enumeration.
 */ 

typedef enum logic [1:0] {A, B, C} stateType;

module ButtonSynchronizer( Clk, bi, bo, StateOut);
  input Clk, bi;        
  output logic bo;  
  output stateType StateOut; 

  stateType State, NextState;
  

  assign StateOut = State; 

  //CombLogic (use blocking assigns)
  //describe state transition
  //of a Moore machine
  always_comb begin
    
    bo=0;
    case (State)
      A: begin
        if (bi) NextState = B; 
        else NextState = A;
      end  
      
      B: begin
        bo=1;
        if (bi) NextState = C; 
        else NextState = A;
      end  
      
      C: begin
        if (bi) NextState = C; 
        else NextState = A;
       end
      
      default: begin
        NextState = A;
      end
    endcase 
  end 

  always_ff @(posedge Clk) begin
      State <= NextState;   // go to the state we described above
  end 
endmodule

module ButtonSynchronizer_tb;
  logic Clk, bi;        // system clock
  logic bo;             // system output 
  stateType StateOut; 
  	
  ButtonSynchronizer DUT( Clk, bi, bo, StateOut);
	
  always begin  // 50 MHz Clock
	  Clk = 1'b0; #10;
	  Clk = 1'b1; #10;
	end
  
  initial begin
    bi=1'b0; #25;//rest active
    assert(StateOut == A) $display("Start!");

    @(negedge Clk) bi=1'b1; #80;
    @(negedge Clk) bi=1'b0; #40;

    $stop;
  end
endmodule


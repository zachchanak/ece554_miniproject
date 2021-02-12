// Authors: Zachary Chanak, William Kelly, Evan Smith

module transpose_fifo
  #(
  parameter DEPTH=8,
  parameter BITS=64
  )
  (
  input clk,rst_n,en,WrEn,
  input [BITS-1:0] d,
  input [BITS-1:0] p_load [DEPTH-1:0],
  output [BITS-1:0] q
  );
  
  // fifo regs
  logic [BITS-1:0] fifo [DEPTH-1:0];
  
  // output assign
  assign q = fifo[0];
  
  always_ff @(posedge clk, negedge rst_n) begin

	if (!rst_n) begin

		for (integer i = 0; i < DEPTH; i++)
			fifo[i] <= {BITS{1'b0}};

	end
	
	else if (WrEn) begin
		fifo <= p_load;
	end

	else if (en) begin
		fifo[DEPTH-2:0] <= fifo[DEPTH-1:1];
		fifo[DEPTH-1] <= d;
	end
	
  end
  
endmodule // fifo
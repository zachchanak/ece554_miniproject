// fifo.sv
// Implements delay buffer (fifo)
// On reset all entries are set to 0
// Shift causes fifo to shift out oldest entry to q, shift in d

module fifo
  #(
  parameter DEPTH=8,
  parameter BITS=64
  )
  (
  input clk,rst_n,en,
  input [BITS-1:0] d,
  output [BITS-1:0] q
  );
  // your RTL code here
  
  // fifo regs
  reg [BITS-1:0] fifo [DEPTH-1:0];
  
  // output assign
  assign q = fifo[DEPTH-1];
  
  always_ff @(posedge clk, negedge rst_n) begin


	if (!rst_n) begin

		for (integer i = 0; i < DEPTH; i++)
			fifo[i] <= {BITS{1'b0}};

	end

	else if (en) begin
	
		if (DEPTH > 1) begin
			fifo[DEPTH-1:1] <= fifo[DEPTH-2:0];
			fifo[0] <= d;
		end
		
		else if (DEPTH == 1) begin
			fifo[0] <= d;
		end
	end
	
  end
  
endmodule // fifo

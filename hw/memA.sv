// Authors: Zachary Chanak, William Kelly, Evan Smith

module memA
  #(
    parameter BITS_AB=8,
    parameter DIM=8
    )
   (
    input                      clk,rst_n,en,WrEn,
    input signed [BITS_AB-1:0] Ain [DIM-1:0],
    input [$clog2(DIM)-1:0] Arow,
    output signed [BITS_AB-1:0] Aout [DIM-1:0]
   );

	// just wires...
	logic [DIM-1:0] wr_en_rows; 							// A row selector
	logic [BITS_AB-1:0] delay_fifo_out_rows [DIM-1:0];		// input to delay fifos follwing AMatrix
	logic [BITS_AB-1:0] delay_fifo_in_rows [DIM-1:0];		// outputs of delay fifos preceding AMatrix


	// continuous assignments
	assign Aout[0] = delay_fifo_out_rows[0];
	assign delay_fifo_in_rows[DIM-1] = '0;

	// AMatrix row write selection
	always_comb begin
	
		wr_en_rows = 0;
		wr_en_rows[Arow] = WrEn;
	
	end

	// fifos
	genvar i;
	generate
	
		// AMatrix fifos
		for (i = 0; i < DIM; i++) begin
		
			transpose_fifo #(.DEPTH(DIM),.BITS(BITS_AB)) AMatrix(.clk(clk),.rst_n(rst_n),.en(en),.WrEn(wr_en_rows[i]),.d(delay_fifo_in_rows[i]),.p_load(Ain),.q(delay_fifo_out_rows[i]));
			
		end
		
		// delay fifos
		for (i = 0; i < DIM-1; i++) begin

			fifo #(.DEPTH((DIM-1)-i),.BITS(BITS_AB)) delay_fifo_in(.clk(clk),.rst_n(rst_n),.en(en),.d('0),.q(delay_fifo_in_rows[i]));
			fifo #(.DEPTH(i+1),.BITS(BITS_AB)) delay_fifo_out(.clk(clk),.rst_n(rst_n),.en(en),.d(delay_fifo_out_rows[i+1]),.q(Aout[i+1]));

		end		
			
	endgenerate
	
endmodule
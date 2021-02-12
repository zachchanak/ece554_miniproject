module memB
  #(
    parameter BITS_AB=8,
    parameter DIM=8
    )
   (
    input                      clk,rst_n,en,
    input signed [BITS_AB-1:0] Bin [DIM-1:0],
    output signed [BITS_AB-1:0] Bout [DIM-1:0]
    );
	logic [4:0] cnt;
	always_ff @(posedge clk or negedge rst_n) begin
		if (!rst_n)
			cnt <= 5'b0;
		//else if(en)
		//	if (cnt == (DIM * 2) -1) 
		//		cnt <= 5'b0;
		//	else
		//		cnt <= cnt + 1;
		else if(en)
			cnt <= cnt + 1;
		else if (!en && cnt > 5'd25) 
			cnt <= 5'b0;
	end

   genvar i;
   logic signed [BITS_AB-1:0] fifo_in [DIM-1:0];
   always_comb begin
	for (int j = 0; j < DIM; j++) begin
		//fifo_in[j] = (cnt > 15) ? 8'b0 : (cnt >= DIM) ? 8'b0 : Bin[j];
		fifo_in[j] = (cnt >= DIM) ? 8'b0 : Bin[j];
	end
   end

   generate
	for (i = 0; i < BITS_AB; i++) begin
		
		
		//fifo #(.DEPTH(i+1), .BITS(BITS_AB)) fifo_cascade(.clk(clk), .rst_n(rst_n), .en(en), .d(fifo_in[i]), .q(Bout[i]));
		fifo #(.DEPTH(i + 8), .BITS(BITS_AB)) fifo_cascade(.clk(clk), .rst_n(rst_n), .en(en), .d(fifo_in[i]), .q(Bout[i]));
		
	end
endgenerate
	
endmodule
module systolic_array
#(
   parameter BITS_AB=8,
   parameter BITS_C=16,
   parameter DIM=8
   )
  (
   input                      clk,rst_n,WrEn,en,
   input signed [BITS_AB-1:0] A [DIM-1:0],
   input signed [BITS_AB-1:0] B [DIM-1:0],
   input signed [BITS_C-1:0]  Cin [DIM-1:0],
   input [$clog2(DIM)-1:0]    Crow,
   output signed [BITS_C-1:0] Cout [DIM-1:0]
   );
logic signed [BITS_AB-1:0] A_values [DIM-1:0][DIM:0];
logic signed [BITS_AB-1:0] B_values [DIM:0][DIM-1:0];
logic signed [BITS_C-1:0] C_values [DIM-1:0][DIM-1:0];
genvar j;
generate
	for (j = 0; j < DIM; j++) begin
		assign A_values[j][0] = A[j];
	end
endgenerate
assign B_values[0] = B;

logic WrEn_row[DIM-1:0];

logic [DIM-1:0] WrEn_temp;
integer x;
always @(Crow, WrEn) begin
	if (WrEn) begin
		for (x = 0; x < DIM; x++) begin
			if (x == Crow)
				WrEn_temp[x] = 1;
			else
				WrEn_temp[x] = 0;
		end
	end
	else 
		WrEn_temp = 8'b0;
end

genvar row,col;

generate 
	for (row = 0; row < DIM; row++) begin
		for (col = 0; col < DIM; col++) begin
			tpumac adder(.clk(clk), .rst_n(rst_n), .WrEn(WrEn_temp[row]), .en(en), .Ain(A_values[row][col]), .Bin(B_values[row][col]), .Cin(Cin[col]), .Aout(A_values[row][col+1]), .Bout(B_values[row+1][col]), .Cout(C_values[row][col]));
		end
	end  
endgenerate   
   
assign Cout = C_values[Crow];
  
endmodule
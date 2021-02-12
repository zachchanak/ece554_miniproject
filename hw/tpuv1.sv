module tpuv1
  #(
    parameter BITS_AB=8,
    parameter BITS_C=16,
    parameter DIM=8,
    parameter ADDRW=16,
    parameter DATAW=64
    )
   (
    input clk, rst_n, r_w, // r_w=0 read, =1 write
    input [DATAW-1:0] dataIn,
    output [DATAW-1:0] dataOut,
    input [ADDRW-1:0] addr
   );
   
logic [$clog2(DIM)-1:0] Crow;
logic [$clog2(DIM)-1:0] Arow;
logic A_en;
logic A_WrEn;
logic B_en;
logic C_WrEn;
logic en;
logic read_c_en;
logic write_c_en;
logic matMul_en;
logic c_high_out;
logic signed [BITS_AB-1:0] Ain [DIM-1:0];
logic signed [BITS_AB-1:0] Bin [DIM-1:0];
logic signed [BITS_AB-1:0] A [DIM-1:0];
logic signed [BITS_AB-1:0] B [DIM-1:0];
logic signed [BITS_C-1:0]  Cin [DIM-1:0];
logic signed [BITS_C-1:0] Cout [DIM-1:0];
assign {>>{Ain}} = matMul_en ? 0 : dataIn;
assign {>>{Bin}} = matMul_en ? 0 : dataIn;

//**********************************MODULES**************************************
systolic_array systolic_array(.clk(clk), .rst_n(rst_n), .WrEn(write_c_en), .en(en), .A(A), .B(B), .Cin(Cin), .Crow(Crow), .Cout(Cout));
memA memA(.clk(clk), .rst_n(rst_n), .en(A_en), .WrEn(A_WrEn), .Ain(Ain), .Arow(Arow), .Aout(A)); 	// dataIn?
memB memB(.clk(clk), .rst_n(rst_n), .en(B_en), .Bin(Bin), .Bout(B)); 								// dataIn?
//**********************************ENDMODULES***********************************

//assign A_en = (addr == 16'h0400 && r_w == 1 ) ? 1 : 0;

// COUNTER
parameter CNT_DIM = $clog2((3*DIM)-2);
logic [CNT_DIM:0] cnt; 
always_ff @(posedge clk, negedge rst_n) begin
	if (!rst_n)
		cnt <= {CNT_DIM{1'b0}};
	else if (en && cnt <= ((3*DIM) -2))
		cnt <= cnt + 1;
	else
		cnt <= {CNT_DIM{1'b0}};
end



logic [DATAW-1:0] C_low;
logic [DATAW-1:0] C_high;
assign C_low = {Cout[3],Cout[2], Cout[1], Cout[0]};
assign C_high = {Cout[7],Cout[6], Cout[5], Cout[4]};
logic [DATAW-1:0] dataOut_temp, dataOut_temp1;
logic c_high_out_test;
assign c_high_out_test = addr[3];
//assign dataOut = read_c_en ? c_high_out_ff ? C_high: C_low  : {DATAW-1{1'b0}};
assign dataOut = read_c_en ? c_high_out_test ? C_high: C_low  : {DATAW-1{1'b0}};
// Crow is simply a function of the addr....lowest address: Crow =0, ... highest Crow = 7;
assign Crow = addr[6:4];
// Arow is a function of the lower 7 bits of addr
assign Arow = addr[6:0] / 7'd8;


logic signed [BITS_C-1:0]  Cin_low [(DIM-1) / 2:0];
logic signed [BITS_C-1:0]  Cin_high [(DIM-1) /2:0];
// Cin low flop
always_ff @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		Cin_low[0] <= 16'b0;
		Cin_low[1] <= 16'b0;
		Cin_low[2] <= 16'b0;
		Cin_low[3] <= 16'b0;
	end
	
	else if ((addr[3:0] == 4'h0) && write_c_en == 1) begin
		Cin_low[0] <= dataIn[15:0];
		Cin_low[1] <= dataIn[31:16];
		Cin_low[2] <= dataIn[47:32];
		Cin_low[3] <= dataIn[63:48];
	end
	
end
// Cin high flop
always_ff @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		Cin_high[0] <= 16'b0;
		Cin_high[1] <= 16'b0;
		Cin_high[2] <= 16'b0;
		Cin_high[3] <= 16'b0;
	end
	
	else if (addr[3:0]== 4'h8 && write_c_en) begin
		Cin_high[0] <= dataIn[15:0];
		Cin_high[1] <= dataIn[31:16];
		Cin_high[2] <= dataIn[47:32];
		Cin_high[3] <= dataIn[63:48];
	
	end
		
	
end
// Concat Cin high with Cin low
assign Cin = {Cin_high, Cin_low};


// state machine
// TODO: implement WRITE_C and READ_C

typedef enum reg[1:0] {IDLE, MAT_MUL, READ_C_HIGH} state_t;
state_t state, nxt_state;

// state flop
always_ff @(posedge clk or negedge rst_n) begin
	if (!rst_n)
		state <= IDLE;
	else
		state <= nxt_state;

end
assign A_WrEn = addr >= 16'h0100 && addr <= 16'h013f && r_w == 1 ? 1 : 0;
always_comb begin
	// DEFAULT
	A_en = 0;
	//A_WrEn = 0;
	B_en = 0;
	C_WrEn = 0;
	en = 0;
	nxt_state = state;
	read_c_en = 0;
	write_c_en = 0;
	matMul_en = 0;
	c_high_out = 0;
	write_c_en = 0;	
	
	case(state)
		
		
		IDLE: begin
			// CHECK IF MATMUL
			if (addr == 16'h0400 && r_w == 1) begin
				// MIGHT TURN ON SIGNALS HERE IN PREP
				en = 1;
				A_en = 1;
				B_en = 1;
				matMul_en = 1;
				nxt_state = MAT_MUL;
			end
			// CHECK IF C ADDR
			else if (addr >= 16'h0300 && addr <= 16'h037f) begin
				// GO TO WRITE C
				if (r_w == 1) begin
					// TODO: Can do a write of C in this state
					write_c_en = 1;
				end
				// GO TO READ C
				else begin
					//TODO: Might be able to do read C in this state
					
					// read c low?
					read_c_en = 1;
					nxt_state = READ_C_HIGH;
				end
			end
			// WRITE TO B
			else if (addr >= 16'h0200 && addr <= 16'h023f && r_w == 1) begin
				B_en = 1;
				// TODO: Might need to set Bin input manually into array form
			end
			// WRITE TO A
			else if (addr >= 16'h0100 && addr <= 16'h013f && r_w == 1) begin
				//A_WrEn = 1;
				// TODO: Might need to set Ain input manually into array form
			end
		end
		READ_C_HIGH: begin
			nxt_state = IDLE;
			read_c_en = 1;
			c_high_out = 1;
			//A_WrEn = 1;
		end
		
		MAT_MUL: begin
			// WATCH OUT FOR OFF BY 1 SHENANIGANS
			en = 1;
			A_en = 1;
			B_en = 1;
			matMul_en = 1;
			if (cnt < ((3*DIM) -2)) begin
				nxt_state = MAT_MUL;
			end
			else 
				nxt_state = IDLE;
		
		end
	
	
	endcase

end

endmodule
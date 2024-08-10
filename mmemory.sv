module mmemory(
    input logic clk,
	input logic [3:0] address_1,address_2,
	input logic read1, read2,
	input logic write1, write2, 
	input logic [31:0] data_write1, data_write2,
	
	output logic mmvalid1, mmvalid2,
	output logic [1:0] tag_bit1, tag_bit2,
	output logic [31:0] readed1, readed2	
);
	logic valid1, valid2;
	assign valid1 = read1 && (address_1 <= 4'b1111);
	assign valid2 = read2 && (address_2 <= 4'b1111);

	integer i;
	logic [31:0] mem [15:0];
	initial begin
		#0	
		for(i=0;i<16;i=i+1)begin
			mem[i] <= 32'b0;
		end
		#5
		mem[4] <= 1'b1;
		mem[5] <= 2'b11;
		mem[14] <= 3'b111;
		mem[15] <= 4'b1111;
	end
	always@(posedge clk)begin
		mmvalid1 <= valid1;
		mmvalid2 <= valid2;
		if(mmvalid1) begin
	  		readed1 = mem[address_1];
			tag_bit1 = address_1[3:2];
		end
		if(mmvalid2) begin
			readed2 = mem[address_2];
			tag_bit2 = address_2[3:2];
		end
		if(write1)
			mem[address_1] <= data_write1;
		if(write2)
			mem[address_2] <= data_write2;
	end
endmodule

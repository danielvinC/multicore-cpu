module mmemory(
    input clk,
	input [3:0] address_read1,address_read2,
	input write1, write2, write3, write4,
	input [3:0] address_write1,address_write2,address_write3,address_write4, 
	input [31:0] data_write1, data_write2,data_write3, data_write4,
	
	output [1:0] tag_bit1, tag_bit2,
	output [31:0] readed1,readed2	
);
	integer i,j;
	reg [31:0] mem [15:0];
	assign readed1 = mem[address_read1];
	assign tag_bit1 = address_read1[3:2];
	assign readed2 = mem[address_read2];
	assign tag_bit2 = address_read2[3:2];
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
		if(write1)
			mem[address_write1] <= data_write1;
		if(write2)
			mem[address_write2] <= data_write2;
		if(write3)
			mem[address_write3] <= data_write3;
		if(write4)
			mem[address_write4] <= data_write4;
	end
endmodule
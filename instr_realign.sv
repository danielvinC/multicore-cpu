// Description: Instruction Re-aligner
//
// This module takes cache blocks and extracts the instructions.
// As we are supporting the compressed instruction set extension, in a 32 bit instruction word
// are up to 2 compressed instructions.

module instr_realign
(
    // Subsystem Clock - SUBSYSTEM
    input logic clk_i,
    // Asynchronous reset active low - SUBSYSTEM
    input logic rst_i,
    
    // Fetch flush request - CONTROLLER
    input logic flush_i,
    // 32-bit block - i$ 
    input logic [31:0] data_i,
    // Instruction - instrF_o
    output logic [31:0] instr_o,
	 
	 output logic PC_Stall
);


    // save the unaligned part of the instruction to this ff
    logic [15:0] unaligned_instr_n,   unaligned_instr_q;
    // the last instruction was unaligned
    logic        unaligned_n,         unaligned_q;
    // the previous instruction was compressed
    logic        compressed_n,        compressed_q;

    // as a maximum we support a fetch width of 64-bit, hence there can be 4 compressed instructions
    logic [1:0] instr_is_compressed;
    // LSB != 2'b11
    assign instr_is_compressed[0] = ~&data_i[0*16+:2];
    assign instr_is_compressed[1] = ~&data_i[1*16+:2];
    
    // Instruction re-alignment

    always_comb begin : re_align

        unaligned_n = unaligned_q;
		  
		PC_Stall = compressed_q;
		  
	    compressed_n = instr_is_compressed[0] && instr_is_compressed[1];

        unaligned_instr_n = 16'b0;
		           
        instr_o = unaligned_q ? {data_i[15:0], unaligned_instr_q} : compressed_q ? unaligned_instr_q : data_i[31:0];

        // we are serving the second part of an instruction which was also compressed
        //this instruction is compressed or the last instruction was unaligned
        if (!compressed_q && (instr_is_compressed[0] || unaligned_q))begin
            // check if this is instruction is still unaligned e.g.: it is not compressed
            // if its compressed re-set unaligned flag
            // for 32 bit we can simply check the next instruction and whether it is compressed or not
            // if it is compressed the next fetch will contain an aligned instruction
            // is instruction 1 also compressed
            // yes? -> save the upper bits for next cycle
            unaligned_instr_n = data_i[31:16];
            // no -> we've got an unaligned instruction
            if (instr_is_compressed[1]) begin
                unaligned_n = 1'b0;
            end else begin
                unaligned_n = 1'b1;
            end
        end  // else -> normal fetch

		  
		if (flush_i) begin
            // clear the unaligned and compressed instruction
            unaligned_n  = 1'b0;
            compressed_n = 1'b0;
        end
		  
    end 
    always_ff @(posedge clk_i, posedge rst_i) begin
        if (rst_i) begin
            unaligned_q         <= 1'b0;
            unaligned_instr_q   <= 16'b0;
            compressed_q        <= 1'b0;
        end else begin
            unaligned_q         <= unaligned_n;
            unaligned_instr_q   <= unaligned_instr_n;
            compressed_q        <= compressed_n;
        end
    end
endmodule


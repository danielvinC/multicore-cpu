module decompress(
    input logic [31:0] instr_i,
    output logic [31:0] instr_o
);
    always @* begin
        unique case (instr_i[1:0])
            // C0
            2'b00: begin
                unique case(instr_i[15:13])
                    3'b000: begin
                        // c.addi4spn -> addi rd', x2, imm
                        instr_o = {2'b0, instr_i[10:7], instr_i[12:11], instr_i[5], instr_i[6], 2'b00, 5'h02, 3'b000, 2'b01, instr_i[4:2], 7'b00_100_11};
                    end
                    3'b001: begin
                        // c.fld -> fld rd', imm(rs1')
                        // CLD: | funct3 | imm[5:3] | rs1' | imm[7:6] | rd' | C0 |
                        instr_o = {4'b0, instr_i[6:5], instr_i[12:10], 3'b000, 2'b01, instr_i[9:7], 3'b011, 2'b01, instr_i[4:2], 7'b00_001_11};
                    end
                    
                    3'b010: begin
                        // c.lw -> lw rd', imm(rs1')
                        instr_o = {5'b0, instr_i[5], instr_i[12:10], instr_i[6], 2'b00, 2'b01, instr_i[9:7], 3'b010, 2'b01, instr_i[4:2], 7'b00_000_11};
                    end

                    3'b011: begin
                        // c.ld -> ld rd', imm(rs1')
                        // CLD: | funct3 | imm[5:3] | rs1' | imm[7:6] | rd' | C0 |
                        instr_o = {4'b0, instr_i[6:5], instr_i[12:10], 3'b000, 2'b01, instr_i[9:7], 3'b011, 2'b01, instr_i[4:2], 7'b00_000_11};
                    end

                    3'b101: begin
                        // c.fsd -> fsd rs2', imm(rs1')
                        instr_o = {4'b0, instr_i[6:5], instr_i[12], 2'b01, instr_i[4:2], 2'b01, instr_i[9:7], 3'b011, instr_i[11:10], 3'b000, 7'b01_001_11};
                    end

                    3'b110: begin
                        // c.sw -> sw rs2', imm(rs1')
                        instr_o = {5'b0, instr_i[5], instr_i[12], 2'b01, instr_i[4:2], 2'b01, instr_i[9:7], 3'b010, instr_i[11:10], instr_i[6], 2'b00, 7'b01_000_11};
                    end

                    3'b111: begin
                        // c.sd -> sd rs2', imm(rs1')
                        instr_o = {4'b0, instr_i[6:5], instr_i[12], 2'b01, instr_i[4:2], 2'b01, instr_i[9:7], 3'b011, instr_i[11:10], 3'b000, 7'b01_000_11};
                    end

                    default: instr_o = instr_i;
                
                endcase 
            end

            //C1
            2'b01: begin
                unique case(instr_i[15:13])

                    3'b000: begin
                        // c.addi -> addi rd, rd, nzimm
                        // c.nop -> addi 0, 0, 0
                        instr_o = {{6 {instr_i[12]}}, instr_i[12], instr_i[6:2], instr_i[11:7], 3'b0, instr_i[11:7], 7'b00_100_11};
                    end

                    3'b010: begin
                        // c.li -> addi rd, x0, nzimm
                        instr_o = {{6 {instr_i[12]}}, instr_i[12], instr_i[6:2], 5'b0, 3'b0, instr_i[11:7], 7'b00_100_11};
                        if (instr_i[11:7] == 5'b0)  instr_o = 32'h0;
                    end

                    3'b100: begin
                        unique case (instr_i[11:10])

                            2'b10: begin
                                // c.andi -> andi rd, rd, imm
                                instr_o = {{6 {instr_i[12]}}, instr_i[12], instr_i[6:2], 2'b01, instr_i[9:7], 3'b111, 2'b01, instr_i[9:7], 7'b00_100_11};
                            end

                            2'b11: begin
                                unique case ({instr_i[12], instr_i[6:5]})
                                    3'b000: begin
                                        // c.sub -> sub rd', rd', rs2'
                                        instr_o = {2'b01, 5'b0, 2'b01, instr_i[4:2], 2'b01, instr_i[9:7], 3'b000, 2'b01, instr_i[9:7], 7'b01_100_11};
                                    end

                                    3'b001: begin
                                        // c.xor -> xor rd', rd', rs2'
                                        instr_o = {7'b0, 2'b01, instr_i[4:2], 2'b01, instr_i[9:7], 3'b100, 2'b01, instr_i[9:7], 7'b01_100_11};
                                    end

                                    3'b010: begin
                                        // c.or  -> or  rd', rd', rs2'
                                        instr_o = {7'b0, 2'b01, instr_i[4:2], 2'b01, instr_i[9:7], 3'b110, 2'b01, instr_i[9:7], 7'b01_100_11};
                                    end

                                    3'b011: begin
                                        // c.and -> and rd', rd', rs2'
                                        instr_o = {7'b0, 2'b01, instr_i[4:2], 2'b01, instr_i[9:7], 3'b111, 2'b01, instr_i[9:7], 7'b01_100_11};
                                    end

                                    default: begin
                                        instr_o = instr_i;
                                    end
                                endcase 
                            end
                        endcase
                    end
						  
					3'b101: begin
						// c.j   -> jal x0, imm
						instr_o = {instr_i[12], instr_i[8], instr_i[10:9], instr_i[6], instr_i[7], instr_i[2], instr_i[11], instr_i[5:3], {9 {instr_i[12]}}, 4'b0, ~instr_i[15], 7'b11_011_11};
	    			end

                    3'b110: begin
                        //c.beqz -> beq rs1', x0, imm
                        instr_o = {{4 {instr_i[12]}}, instr_i[6:5], instr_i[2], 5'b0, 2'b01, instr_i[9:7], 2'b00, instr_i[13], instr_i[11:10], instr_i[4:3], instr_i[12], 7'b11_000_11};
                    end

                    default: instr_o = instr_i;

                endcase
            end 

            default: instr_o = instr_i;
            
        endcase   
    end
endmodule

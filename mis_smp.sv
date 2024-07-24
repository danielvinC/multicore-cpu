module mis_smp(input logic clk, reset,
            output logic [31:0][1:0] WriteDataM,
            output logic [31:0][1:0] DataAdrM,
            output logic [1:0] MemReadM,
            output logic [1:0] MemWriteM,
            output logic [1:0] PCstall,
            output logic [31:0][1:0] PCF, 
            output logic [31:0][1:0] InstrF, 
            output logic [31:0][1:0] ReadDataM,
            output logic [31:0][1:0] dec
	);
    //all declerations of dmem pins

	logic [1:0][1:0] mmtag;
	logic [1:0][1:0] answer_i, ask;
	logic [3:0][1:0] Addr_rq;
	logic [1:0] bus_response_valid, bus_data_valid, mmvalid, mem_rden, mem_wren;
    
    logic [31:0][1:0] data_o, mmdata;

    
    riscv core1(clk, reset, PCF[0], InstrF[0], MemReadM[0], MemWriteM[0], PCstall[0], DataAdrM[0], WriteDataM[0], ReadDataM[0], dec[0]);
    imem imem1(PCF[0], InstrF[0]);

    riscv core2(clk, reset, PCF[1], InstrF[1], MemReadM[1], MemWriteM[1], PCstall[1], DataAdrM[1], WriteDataM[1], ReadDataM[1], dec[1]);
    imem imem2(PCF[1], InstrF[1]);

    dmem dmem1(
                clk,
                MemReadM[0], 
                MemWriteM[0],
                WriteDataM[0],
                DataAdrM[0],

                answer_i[1],
                ask[0],
                bus_response_valid[1],

                data_o[1],
                DataAdrM[1],
                bus_data_valid[0],

                mmvalid[0],
                mmdata[0],
                mmtag[0],
                mem_rden[0],
                mem_wren[0],

                Addr_rq[0],
                data_o[0],
            );
  
    dmem dmem2(
                clk,
                MemReadM[1], 
                MemWriteM[1],
                WriteDataM[1],
                DataAdrM[1],

                answer_i[0],
                ask[1],
                bus_response_valid[0],

                data_o[0],
                DataAdrM[0],
                bus_data_valid[1],

                mmvalid[1],
                mmdata[1],
                mmtag[1],
                mem_rden[1],
                mem_wren[1],

                Addr_rq[1],
                data_o[1],
            );
    mmemory ram_(
        clk,
        Addr_rq[0], Addr_rq[1],
        mem_rden[0],
        mem_rden[1],
        mem_wren[0],
        mem_wren[1],
        data_o[0],
        data_o[1],

        mmtag[0],
        mmtag[1],
        mmdata[0],
        mmdata[1]
    );

endmodule

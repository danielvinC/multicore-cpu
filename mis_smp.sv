module mesi_smp(input logic clk, reset,
            output logic [1:0][31:0] PCF, 
            output logic [1:0][31:0] InstrF, 
            output logic [1:0][31:0] ReadDataM
	);
    //all declerations of dmem pins

	logic [1:0][1:0] mmtag;
	logic P1_2_P2, P2_2_P1;
	logic [3:0][1:0] Addr_rq;
	logic [1:0] mmvalid, mem_rden, mem_wren;
    logic P1_2_P2_valid, P2_2_P1_valid;
    logic P1_seen_P2, P2_seen_P1;
    
    logic [31:0][1:0] mmdata;

    
    riscv core1(clk, reset, 
                PCF[0], 
                InstrF[0], 

                P2_2_P1,
                P1_2_P2,

                P2_seen_P1,
                P1_seen_P2,

                P2_2_P1_valid,
                ReadDataM[1],
                Addr_rq[1], 
                P1_2_P2_valid,

                mmvalid[0],
                mmdata[0],
                mmtag[0],
                mem_rden[0], mem_wren[0],

                Addr_rq[0],
                ReadDataM[0]
                );

    imem imem1(PCF[0], InstrF[0]);

    riscv core2(
                clk, reset,
                PCF[1], 
                InstrF[1], 

                P1_2_P2,
                P2_2_P1,

                P1_seen_P2,
                P2_seen_P1,

                P1_2_P2_valid,
                ReadDataM[0],
                Addr_rq[0], 
                P2_2_P1_valid,

                mmvalid[1],
                mmdata[1],
                mmtag[1],
                mem_rden[1], mem_wren[1],

                Addr_rq[1],
                ReadDataM[1]
                );

    imem imem2(PCF[1], InstrF[1]);

    mmemory ram_(
        clk,
        Addr_rq[0], 
        Addr_rq[1],
        mem_rden[0],
        mem_rden[1],
        mem_wren[0],
        mem_wren[1],
        ReadDataM[0],
        ReadDataM[1],

        mmvalid[0],
        mmvalid[1],
        mmtag[0],
        mmtag[1],
        mmdata[0],
        mmdata[1]
    );

endmodule

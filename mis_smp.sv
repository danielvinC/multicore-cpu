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

	logic [1:0] tagbit;
	logic [1:0][1:0] cache_bus_reply;
	logic [3:0][1:0] cache_ask_mem_address, cache_address_out_mem_cpu, cache_address_out_mem_bus;
	logic [1:0] cache_bus_reply_data_found;
	logic [31:0][1:0] cache_bus_reply_data_delivery, cache_data_out_cpu, cache_data_out_mem_cpu, cache_data_out_mem_bus;//connections for Caches outputs
	logic [1:0] cache_write_back_cpu, cache_write_back_bus;
    
    logic [31:0][1:0] mem_readed;

    
    riscv core1(clk, reset, PCF[0], InstrF[0], MemReadM[0], MemWriteM[0], PCstall[0], DataAdrM[0], WriteDataM[0], ReadDataM[0], dec[0]);
    imem imem1(PCF[0], InstrF[0]);

    riscv core2(clk, reset, PCF[1], InstrF[1], MemReadM[1], MemWriteM[1], PCstall[1], DataAdrM[1], WriteDataM[1], ReadDataM[1], dec[1]);
    imem imem2(PCF[1], InstrF[1]);

    dmem dmem1(
                .clk(clk),
                .read(MemReadM[0]), 
                .write(MemWriteM[0]), 
                .write_data(WriteDataM[0]), 
                .mem_address(DataAdrM[0]), 

                .bus_requests(cache_bus_reply[1]),
                .bus_request_mem_address(cache_ask_mem_address[1]),

                .bus_data_found(cache_bus_reply_data_found[1]),
                .bus_data_delivery(cache_bus_reply_data_delivery[1]),

                .mem_data_delivery(mem_readed[0]),
                .tag_bit(tagbit[0]),

                .data_out_cpu(ReadDataM[0]),

                .cpu_write_back(cache_write_back_cpu[0]),//<-outputs:
                .bus_write_back(cache_write_back_bus[0]),
                .address_out_mem_cpu(cache_address_out_mem_cpu[0]),
                .address_out_mem_bus(cache_address_out_mem_bus[0]),
                .data_out_mem_cpu(cache_data_out_mem_cpu[0]),
                .data_out_mem_bus(cache_data_out_mem_bus[0]),
                .bus_reply_abort_mem_access(cache_bus_reply_data_found[0]),
                .bus_reply_data_found(cache_bus_reply_data_delivery[0]),

                .ask_mem_address(cache_ask_mem_address[0]),
                .bus_reply(cache_bus_reply[0])
            );
    
    dmem dmem2(
                .clk(clk),
                .read(MemReadM[1]), 
                .write(MemWriteM[1]), 
                .write_data(WriteDataM[1]), 
                .mem_address(DataAdrM[1]), 

                .bus_requests(cache_bus_reply[0]),
                .bus_request_mem_address(cache_ask_mem_address[0]),

                .bus_data_found(cache_bus_reply_data_found[0]),
                .bus_data_delivery(cache_bus_reply_data_delivery[0]),

                .mem_data_delivery(mem_readed[1]),
                .tag_bit(tagbit[1]),

                .data_out_cpu(ReadDataM[1]),

                .cpu_write_back(cache_write_back_cpu[1]),//<-outputs:
                .bus_write_back(cache_write_back_bus[1]),
                .address_out_mem_cpu(cache_address_out_mem_cpu[1]),
                .address_out_mem_bus(cache_address_out_mem_bus[1]),
                .data_out_mem_cpu(cache_data_out_mem_cpu[1]),
                .data_out_mem_bus(cache_data_out_mem_bus[1]),
                .bus_reply_abort_mem_access(cache_bus_reply_data_found[1]),
                .bus_reply_data_found(cache_bus_reply_data_delivery[1]),

                .ask_mem_address(cache_ask_mem_address[1]),
                .bus_reply(cache_bus_reply[1])
            );

    mmemory ram_(
    .clk(clk),
	.address_read1(cache_ask_mem_address[0]), .address_read2(cache_ask_mem_address[1]),
    .write1(cache_write_back_cpu[0]), .write2(cache_write_back_bus[0]), .write3(cache_write_back_cpu[1]), .write4(cache_write_back_bus[1]),
    .address_write1(cache_address_out_mem_cpu[0]), .address_write2(cache_address_out_mem_bus[0]), .address_write3(cache_address_out_mem_cpu[1]), .address_write4(cache_address_out_mem_bus[1]),
    .data_write1(cache_data_out_mem_cpu[0]), .data_write2(cache_data_out_mem_bus[0]), .data_write3(cache_data_out_mem_cpu[1]), .data_write4(cache_data_out_mem_bus[1]),
    .tag_bit1(tagbit[0]), .tag_bit2(tagbit[1]),
    .readed1(mem_readed[0]), .readed2(mem_readed[1]));

endmodule

module snoop (
	input logic [1:0] status__q,
	input logic[1:0] message_i,
	output logic wren,
	output logic [1:0] status_n
 	);
	//States parameters, for status_q and state_out, simplificam a vida:
	parameter I=2'b00, M=2'b01, S=2'b10, E=2'b11;
	//Bus parameters, to go out for bus:
    parameter NA = 2'b00, bus_invalidate = 2'b01, bus_write_miss = 2'b10, bus_read_miss = 2'b11;



	always_comb begin : snooper
		status_n = status__q;
		wren = 1'b0;
		case(status__q)
			M:begin 
				case(message_i)
					bus_read_miss:begin
						status_n = S;
					end
					bus_write_miss:begin
						status_n = I;
					end 
				endcase
			end
			E:begin
				case(message_i)
					bus_read_miss:begin
						status_n = S;
						wren = 1'b1;
					end
					bus_write_miss:begin
						status_n = I;
						wren = 1'b0;
					end 
				endcase
			end
			S:begin
				if ( (message_i==bus_write_miss) || (message_i==bus_invalidate) )	begin	 			
					status_n = I;
				end
			end
		endcase
	end
endmodule

module cpu_rq_controller(
	input logic [1:0] status_q,
	input logic cpu_write_hit, cpu_read_hit,
	input logic cpu_write_miss, cpu_read_miss,
	
	output logic write_back_block_n,//used in implementation
	output logic [1:0] status_n, bus_n
	);
	//States parameters, for status_q and state_out, simplificam a vida:
	parameter I=2'b00, M=2'b01, S=2'b10;
	//Bus parameters, to go out for bus:
	parameter bus_ivalidate=2'b00, bus_write_miss=2'b01, bus_read_miss=2'b10;
	
	logic cpu_write, cpu_read;
	assign cpu_write = cpu_write_hit | cpu_write_miss;//whenever a write
	assign cpu_read = cpu_read_hit | cpu_read_miss;
	
	initial begin
		status_n <= I;
		bus_n <= 2'b0;
		write_back_block_n <= 0;
	end
	always @(*) begin
		case(status_q)
			I:begin
				case({cpu_write,cpu_read})
					2'b01: begin
						status_n <= S;
						bus_n <= bus_read_miss;
						write_back_block_n <= 0;
					end
					2'b10: begin
						status_n <= M;
						bus_n <= bus_write_miss;
						write_back_block_n <= 0;
					end
					default:begin
						status_n <= 2'b11;//error code
						bus_n <= 2'b11;
						write_back_block_n <= 0;
						$display("Error: no cpu should write and read at the once");
					end
				endcase
			end
			M:begin
				case({cpu_write_hit,cpu_read_hit,cpu_write_miss,cpu_read_miss})
					4'b0001:begin						
						status_n <= S;
						bus_n <= bus_read_miss;
						write_back_block_n <= 1;
					end
					4'b0010:begin
						status_n <= M;
						bus_n <= bus_write_miss;
						write_back_block_n <=1;					
					end
					4'b0100,4'b1000:begin
						status_n <= M;
						write_back_block_n <= 0;
					end
					default:begin
						status_n <= 2'b11;//error code
						bus_n <= 2'b11;
						write_back_block_n <= 0;
					end
				endcase			
			end
			S:begin
				case({cpu_write_hit,cpu_read_hit,cpu_write_miss,cpu_read_miss})
					4'b0001:begin
						status_n <= S;
						bus_n <= bus_read_miss;
						write_back_block_n <= 0;
					end
					4'b0010:begin
						status_n <= M;
						bus_n <= bus_write_miss;
						write_back_block_n <= 0;
					end
					4'b0100:begin
						status_n <= S;
						write_back_block_n <= 0;
					end
					4'b1000:begin
						status_n <= M;
						bus_n <= bus_ivalidate;
						write_back_block_n <= 0;
					end
					default:begin
						status_n <= 2'b11;//error code
						bus_n <= 2'b11;
						write_back_block_n <= 0;
					end
				endcase
			end
		endcase
	end
endmodule

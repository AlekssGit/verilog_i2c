module imp_generator_v2(address, clock, m_reset, m_enable, m_rw, m_tx_data, m_restart, s_50_tx_data, s_51_tx_data, s_50_reset, s_51_reset, m_clock, m_ack, m_rx_data, s_50_rx_data, s_51_rx_data, m_ready);
output logic [6:0] address;
output logic clock;
output logic m_reset;
output logic m_enable;
output logic m_rw;
output logic m_restart;
output logic [7:0] m_tx_data;
output logic [7:0] s_50_tx_data;
output logic [7:0] s_51_tx_data;
output logic s_50_reset;
output logic s_51_reset;
output logic m_clock;
input logic m_ack;
input logic  [7:0] m_rx_data;
input logic  [7:0] s_50_rx_data;
input logic  [7:0] s_51_rx_data;
input logic m_ready;
int i;
logic ack_posedge;

int cnt_idle;

logic [7:0] check_data;

enum int unsigned {
	WRITE,
	READ,
	ACK_1_W,
	ACK_1_R,
	ACK_2,
	IDLE
} state;

initial
begin
	clock = 0; 
	m_clock = 1'b0;
	m_reset = 1; 
	m_rw = 1'b0;
	m_restart = 0;
	m_enable = 0;
	m_tx_data = 8'hFE; 
	address = 7'h50;
	s_50_tx_data = 8'hCC;
	s_51_tx_data = 8'hBB;
	s_50_reset = 1'b1;
	s_51_reset = 1'b1;

	check_data = 8'hFE;

	state = WRITE;
	ack_posedge = 1'b0;
	cnt_idle = 0;

        #5;
        m_reset = 1;
        #5 
	m_reset = 0;
        #5 
	m_reset = 1;
	#15
	m_enable =  1;
	forever
	begin
		case(state)
		WRITE, READ: 
		begin
			m_enable = 1'b1;
			if(m_ack == 1'b0)
			begin
				if(ack_posedge)
				begin
					ack_posedge = 0;
					if(state == WRITE)
					begin					
						state = ACK_1_W;
					end
					else if (state == READ)
					begin
						state = ACK_1_R;
					end
				end
			end
		end
		ACK_1_R: 
		begin
			m_enable = 1'b0;
			if(m_ready)
			begin
				state = IDLE;
				cnt_idle = 0;
				ack_posedge = 0;
				if(check_data == m_rx_data)
					$info("success data write from slave to master");
				else
					$warning("wrong data write from slave to master");
			end
		end
		ACK_1_W: 
		begin
			m_enable = 1'b0;
			if(m_ready)
			begin
				state = IDLE;
				cnt_idle = 0;
				ack_posedge = 0;
				if(check_data == ((address == 7'h50) ? s_50_rx_data : s_51_rx_data))
					$info("success data write from master to slave");
				else
					$warning("wrong data write from master to slave");
			end
		end

		IDLE:
		begin
			if(cnt_idle < 15)
			begin
				cnt_idle++;
			end
			else
			begin
				cnt_idle = 0;
				m_rw = ~m_rw;
				state = (m_rw) ? READ : WRITE;
				address = (state == WRITE) ? 7'h50 :7'h51;
				if(state == WRITE)
				begin
					s_50_tx_data++;
					s_51_tx_data++;
					check_data = m_tx_data;
				end
				else if(state == READ)
				begin
					m_tx_data++;
					check_data = (address == 7'h50) ? s_50_tx_data : s_51_tx_data;
				end
			end
		end
		endcase
		
		if(m_ack == 1'b1)
		begin
			ack_posedge = 1'b1;
		end	


		m_clock = (i % 2) ? ~m_clock : m_clock;
		#5 
		clock=1;
          	#5 
		clock=0;
		i++;
	end
end

endmodule

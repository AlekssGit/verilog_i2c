module imp_generator_v2(address, clock, m_reset, m_enable, m_rw, m_tx_data, m_restart, s_50_tx_data, s_51_tx_data, s_50_reset, s_51_reset, m_clock, m_ack, m_rx_data, s_50_rx_data, s_51_rx_data, m_ready);

class TEST_DATA;
	randc bit [6 : 0] address;
	constraint address_valid { address inside { [7'h4C : 7'h52] }; }
	rand bit [7 : 0] master_data;
	rand bit [7 : 0] slave_1_data;
	rand bit [7 : 0] slave_2_data;
	constraint data_valid { master_data > 0; slave_1_data > 0; slave_2_data > 0; }
	rand bit master_reset;
endclass;
TEST_DATA rand_data;

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
int test_cnt;
int cnt_reset;

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
	rand_data = new();
	assert(rand_data.randomize());

	clock = 0; 
	m_clock = 1'b0;
	m_reset = 1; 
	m_rw = 1'b0;
	m_restart = 0;
	m_enable = 0;
	m_tx_data    = rand_data.master_data; 	//8'hFE; 
	address      = rand_data.address; 	//7'h50;
	s_50_tx_data = rand_data.slave_1_data; 	//8'hCC;
	s_51_tx_data = rand_data.slave_1_data; 	//8'hBB;
	s_50_reset = 1'b1;
	s_51_reset = 1'b1;

	check_data = 8'hFE;

	state = WRITE;
	ack_posedge = 1'b0;
	cnt_idle = 0;
	test_cnt = 0;
	cnt_reset = 0;

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
						cnt_reset = 0;
					end
					else if (state == READ)
					begin
						state = ACK_1_R;
					end
				end
				else  if(m_ready & (test_cnt > 10))
				begin
					test_cnt = 0;
					m_enable = 1'b0;
					state = IDLE;
				end
				else
				begin
					test_cnt++;
				end
			end

		end
		ACK_1_R: 
		begin
			m_enable = 1'b0;
			if(m_ready)
			begin
				//assert(rand_data.randomize());
				state = IDLE;
				test_cnt = 0;
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
			if(cnt_reset == 4)
			begin
				cnt_reset = 0;
				m_reset = rand_data.master_reset;
			end
			else 
				cnt_reset++;

			if(m_ready)
			begin
				state = IDLE;
				test_cnt = 0;
				cnt_idle = 0;
				ack_posedge = 0;
				if((address == 7'h50) || (address == 7'h51))
				begin
					if(check_data == ((address == 7'h50) ? s_50_rx_data : s_51_rx_data))
						$info("success data write from master to slave");
					else
						$warning("wrong data write from master to slave");
				end
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
				m_reset = 1'b1;
				assert(rand_data.randomize());
				cnt_idle = 0;
				m_rw = ~m_rw;
				state = (m_rw) ? READ : WRITE;
				address = rand_data.address; //(state == WRITE) ? 7'h50 :7'h51;
				if(state == WRITE)
				begin
					s_50_tx_data = rand_data.slave_1_data; //s_50_tx_data++;
					s_50_tx_data = rand_data.slave_1_data; //s_51_tx_data++;
					check_data = m_tx_data;
				end
				else if(state == READ)
				begin
					m_tx_data = rand_data.master_data;//m_tx_data++;
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

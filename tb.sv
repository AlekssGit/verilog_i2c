module tb();

logic clock;
wire scl;
wire sda;
// variables for master
logic [6:0] address;
logic m_reset;
logic m_enable;
logic m_rw;
logic m_ack;
logic m_nack;
logic m_ready;
logic [7:0] m_tx_data;
logic [7:0] m_rx_data;
logic m_restart;
//end variables for master

//variables for slaves with addresses: 0x50 and 0x51
logic [7:0] s_50_tx_data;
logic [7:0] s_50_rx_data;
logic 	s_50_ack;
logic 	s_50_r_ack;
logic	s_50_w_ack;
logic	s_50_reset;

logic [7:0] s_51_tx_data;
logic [7:0] s_51_rx_data;
logic 	s_51_ack;
logic 	s_51_r_ack;
logic	s_51_w_ack;
logic	s_51_reset;

pullup (weak1) pull_sda (sda);
pullup (weak1) pull_scl (scl);

logic m_clock;

//end variables for slave
imp_generator gen (.address(address), .clock(clock), .m_reset(m_reset), .m_enable(m_enable), .m_rw(m_rw), .m_tx_data(m_tx_data), .m_restart(m_restart), .s_50_tx_data(s_50_tx_data), .s_51_tx_data(s_51_tx_data), .s_50_reset(s_50_reset), .s_51_reset(s_51_reset), .m_clock(m_clock));
i2c_master master ( .clk(m_clock), .txdata(m_tx_data), .address(address), .enable(m_enable), .rw(m_rw), .restart(m_restart), .reset_n(m_reset), .scl(scl), .sda(sda), .rxdata(m_rx_data), .ack(m_ack), .nack(m_nack), .ready(m_ready));
i2c_slave #(7'h50) slave_50 (.clk(clock), .reset_n(s_50_reset), .scl(scl), .sda(sda) , .txdata(s_50_tx_data), .rxdata(s_50_rx_data), .ack(s_50_ack), .r(s_50_r), .w(s_50_w));
i2c_slave #(7'h51) slave_51 (.clk(clock), .reset_n(s_51_reset), .scl(scl), .sda(sda) , .txdata(s_51_tx_data), .rxdata(s_51_rx_data), .ack(s_51_ack), .r(s_51_r), .w(s_51_w));
endmodule

module imp_generator(address, clock, m_reset, m_enable, m_rw, m_tx_data, m_restart, s_50_tx_data, s_51_tx_data, s_50_reset, s_51_reset, m_clock);
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

int i;

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
		for(i = 0; i < 140; i++)
		begin
			case(i)
			0,1,2,3,4,5,6,7,8: m_restart = 1;
			default: m_restart = 0;
			endcase
			if(i % 2 == 0)
				m_clock = ~m_clock;
			#5 
			clock=1;
          		#5 
			clock=0;
		end
		if(address == 7'h50)
			address = address + 1'b1;
		else
			address = address - 1'b1;
		m_rw = ~m_rw;
	end
end

endmodule
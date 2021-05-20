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
logic m_ready;
logic [7:0] m_tx_data;
logic [7:0] m_rx_data;
logic m_restart;
//end variables for master

//variables for slaves with addresses: 0x50 and 0x51
logic [7:0] s_50_tx_data;
logic [7:0] s_50_rx_data;
logic 	s_50_ack;
logic	s_50_reset;

logic [7:0] s_51_tx_data;
logic [7:0] s_51_rx_data;
logic 	s_51_ack;
logic	s_51_reset;

pullup (weak1) pull_sda (sda);
pullup (weak1) pull_scl (scl);

logic m_clock;

//end variables for slave

imp_generator_v2 gen_v2 (.address(address), .clock(clock), .m_reset(m_reset), .m_enable(m_enable), .m_rw(m_rw), .m_tx_data(m_tx_data), .m_restart(m_restart), .s_50_tx_data(s_50_tx_data), .s_51_tx_data(s_51_tx_data), .s_50_reset(s_50_reset), .s_51_reset(s_51_reset), .m_clock(m_clock), .m_ack(m_ack), .m_rx_data(m_rx_data), .s_50_rx_data(s_50_rx_data), .s_51_rx_data(s_51_rx_data), .m_ready(m_ready));
i2c_master master ( .clk(m_clock), .txdata(m_tx_data), .address(address), .enable(m_enable), .rw(m_rw), .restart(m_restart), .reset_n(m_reset), .scl(scl), .sda(sda), .rxdata(m_rx_data), .ack(m_ack), .ready(m_ready));
i2c_slave #(7'h50) slave_50 (.clk(clock), .reset_n(s_50_reset), .scl(scl), .sda(sda) , .txdata(s_50_tx_data), .rxdata(s_50_rx_data), .ack(s_50_ack), .r(s_50_r), .w(s_50_w));
i2c_slave #(7'h51) slave_51 (.clk(clock), .reset_n(s_51_reset), .scl(scl), .sda(sda) , .txdata(s_51_tx_data), .rxdata(s_51_rx_data), .ack(s_51_ack), .r(s_51_r), .w(s_51_w));
endmodule
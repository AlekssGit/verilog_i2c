module i2c_maseter_tb();

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

    pullup (weak1) pull_sda(sda);
    pullup (weak1) pull_scl(scl);
    logic _sda;

    assign sda = _sda;
    int i;

    logic [7:0] rx_data;

    i2c_master master(
        .clk(clock),
        .txdata(m_tx_data),
        .address(address),
        .enable(m_enable),
        .rw(m_rw),
        .restart(m_restart),
        .reset_n(m_reset),
        .scl(scl),
        .sda(sda),
        .rxdata(m_rx_data),
        .ack(m_ack),
        .ready(m_ready)
    );

    initial
        begin
            address = 7'h52;
            clock = 0;
            m_reset = 0;
            m_enable = 0;
            m_restart = 0;
            _sda = 1'bz;
            #5;
            m_reset = 1;
            #5;
            m_reset = 0;
            #5;
            m_reset = 1;

            // read 1 byte from slave
            #15;
            m_rw = 1;
            m_enable = 1;
            address = 7'h52;
            rx_data = 8'hca;

            // slave ack
            #180;
            _sda = 0;
            #20;
            m_enable = 0;
            for (i = 0; i < 8; i++)
                begin
                    _sda = rx_data[7 - i] ? 1'bz : 1'b0;
                    #20;
                end
            _sda = 1'bz;
            #40;
            // end read 1 byte from slave

            // write 1 byte to slave
            #15;
            m_rw = 0;
            m_enable = 1;
            m_tx_data = 8'haa;
            address = 7'h52;

            // slave ack
            #180;
            _sda = 0;
            #20;
            _sda = 1'bz;
            m_enable = 0;

            #200;
            // end write 1 byte to slave

            // slave don't respond
            #15;
            m_rw = 0;
            m_enable = 1;
            m_tx_data = 8'haa;
            address = 7'h52;

            // slave nack
            #180;
            _sda = 1'bz;
            #20;
            m_enable = 0;

            #200;
            // end slave don't respond

        end

    always #5
        begin
            clock = ~clock;
        end

endmodule : i2c_maseter_tb








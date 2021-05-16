module i2c_slave_tb();


    logic clock;
    wire scl;
    wire sda;
    logic [7:0] s_rxdata;
    logic [7:0] s_txdata;

    logic [6:0] address;
    logic [7:0] rxdata;
    logic [7:0] txdata;

    pullup (weak1) pull_sda(sda);
    pullup (weak1) pull_scl(scl);

    logic _scl;
    logic _sda;

    assign sda = _sda;
    assign scl = _scl;
    int i;

    i2c_slave#(.ADRS(7'h50)) slave(
        .scl(scl),
        .sda(sda),
        .clk(clock),
        .reset_n(1'b1),
        .rxdata(s_rxdata),
        .txdata(s_txdata)
    );

    initial
        begin
            _sda = 1'bz;
            _scl = 1'bz;
            clock = 1'b0;

            // slave writes data

            s_txdata = 8'hcd;
            address = 7'h50;

            //start
            #20;
            _sda = 1'b0;
            #20;
            _scl = 1'b0;

            // address
            for (i = 0; i < 7; i++)
                begin
                    #20;
                    _sda = address[6-i] ? 1'bz:1'b0;
                    #20;
                    _scl = 1'bz;
                    #40;
                    _scl = 1'b0;
                end

            // rw
            #20;
            _sda = 1'bz; // read
            #20;
            _scl = 1'bz;
            #40;
            _scl = 1'b0;

            // wait ack
            #20;
            _sda = 1'bz;
            #20;
            _scl = 1'bz;
            #40;
            _scl = 1'b0;

            // read
            for (i = 0; i < 8; i++)
                begin
                    #40;
                    _scl = 1'bz;
                    rxdata[7-i] = sda;
                    #40;
                    _scl = 1'b0;
                end
            // check if rxdata = s_txdata

            // nack
            #20;
            _sda = 1'bz;
            #20;
            _scl = 1'bz;
            #40;
            _scl = 1'b0;

            // stop
            #20;
            _sda = 1'b0;
            #20;
            _scl = 1'bz;
            #20;
            _sda = 1'bz;

            // end slave writes data

            #100;

            // wrong slave address

            address = 7'h51;

            //start
            #20;
            _sda = 1'b0;
            #20;
            _scl = 1'b0;

            // address
            for (i = 0; i < 7; i++)
                begin
                    #20;
                    _sda = address[6-i] ? 1'bz:1'b0;
                    #20;
                    _scl = 1'bz;
                    #40;
                    _scl = 1'b0;
                end

            // rw
            #20;
            _sda = 1'bz; // read
            #20;
            _scl = 1'bz;
            #40;
            _scl = 1'b0;

            // wait ack
            #20;
            _sda = 1'bz;
            #20;
            _scl = 1'bz;
            // check whether sda is 1 or not
            #40;
            _scl = 1'b0;

            // stop
            #20;
            _sda = 1'b0;
            #20;
            _scl = 1'bz;
            #20;
            _sda = 1'bz;

            // end wrong slave address

            #100;

            // slave read data

            txdata = 8'had;
            address = 7'h50;

            //start
            #20;
            _sda = 1'b0;
            #20;
            _scl = 1'b0;

            // address
            for (i = 0; i < 7; i++)
                begin
                    #20;
                    _sda = address[6-i] ? 1'bz:1'b0;
                    #20;
                    _scl = 1'bz;
                    #40;
                    _scl = 1'b0;
                end

            // rw
            #20;
            _sda = 1'b0; // write
            #20;
            _scl = 1'bz;
            #40;
            _scl = 1'b0;

            // wait ack
            #20;
            _sda = 1'bz;
            #20;
            _scl = 1'bz;
            #40;
            _scl = 1'b0;

            // write
            for (i = 0; i < 8; i++)
                begin
                    #20;
                    _sda = txdata[7-i] ? 1'bz:1'b0;
                    #20;
                    _scl = 1'bz;
                    #40;
                    _scl = 1'b0;
                end
            // check if txdata = s_rxdata

            // wait for ack
            #20;
            _sda = 1'bz;
            #20;
            _scl = 1'bz;
            #40;
            _scl = 1'b0;

            // stop
            #20;
            _sda = 1'b0;
            #20;
            _scl = 1'bz;
            #20;
            _sda = 1'bz;

            // end slave read data

        end

    always #5
        begin
            clock = ~clock;
        end


endmodule: i2c_slave_tb
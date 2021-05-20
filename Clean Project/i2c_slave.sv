module i2c_slave
    #(
        parameter reg [6:0] ADRS=7'b1010000
    )
    (
        input clk,
        input reset_n,
        input scl,
        inout sda,
        input [7:0] txdata,
        output reg [7:0] rxdata,
        output reg ack,
        output reg r,
        output reg w
    );


    logic start_detect = 0;
    logic stop_detect = 0;

    logic sda_reg = 1;
    logic scl_reg = 1;

    logic [7:0] txshift = '1;
    logic [7:0] rxshift = '1;
    logic [2:0] counter = '0;

    logic read_strobe = 0;
    logic write_strobe = 0;

    logic _sda = 1'bz;

    enum int unsigned {
        IDLE,
        ADDRESS,
        READ,
        WRITE,
        ACK_A,
        NACK,
        ACK_W,
        ACK_R,
        RW
    } state, next;

    assign sda = _sda;

    always @(posedge clk)
        begin
            start_detect = sda_reg && ~sda && scl;
            stop_detect = ~sda_reg && sda && scl;
            read_strobe = ~scl_reg && scl;
            write_strobe = scl_reg && ~scl;
            sda_reg = sda;
            scl_reg = scl;
        end

    always @(posedge clk, negedge reset_n)
        begin
            if (~reset_n)
                begin
                    state = IDLE;
                end
            else
                begin
                    if (stop_detect)
                        state = IDLE;
                    else
                        state = next;
                end
        end

    always_comb
        begin
            case (state)
                IDLE: next = start_detect ? ADDRESS:IDLE;
                ADDRESS: next = counter == 7 ? RW:ADDRESS;
                RW: next = read_strobe ? (ADRS == rxshift[7:1] ? ACK_A:NACK):RW;
                ACK_A: next = read_strobe ? (rxshift[0] ? WRITE:READ):ACK_A;
                NACK: next = read_strobe ? IDLE:NACK;
                READ: next = read_strobe && counter == 0 ? ACK_R:start_detect ? ADDRESS:READ;
                WRITE: next = read_strobe && counter == 0 ? ACK_W:start_detect ? ADDRESS:WRITE;
                ACK_W: next = read_strobe ? (sda ? IDLE:WRITE):ACK_W;
                ACK_R: next = read_strobe ? READ:ACK_R;
            endcase
        end

    always @(posedge clk)
        begin
            if (read_strobe)
                begin
                    if (state == ACK_W || state == ACK_R || state == ACK_A && r)
                        ack = ~sda;
                    else
                        ack = 1'b0;
                end
        end

    always @(posedge clk)
        begin
            if (read_strobe)
                begin
                    if (state == IDLE || state == ADDRESS)
                        begin
                            r = 1'b0;
                            w = 1'b0;
                        end
                    else if (state == RW)
                        begin
                            r = sda;
                            w = ~sda;
                        end
                end
        end

    always @(posedge clk)
        begin
            if (write_strobe)
                begin
                    case (state)
                        IDLE, ADDRESS, RW, NACK, READ, ACK_W:
                            begin
                                _sda = 1'bz;
                            end
                        ACK_A, ACK_R:
                            begin
                                _sda = 1'b0;
                            end
                        WRITE:
                            begin
                                _sda = txshift[7] ? 1'bz:1'b0;
                            end
                    endcase

                end
        end

    always @(posedge clk)
        begin
            if (state == IDLE)
                counter = '0;
            else if (read_strobe && (state == ADDRESS || state == READ || state == RW) || write_strobe && state == WRITE)
                counter++;
        end

//read sda
    always @(posedge clk)
        begin
            if (read_strobe && (state == ADDRESS || state == READ || state == RW))
                rxshift = {rxshift[6:0], sda};
        end

    always @(posedge clk)
        begin
            if (read_strobe && state == ACK_R)
                rxdata = rxshift;
        end

//write to sda
    always @(posedge clk)
        begin
            if (write_strobe && (state == WRITE || state == ACK_A && r || state == ACK_W))
                txshift = (state == WRITE) ? {txshift[6:0], 1'b1}:txdata;
        end


endmodule : i2c_slave
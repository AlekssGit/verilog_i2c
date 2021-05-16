module i2c_slave
#(
	parameter reg [6:0] ADRS = 7'b1010000
)
(
	input scl,
	inout sda,
	input [7:0] txdata,
	output reg [7:0] rxdata,
	output reg ack,
	output reg r,
	output reg w
);

reg [7:0] txshift;
reg [7:0] rxshift;
reg [2:0] counter;

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

// start detector
reg start_detect;
reg start_reset;

reg _sda;
assign sda = _sda;

always @(negedge sda, posedge start_reset)
begin
	if (start_reset)
		start_detect = 1'b0;
	else 
		start_detect = scl;
end

always @(posedge scl)
begin
	start_reset = start_detect;
end

//stop detector
reg stop_detect;
reg stop_reset;

always @(posedge sda, posedge stop_reset)
begin
	if (stop_reset)
		stop_detect = 1'b0;
	else 
		stop_detect = scl;
end

always @(negedge sda)
begin
	stop_reset = stop_detect;
end

//state logic
always @(negedge scl, posedge stop_detect)
begin
	if (stop_detect)
		state = IDLE;
	else
		state = next;
end

always_comb
begin
	case (state)
		IDLE: next = start_detect ? ADDRESS : IDLE;
		ADDRESS: next = counter == 6 ? RW : ADDRESS;
		RW: next = ADRS == rxshift[6:0] ? ACK_A : NACK;
		ACK_A: next = rxshift[0] ? WRITE : READ;
		NACK: next = IDLE;
		READ: next = counter == 7 ? ACK_R : start_detect ? ADDRESS : READ;
		WRITE: next = counter == 7 ? ACK_W : start_detect ? ADDRESS : WRITE;
		ACK_W: next = sda ? IDLE : WRITE;
		ACK_R: next = READ;
	endcase
end

always @(negedge scl, posedge stop_detect)
begin
	if (stop_detect)
		ack = 1'b0;
	else
	begin
		if (state == ACK_W || state == ACK_R || state == ACK_A && r)
			ack = ~sda;
		else
			ack = 1'b0;
	end
end

always @(negedge scl, posedge stop_detect)
begin
	if (stop_detect)
	begin
		r = 1'b0;
		w = 1'b0;
	end
	else
	begin
		if (state == IDLE || state == ADDRESS)
		begin
			r = 1'b0;
			w = 1'b0;
		end
		else if (state == RW && ADRS == rxshift[6:0])
		begin
			r = sda;
			w = ~sda;
		end
	end
end

always_comb
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
			_sda = txshift[7] ? 1'bz : 1'b0;
		end
	endcase
end

always @(negedge scl, posedge start_detect)
begin
	if (start_detect)
		counter = '0;
	else if (state == ADDRESS || state == READ || state == WRITE || state == RW)
		counter++;
end

//read sda
always @(negedge scl)
begin
	if (state == ADDRESS || state == READ || state == RW)
		rxshift = {rxshift[6:0], sda};
end

always @(posedge scl)
begin
	if (state == ACK_R)
		rxdata = rxshift;
end

//write to sda
always @(negedge scl)
begin
	if (state == WRITE || state == ACK_A && r || state == ACK_W)
		txshift = (state == WRITE) ? {txshift[6:0], 1'b1} : txdata;
end

endmodule 
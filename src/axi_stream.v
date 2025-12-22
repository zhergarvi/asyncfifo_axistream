
module axi_stream #(
		parameter DATA_WIDTH = 32,
		parameter DEPTH = 4096
	) (
		input            			ACLK, 
		input            			ARESETn, 
		output wire [DATA_WIDTH-1:0] M_AXIS_TDATA, 
		output reg          		M_AXIS_TVALID,
		output wire [(DATA_WIDTH/8)-1:0]				M_AXIS_TSTRB, 
		input            			M_AXIS_TREADY,
		output wire         		M_AXIS_TLAST,
		input  						wr_clk,
		input  						wr_rstn,
		input  [DATA_WIDTH-1:0] 	din,
		input  						wr_en
	);

	wire [DATA_WIDTH-1:0] fifo_dout;
	wire fifo_empty;
	wire fifo_full;
	reg  fifo_rd_en;

	wire rd_clk;
	wire rd_rst;
	wire wr_rst;

	wire rd_ack_w;
	wire wr_req_w;
	
	reg wr_req;
	reg rd_ack_sync_w;
	reg rd_ack;
	reg rd_en;
	reg read_start_flag;
	wire m_axis_tlast_reg;
	wire write_burst_done;

	reg  	axis_tlast;
	wire  	axis_tvalid;
	reg [7:0] count;
	
	assign rd_clk = ACLK;
	assign rd_rst = ~ARESETn;
	assign wr_rst = ~wr_rstn;

	async_fifo #(
		.DATA_WIDTH(DATA_WIDTH),
		.DEPTH(DEPTH)
		) u_async_fifo (
		.wr_clk(wr_clk),
		.wr_rst(wr_rst),
		.din(din),
		.wr_en(wr_en),
		.full(fifo_full),

		.rd_clk(rd_clk),
		.rd_rst(rd_rst),
		.dout(fifo_dout),
		.rd_en(rd_en),
		.empty(fifo_empty)
	);

	assign axis_tvalid = read_start_flag && !fifo_empty;

	negedge_detection negedge_detection_inst (.clk(wr_clk),.rst(wr_rst),.in(wr_en),.out(write_burst_done));
	
	// posedge_detection posedge_detection_inst (.clk(rd_clk),.rst(rd_rst),.in(fifo_empty),.out(M_AXIS_TLAST));
	
	synchronizer #(.DATA_WIDTH(0)) u_sync_tlast_trigger_0 (.dest_clk(rd_clk),.dest_rst(rd_rst),.data_in(wr_req),.data_out(wr_req_w));

	synchronizer #(.DATA_WIDTH(0)) u_sync_tlast_trigger_1 (.dest_clk(wr_clk),.dest_rst(wr_rst),.data_in(rd_ack),.data_out(rd_ack_w));

	// Generate request
	always @(posedge wr_clk or posedge wr_rst) begin
		if (wr_rst) begin
			wr_req <= 1'b0;
			rd_ack_sync_w <= 1'b0;
		end else begin
			if (write_burst_done) begin
				wr_req <= 1'b1;
			end else if (wr_req && rd_ack_sync_w) begin
				wr_req <= 1'b0;
			end
			rd_ack_sync_w <= rd_ack_w; 
		end
	end

	// Acknowledge the request
	always @(posedge rd_clk or posedge rd_rst) begin
		if (rd_rst) begin
			read_start_flag <= 1'b0;
        	rd_ack <= 1'b0;
		end else begin
			if (wr_req_w) begin
				read_start_flag <= 1'b1;
				rd_ack <= 1'b1;
			end else if (!wr_req_w && rd_ack) begin
				rd_ack <= 1'b0;
			end
			if (fifo_empty) begin
            	read_start_flag <= 1'b0;
        	end
		end
	end

	assign rd_en = read_start_flag && axis_tvalid && M_AXIS_TREADY;

	always @(posedge rd_clk or posedge rd_rst) begin
		if (rd_rst) begin
			count      <= 8'd0;
			axis_tlast <= 1'b0;
		end else begin
			if (rd_en) begin
				if (count == 8'd255) begin
					count <= 8'd0;
				end else begin
					count <= count + 1;
				end
				axis_tlast <= (count == 8'd254);
			end
		end
	end

	assign M_AXIS_TDATA = fifo_dout;
	assign M_AXIS_TLAST	= axis_tlast;
	assign M_AXIS_TVALID = axis_tvalid;
	assign M_AXIS_TSTRB	= {(DATA_WIDTH/8){1'b1}};
endmodule

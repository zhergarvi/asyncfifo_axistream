`timescale 1 ns / 1 ps

module async_fifo #(
		parameter DATA_WIDTH = 32,
		parameter DEPTH = 16384
	) (
		input  						wr_clk,
		input  						wr_rst,
		input  [DATA_WIDTH-1:0] 	din,
		input  						wr_en,
		output wire 				full,

		input  						rd_clk,
		input  						rd_rst,
		output reg [DATA_WIDTH-1:0] dout,
		input  						rd_en,
		output wire 				empty
	);

	localparam ADDR_WIDTH = $clog2(DEPTH);

	reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];

	integer i;
	initial begin
		for (i = 0; i < DEPTH; i = i + 1) begin
			mem[i] = 0;
		end
	end

	reg [ADDR_WIDTH:0] w_ptr_bin;
	reg [ADDR_WIDTH:0] r_ptr_bin;

	reg [ADDR_WIDTH:0] w_ptr_gray;
	reg [ADDR_WIDTH:0] r_ptr_gray;

	wire [ADDR_WIDTH:0] r_ptr_sync_wclk;
	wire [ADDR_WIDTH:0] w_ptr_sync_rclk;


	always @(posedge wr_clk or posedge wr_rst) begin
		if (wr_rst) begin
			w_ptr_bin <= 0;
			w_ptr_gray <= 0;
		end else if (wr_en && !full) begin
			w_ptr_bin <= w_ptr_bin + 1;
			w_ptr_gray <= ((w_ptr_bin + 1) >> 1) ^ (w_ptr_bin + 1);
		end
	end



	always @(posedge rd_clk or posedge rd_rst) begin
		if (rd_rst) begin
			r_ptr_bin <= 0;
			r_ptr_gray <= 0;
		end else if (rd_en && !empty) begin
			r_ptr_bin <= r_ptr_bin + 1;
			r_ptr_gray <= ((r_ptr_bin + 1) >> 1) ^ (r_ptr_bin + 1);
		end
	end

	assign full = (w_ptr_gray[ADDR_WIDTH-1] != r_ptr_sync_wclk[ADDR_WIDTH-1]) &&
					(w_ptr_gray[ADDR_WIDTH-2:0] == r_ptr_sync_wclk[ADDR_WIDTH-2:0]);

	assign empty = (r_ptr_gray == w_ptr_sync_rclk);


	// --- Memory Core Logic ---
	always @(posedge wr_clk) begin
		if (wr_en && !full) begin
			mem[w_ptr_bin[ADDR_WIDTH-1:0]] <= din;
		end
	end

	always @(posedge rd_clk) begin
		if (rd_rst) begin
			dout <= 32'h0; end
		else if (rd_en && !empty) begin
			dout <= mem[r_ptr_bin[ADDR_WIDTH-1:0]];
		end
	end	

	synchronizer #(
		.DATA_WIDTH(ADDR_WIDTH)
	) u_sync_r_to_w (
		.dest_clk(wr_clk),
		.dest_rst(wr_rst),
		.data_in(r_ptr_gray),
		.data_out(r_ptr_sync_wclk)
	);

	synchronizer #(
		.DATA_WIDTH(ADDR_WIDTH)
	) u_sync_w_to_r (
		.dest_clk(rd_clk),
		.dest_rst(rd_rst),
		.data_in(w_ptr_gray),
		.data_out(w_ptr_sync_rclk)
	);

endmodule

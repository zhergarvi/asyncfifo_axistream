`timescale 1 ns / 1 ps

module async_fifo #(
		parameter DATA_WIDTH = 32,
		parameter DEPTH = 1024,
		parameter ADDR_WIDTH = $clog2(DEPTH)
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
		output wire 				empty,
		output  [DATA_WIDTH-1:0] 	din_test,
		output [ADDR_WIDTH:0] w_ptr_bin,
		output [ADDR_WIDTH:0] r_ptr_bin,
		output wr_en_test
	);


	reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];

	reg [ADDR_WIDTH:0] w_ptr_bin;
	reg [ADDR_WIDTH:0] r_ptr_bin;

	reg [ADDR_WIDTH:0] w_ptr_gray;
	reg [ADDR_WIDTH:0] r_ptr_gray;

	wire [ADDR_WIDTH:0] r_ptr_sync_wclk;
	wire [ADDR_WIDTH:0] w_ptr_sync_rclk;

	wire [ADDR_WIDTH:0] w_ptr_bin_next;
	wire [ADDR_WIDTH:0] r_ptr_bin_next;

	assign wr_en_test = wr_en;
	
	assign w_ptr_bin_next = w_ptr_bin + 1;
	always @(posedge wr_clk or posedge wr_rst) begin
		
		if (wr_rst) begin
			w_ptr_bin <= {ADDR_WIDTH+1{1'b0}};
			w_ptr_gray <= {ADDR_WIDTH+1{1'b0}};
		end else if (wr_en && !full) begin
			w_ptr_bin  <= w_ptr_bin_next;
			w_ptr_gray <= (w_ptr_bin_next >> 1) ^ w_ptr_bin_next;
		end
	end

	assign r_ptr_bin_next = r_ptr_bin + 1;
	always @(posedge rd_clk or posedge rd_rst) begin
		
		if (rd_rst) begin
			r_ptr_bin <= {ADDR_WIDTH+1{1'b0}};
			r_ptr_gray <= {ADDR_WIDTH+1{1'b0}};
		end else if (rd_en && !empty) begin
			r_ptr_bin <= r_ptr_bin_next;
			r_ptr_gray <= (r_ptr_bin_next >> 1) ^ r_ptr_bin_next;
		end
	end

	// assign full = (w_ptr_gray[ADDR_WIDTH-1] != r_ptr_sync_wclk[ADDR_WIDTH-1]) &&
	// 				(w_ptr_gray[ADDR_WIDTH-2:0] == r_ptr_sync_wclk[ADDR_WIDTH-2:0]);

	// assign full = ( r_ptr_sync_wclk == {~w_ptr_gray[ADDR_WIDTH:ADDR_WIDTH-1],w_ptr_gray[ADDR_WIDTH-2:0]});

	assign full = (w_ptr_gray[ADDR_WIDTH]   != r_ptr_sync_wclk[ADDR_WIDTH]) &&
              (w_ptr_gray[ADDR_WIDTH-1] != r_ptr_sync_wclk[ADDR_WIDTH-1]) &&
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
		.clk(wr_clk),
		.rst(wr_rst),
		.data_in(r_ptr_gray),
		.data_out(r_ptr_sync_wclk)
	);

	synchronizer #(
		.DATA_WIDTH(ADDR_WIDTH)
	) u_sync_w_to_r (
		.clk(rd_clk),
		.rst(rd_rst),
		.data_in(w_ptr_gray),
		.data_out(w_ptr_sync_rclk)
	);

	assign din_test = din;

endmodule

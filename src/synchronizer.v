
module synchronizer #(
		parameter DATA_WIDTH = 1
	) (
		input  clk,
		input  rst,
		input  [DATA_WIDTH:0] data_in,
		output [DATA_WIDTH:0] data_out
	);

	reg [DATA_WIDTH:0] sync_reg1;
	reg [DATA_WIDTH:0] sync_reg2;
	reg [DATA_WIDTH:0] sync_reg3;

	always @(posedge clk or posedge rst) begin
		if (rst) begin
			sync_reg1 <= 0;
			sync_reg2 <= 0;
			sync_reg3 <= 0;
		end else begin
			sync_reg1 <= data_in;
			sync_reg2 <= sync_reg1;
			sync_reg3 <= sync_reg2;
		end
	end

	assign data_out = sync_reg3;

endmodule
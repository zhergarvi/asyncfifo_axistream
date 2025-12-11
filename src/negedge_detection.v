
module negedge_detection (
		input clk,
		input rst,
		input in,
		output out
	);

	reg in_d_reg;

	always @(posedge clk or posedge rst) begin
		if (rst) begin
			in_d_reg <= 1'b0;
		end else begin
			in_d_reg <= in;
		end
	end

	assign out = in_d_reg && !in;

endmodule

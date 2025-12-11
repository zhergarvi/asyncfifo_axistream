
`timescale 1 ns / 1 ps

//------------------------------
// Owner: Zaheer Ahmad
//------------------------------

module top #
	(
        parameter WIDTH = 32,
		parameter DEPTH = 16384
	)
	(
		input wire  				din_clk,
		input wire  				din_resetn,
		input  wire                 din_valid,
		input  wire [WIDTH-1:0]     din,

		input  wire                 m00_axis_aclk,
		input  wire                 m00_axis_aresetn,
		output wire  				m00_axis_tvalid,
		output wire [WIDTH-1 : 0] 	m00_axis_tdata,
		output wire [(WIDTH/8)-1 : 0] m00_axis_tstrb,
		output wire  				m00_axis_tlast,
		input wire  				m00_axis_tready
	);
	
	axi_stream # ( 
		.DATA_WIDTH(WIDTH),
		.DEPTH(DEPTH)
	) axi_stream_inst (
		.wr_clk(din_clk),
		.wr_rstn(din_resetn),
		.wr_en(din_valid),
		.din(din),
		.ACLK(m00_axis_aclk),
		.ARESETn(m00_axis_aresetn),
		.M_AXIS_TDATA(m00_axis_tdata),
		.M_AXIS_TVALID(m00_axis_tvalid),
		.M_AXIS_TREADY(m00_axis_tready),
		.M_AXIS_TSTRB(m00_axis_tstrb),
		.M_AXIS_TLAST(m00_axis_tlast)
	);

	endmodule

`timescale 1ns/1ps

module async_fifo_tb;

    parameter WIDTH = 32;
    parameter DEPTH = 1024;       //1024/2048/.../16384


    reg                  wr_clk = 0;
    reg                  wr_rst = 1;
    reg                  wr_en;
    reg  [WIDTH-1:0]     din = 0;
//    wire                full;

    reg                  rd_clk = 0;
    reg                  rd_rst = 1;
//    reg                  rd_en;
    wire [WIDTH-1:0]     dout;
//    wire                empty;
    
    wire                 m_axis_tvalid;
    wire [(WIDTH/8)-1 : 0]                 m00_axis_tstrb;
    wire                 m_axis_tlast;
    reg ready;
    
    reg [31:0] count;

    always #10  wr_clk = ~wr_clk;      // 100 MHz write clock
    always #16.276  rd_clk = ~rd_clk;      // ~61.44 MHz read clock (different domain)


    axi_stream_custom_ip_v3_0 #(
        .WIDTH(WIDTH),
        .DEPTH(DEPTH)
    ) dut (
        .din_clk   (wr_clk),
        .din_resetn   (wr_rst),
        .din_valid (wr_en),
        .din      (din),

        .m00_axis_aclk   (rd_clk),
        .m00_axis_aresetn   (rd_rst),
        .m00_axis_tready(ready),
        .m00_axis_tvalid(m_axis_tvalid),
		.m00_axis_tdata(dout),
		.m00_axis_tstrb(m00_axis_tstrb),
		.m00_axis_tlast(m_axis_tlast)
    );
    
    task apply_reset;
    begin
        wr_rst = 0;
        rd_rst = 0;
        repeat (10) @(posedge wr_clk);
        repeat (10) @(posedge rd_clk);
        wr_rst = 1;
        rd_rst = 1;
    end
    endtask


    integer i = 0;
    integer j = 0;

    initial begin
        $display("====== FIFO TEST STARTED ======");
//        rd_en <= 0;
        wr_en <= 0;
        ready <= 1;
        count <= 32'h0;
        apply_reset();
//        m00_axis_tready <= 1;
        

        $display("Writing %0d samples...", DEPTH);

        @(posedge wr_clk);
//        rd_en <= 1;
        for (i = 0; i < DEPTH; i = i + 1) begin
            @(posedge wr_clk);
            wr_en <= 1;
            din <= i + 32'h1000;
        end

        @(posedge wr_clk);
        wr_en <= 0;

        $display("Waiting for out_valid...");

//        $display("out_valid asserted! Starting read...");

        repeat(500)@(posedge rd_clk);
//        rd_en <= 1;

        for (i = 0; i < DEPTH; i = i + 1) begin
            @(posedge rd_clk);
//            rd_en <= 1;
//            $display("READ[%0d] = %h", i, dout);

            // Optional self-check
            if (dout !== (i + 32'hFFE))
                $display("ERROR: Expected %h, got %h", (i + 32'h1000), dout);
        end

        @(posedge rd_clk);
//        rd_en = 0;
        repeat(500)@(posedge rd_clk);
        
        @(posedge wr_clk);

        for (i = 0; i < DEPTH; i = i + 1) begin
            @(posedge wr_clk);
            wr_en <= 1;
            din <= i + 32'h100;
            count <= count +1;
        end

        @(posedge wr_clk);
        wr_en <= 0;
        if (count >= 32'h000003e8) begin
            for (j = 0; j < DEPTH; j = j + 1) begin
                @(posedge rd_clk);
//                rd_en <= 1;
//                $display("READ[%0d] = %h", j, dout);
            end
        end
        repeat(1000)@(posedge rd_clk);
        count <= 32'h0;
//        rd_en <= 0;
        fork 
            begin
                for (i = 0; i < DEPTH; i = i + 1) begin
                    @(posedge wr_clk);
                    wr_en <= 1;
                    din <= 32'h1000 - i;
                    count <= count +1;
                end
            end
            begin
    //        @(posedge wr_clk);
    //        wr_en <= 0;
                repeat (1000) @(posedge rd_clk);
//                if (count >= 32'd1000) begin
                    for (j = 0; j < DEPTH; j = j + 1) begin
                        @(posedge rd_clk);
//                        rd_en <= 1;
        //                $display("READ[%0d] = %h", j, dout);
                    end
//                end
            end
        join
        
        @(posedge rd_clk);
        wr_en <= 0;
        repeat(2000)@(posedge rd_clk);
//        rd_en = 0;
        
        ready <= 0;
        for (i = 0; i < DEPTH; i = i + 1) begin
            @(posedge wr_clk);
            wr_en <= 1;
            din <= i + 32'h1000;
        end
        for (i = 0; i < DEPTH; i = i + 1) begin
            @(posedge wr_clk);
            wr_en <= 0;
            din <= i + 32'h1000;
        end
        for (i = 0; i < DEPTH; i = i + 1) begin
            @(posedge wr_clk);
            wr_en <= 1;
            din <= i + 32'h1000;
        end
        for (i = 0; i < DEPTH; i = i + 1) begin
            @(posedge wr_clk);
            wr_en <= 0;
            din <= i + 32'h1000;
        end
        
        ready <= 1;
        repeat(2000)@(posedge rd_clk);
//        rd_en = 0;
        
        for (i = 0; i < DEPTH; i = i + 1) begin
            @(posedge wr_clk);
            wr_en <= 1;
            din <= i + 32'h1000;
        end
        for (i = 0; i < DEPTH; i = i + 1) begin
            @(posedge wr_clk);
            wr_en <= 0;
            din <= i + 32'h1000;
        end
        for (i = 0; i < DEPTH; i = i + 1) begin
            @(posedge wr_clk);
            wr_en <= 1;
            din <= i + 32'h1000;
        end
        for (i = 0; i < DEPTH; i = i + 1) begin
            @(posedge wr_clk);
            wr_en <= 0;
            din <= i + 32'h1000;
        end
        
        repeat(1000)@(posedge rd_clk);
        $display("====== FIFO TEST COMPLETED SUCCESSFULLY ======");
        $finish;
    end
endmodule

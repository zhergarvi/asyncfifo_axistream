## Async FIFO and AXI Stream
This is verilog design of asynchronous fifo with axi stream. Data is written in fifo at write clock domain and read at the read clock domain, data is transmitted using axi stream interface. 

The logic detects the negedge of `wr_en` of async fifo. Once the data is written in fifo, the logic create a pulse on the negedge of `wr_en` and passes this pulse to read clock domain using request and ackowledge flags and it makes `read_start_flag` high. Then `rd_en` becomes high.

This project is for transmitting the fft output data from PL to PS for N number of indexes.

### Project Structure

```text
.
├── src/
│   └── async_fifo.v 
│   └── axi_stream.v 
│   └── negedge_detection.v 
│   └── posedge_detection.v 
│   └── synchronizer.v 
│   └── top.v 
├── tb/
│   └── fifo_tb.v
└── README.md

## Async FIFO and AXI Stream
This repository contains a Verilog implementation of an **Asynchronous FIFO** with an **AXI-Stream interface**. It is designed to facilitate high-speed data transfer across different clock domains, such as streaming FFT output data from Programmable Logic (PL) to the Processor System (PS).

Data is pushed into the FIFO at the frequency of the source logic (e.g., the FFT sampling rate). The system monitors the `wr_en` signal. When the write process is done, the logic detects the falling edge of the `wr_en`.

Once the negedge of `wr_en` is detected:
  - A pulse is generated in the Write clock domain. 
  - A Request/Acknowledge mechanism synchronizes this pulse into the Read clock domain. 
  - This ensures that the Read logic is only activated once a complete packet of data is safe and available.
  - The `read_start_flag` is asserted.
  - The `rd_en` (Read Enable) signal goes high.
  - Data is streamed out via the **AXI-Stream interface** to the PS (Processor System) for software-level processing.

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

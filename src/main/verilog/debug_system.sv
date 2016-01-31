
module debug_system
  (
   input         clk, rstn,
   
   input         rx,
   output        tx,

   output        uart_irq,

   input [12:0]  uart_ar_addr,
   input         uart_ar_valid,
   output        uart_ar_ready,
    
   output [1:0]  uart_r_resp,
   output [31:0] uart_r_data,
   output        uart_r_valid,
   input         uart_r_ready,

   input [12:0]  uart_aw_addr,
   input         uart_aw_valid,
   output        uart_aw_ready,

   input [31:0]  uart_w_data,
   input         uart_w_valid,
   output        uart_w_ready,

   output [1:0]  uart_b_resp,
   output        uart_b_valid,
   input         uart_b_ready
   );

   logic  rst;
   assign rst = ~rstn;

   assign uart_irq = 0;

   glip_channel #(.WIDTH(16)) fifo_in (.clk(clk));
   glip_channel #(.WIDTH(16)) fifo_out (.clk(clk));
   
   logic  logic_rst, com_rst;
 
   glip_uart_toplevel
     #(.WIDTH(16), .BAUD(3000000), .FREQ(25000000))
   u_glip(.clk_io    (clk),
          .clk_logic (clk),
          .rst       (rst),
          .logic_rst (logic_rst),
          .com_rst   (com_rst),
          .fifo_in_data  (fifo_in.data[15:0]),
          .fifo_in_valid (fifo_in.valid),
          .fifo_in_ready (fifo_in.ready),
          .fifo_out_data  (fifo_out.data[15:0]),
          .fifo_out_valid (fifo_out.valid),
          .fifo_out_ready (fifo_out.ready),
          .uart_rx (rx),
          .uart_tx (tx),
          .uart_cts (1),
          .uart_rts (),
          .error ());

      localparam N = 3;

   /* Modules->Ring */
   dii_channel in_ports [N-1:0] ();
   /* Ring->Modules */
   dii_channel out_ports [N-1:0] ();   
   
   osd_him
     u_him(.*,
           .glip_in  (fifo_in),
           .glip_out (fifo_out),
           .dii_out  (out_ports[0]),
           .dii_in   (in_ports[0]));
   
   osd_scm
     #(.SYSTEMID(16'hdead), .NUM_MOD(N-1))
   u_scm(.*,
         .id (10'd1),
         .debug_in  (in_ports[1]),
         .debug_out (out_ports[1]));

   assign uart_r_data[31:8] = 0;
   
   osd_dem_uart_nasti
     u_uart (.*,
             .id (10'd2),

             .ar_addr (uart_ar_addr[4:2]),
             .ar_valid (uart_ar_valid),
             .ar_ready (uart_ar_ready),
             .r_data (uart_r_data[7:0]),
             .r_valid (uart_r_valid),
             .r_ready (uart_r_ready),
             .r_resp (uart_r_resp),
             .aw_addr (uart_aw_addr[4:2]),
             .aw_valid (uart_aw_valid),
             .aw_ready (uart_aw_ready),
             .w_data (uart_w_data),
             .w_valid (uart_w_valid),
             .w_ready (uart_w_ready),
             .b_valid (uart_b_valid),
             .b_ready (uart_b_ready),
             .b_resp (uart_b_resp),
             
             .debug_in  (in_ports[2]),
             .debug_out (out_ports[2]));
   
   dii_channel #(.N(N)) dii_in ();
   dii_channel #(.N(N)) dii_out ();

   genvar i;
   generate
      for (i = 0; i < N; i++) begin
         assign out_ports[i].ready = dii_out.assemble(out_ports[i].data,
                                                      out_ports[i].last,
                                                      out_ports[i].valid,
                                                      i);
         // here is a bug for Verilator,it cannot recognize in_port[i] as an interface
         //assign dii_in.ready[i] = in_ports[i].assemble(dii_in.data[i],
         //                                              dii_in.last[i],
         //                                              dii_in.valid[i]);
         assign in_ports[i].data = dii_in.data[i];
         assign in_ports[i].last = dii_in.last[i];
         assign in_ports[i].valid = dii_in.valid[i];
         assign dii_in.ready[i] = in_ports[i].ready;
      end
   endgenerate


   debug_ring
     #(.PORTS(N))
   u_ring(.*,
          .dii_in  (dii_out),
          .dii_out (dii_in));

   
endmodule // debug_system


                    

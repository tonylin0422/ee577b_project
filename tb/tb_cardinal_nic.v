// Verilog-2001 testbench. FAIL followed by $finish means failure; require PASS.
`timescale 1ns/1ps
module tb_cardinal_nic;
 reg clk=0,reset=1;always #2 clk=~clk;
 reg [1:0] addr=0;reg [63:0] d_in=0,net_di=0;
 wire [63:0] d_out,net_do;
 reg nicEn=0,nicEnWr=0,net_si=0,net_ro=0,net_polarity=0;
 wire net_ri,net_so;
 cardinal_nic dut(.clk(clk),.reset(reset),.addr(addr),.d_in(d_in),.d_out(d_out),.nicEn(nicEn),.nicEnWr(nicEnWr),.net_si(net_si),.net_ri(net_ri),.net_di(net_di),.net_so(net_so),.net_ro(net_ro),.net_do(net_do),.net_polarity(net_polarity));
 reg [63:0] mi=0,mo=0,read_expected=0;
 reg fi=0,fo=0,send_expected,check_read;
 integer fd,checks=0,cycles=0,sends=0,receives=0;
 integer load_full=0,load_empty=0,store_empty=0,store_full=0;
 integer blocked_ro=0,blocked_phase=0,illegal=0,reset_loaded=0,rx_read=0,tx_write=0;
 integer i;reg [31:0] rng=32'hcafe1234;
 reg [8*64-1:0] label_text="startup";
 task step(input [8*64-1:0] label_in,input rst,input [1:0] a,input en,wr,input [63:0] data,
           input ns,input [63:0] nd,input ready_in,phase);
  begin
   @(negedge clk);label_text=label_in;reset=rst;addr=a;nicEn=en;nicEnWr=wr;d_in=data;
   net_si=ns;net_di=nd;net_ro=ready_in;net_polarity=phase;
   @(posedge clk);#0.02;
  end
 endtask
 always @(posedge clk)begin
  cycles=cycles+1;
  if(reset)begin
   if(fi||fo)reset_loaded=reset_loaded+1;
   fi=0;fo=0;mi=0;mo=0;read_expected=0;check_read=1;
  end else begin
   send_expected=fo && net_ro && (net_polarity!=mo[63]);
   if(net_ri!==!fi || net_so!==send_expected || net_do!==mo)begin $display("FAIL"); $display("NIC handshake/data mismatch %0s",label_text); $finish; end 
   if(net_si && fi)begin $display("FAIL"); $display("Testbench violated receive handshake"); $finish; end 
   if(fo && !net_ro)blocked_ro=blocked_ro+1;
   if(fo && net_ro && net_polarity==mo[63])blocked_phase=blocked_phase+1;
   read_expected=0;check_read=1;
   if(nicEn && !nicEnWr)begin
    case(addr)
     0:begin
      if(fi)begin read_expected=mi;load_full=load_full+1;end
      else begin check_read=0;load_empty=load_empty+1;end // Empty read is unspecified.
      fi=0;
     end
     1:read_expected={63'b0,fi};
     3:read_expected={63'b0,fo};
     default:begin illegal=illegal+1;check_read=0;end // Unsupported read value unspecified.
    endcase
   end
   if(nicEn && nicEnWr)begin
    if(addr==2)begin
     if(fo)store_full=store_full+1;
     else begin fo=1;mo=d_in;store_empty=store_empty+1;end
    end else begin illegal=illegal+1;check_read=0;end
   end
   if(net_si)begin mi=net_di;fi=1;receives=receives+1;if(nicEn&&!nicEnWr&&addr==0)rx_read=rx_read+1;end
   if(send_expected)begin fo=0;sends=sends+1;if(nicEn&&nicEnWr&&addr==2)tx_write=tx_write+1;end
  end
  #0.01;
  if(reset && (net_so!==0 || net_ri!==1))begin $display("FAIL"); $display("NIC reset outputs"); $finish; end 
  if(!nicEn && d_out!==0)begin $display("FAIL"); $display("NIC disabled output nonzero"); $finish; end 
  if(nicEn && check_read && d_out!==read_expected)begin $display("FAIL"); $display("NIC load mismatch %0s expected=%h got=%h",label_text,read_expected,d_out); $finish; end 
  if(dut.input_buffer_full!==fi || dut.output_buffer_full!==fo)begin $display("FAIL"); $display("NIC occupancy mismatch %0s",label_text); $finish; end 
  checks=checks+1;
  $fwrite(fd,"%0d,%0s,%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d,%016h,%016h,%0d,%0d\n",cycles,label_text,reset,addr,nicEn,nicEnWr,net_si,net_ri,net_ro,net_so,net_polarity,d_out,net_do,fi,fo);
 end
 initial begin
  fd=$fopen("nic_evidence.csv","w");if(!fd)begin $display("FAIL"); $display("Cannot open NIC log"); $finish; end 
  $fwrite(fd,"cycle,case_name,reset,addr,nicEn,nicEnWr,net_si,net_ri,net_ro,net_so,polarity,d_out,net_do,input_full,output_full\n");
  // Always save the required NIC waveform, including when run directly.
  $dumpfile("nic.vcd");$dumpvars(0,tb_cardinal_nic);
  step("reset",1,0,0,0,0,0,0,0,0);
  step("load_empty",0,0,1,0,0,0,0,0,0);
  step("receive",0,0,0,0,0,1,64'h1234567812345678,0,0);
  step("receive_blocked_full",0,1,1,0,0,0,0,0,1);
  step("illegal_input_write",0,0,1,1,64'hbad,0,0,0,0);
  step("load_full",0,0,1,0,0,0,0,0,1);
  step("store_empty",0,2,1,1,64'h8000000000000021,0,0,0,0);
  step("store_full_ignored",0,2,1,1,64'hbad,0,0,0,1);
  step("wrong_phase",0,3,1,0,0,0,0,1,1);
  step("send_unblocked",0,3,1,0,0,0,0,1,0);
  step("no_duplicate_send",0,3,1,0,0,0,0,1,0);
  step("store_for_simultaneous",0,2,1,1,64'h0000000000000022,0,0,0,0);
  step("write_full_and_send",0,2,1,1,64'h8000000000000099,0,0,1,1);
  step("check_rejected_replacement",0,3,1,0,0,0,0,1,0);
  step("empty_read_and_arrival",0,0,1,0,0,1,64'h1234000000000055,0,0);
  step("read_retained_arrival",0,0,1,0,0,0,0,0,1);
  step("both_directions",0,2,1,1,64'h8000000000000066,1,64'h1234000000000077,0,1);
  step("reset_with_buffers_full",1,0,0,0,0,0,0,0,0);
  step("post_reset_status",0,1,1,0,0,0,0,1,0);
  for(i=0;i<1000;i=i+1)begin
   rng=rng*32'd1664525+32'd1013904223;
   step("random_legal",0,rng[3:2],rng[4],rng[5],{rng,i},!fi&&rng[6],{~rng,i},rng[7],rng[8]);
  end
  step("final_reset",1,0,0,0,0,0,0,0,0);
  if(!load_full||!load_empty||!store_empty||!store_full||!blocked_ro||!blocked_phase||!illegal||!reset_loaded||!rx_read||!tx_write||!sends||!receives)begin $display("FAIL"); $display("NIC coverage missing"); $finish; end 
  $fclose(fd);fd=$fopen("summary.csv","w");
  $fwrite(fd,"checks,load_full,load_empty,store_empty,store_full,blocked_ready,blocked_phase,illegal_ops,reset_loaded,simultaneous_rx_read,simultaneous_tx_write,sends,receives,errors\n");
  $fwrite(fd,"%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d,0\n",checks,load_full,load_empty,store_empty,store_full,blocked_ro,blocked_phase,illegal,reset_loaded,rx_read,tx_write,sends,receives);
  $display("PASS NIC checks=%0d",checks);$finish;
 end
endmodule

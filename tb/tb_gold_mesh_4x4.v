// Verilog-2001 testbench. FAIL followed by $finish means failure; require PASS.
`timescale 1ns/1ps
module tb_gold_mesh_4x4;
 localparam MAX=40000;
 reg clk=0,reset=1;
 always #2 clk=~clk; // 250 MHz; delays appear in testbench only.
 reg [15:0] si=0,ro=16'hffff;
 wire [15:0] ri,so,pol;
 reg [63:0] di[0:15]; wire [63:0] do_data[0:15];
 gold_mesh_4x4 #(.PACKET_SIZE(64)) dut (.clk(clk), .reset(reset),
    .node0_pesi(si[0]),
    .node0_peri(ri[0]),
    .node0_pedi(di[0]),
    .node0_peso(so[0]),
    .node0_pero(ro[0]),
    .node0_pedo(do_data[0]),
    .node0_polarity(pol[0]),
    .node1_pesi(si[1]),
    .node1_peri(ri[1]),
    .node1_pedi(di[1]),
    .node1_peso(so[1]),
    .node1_pero(ro[1]),
    .node1_pedo(do_data[1]),
    .node1_polarity(pol[1]),
    .node2_pesi(si[2]),
    .node2_peri(ri[2]),
    .node2_pedi(di[2]),
    .node2_peso(so[2]),
    .node2_pero(ro[2]),
    .node2_pedo(do_data[2]),
    .node2_polarity(pol[2]),
    .node3_pesi(si[3]),
    .node3_peri(ri[3]),
    .node3_pedi(di[3]),
    .node3_peso(so[3]),
    .node3_pero(ro[3]),
    .node3_pedo(do_data[3]),
    .node3_polarity(pol[3]),
    .node4_pesi(si[4]),
    .node4_peri(ri[4]),
    .node4_pedi(di[4]),
    .node4_peso(so[4]),
    .node4_pero(ro[4]),
    .node4_pedo(do_data[4]),
    .node4_polarity(pol[4]),
    .node5_pesi(si[5]),
    .node5_peri(ri[5]),
    .node5_pedi(di[5]),
    .node5_peso(so[5]),
    .node5_pero(ro[5]),
    .node5_pedo(do_data[5]),
    .node5_polarity(pol[5]),
    .node6_pesi(si[6]),
    .node6_peri(ri[6]),
    .node6_pedi(di[6]),
    .node6_peso(so[6]),
    .node6_pero(ro[6]),
    .node6_pedo(do_data[6]),
    .node6_polarity(pol[6]),
    .node7_pesi(si[7]),
    .node7_peri(ri[7]),
    .node7_pedi(di[7]),
    .node7_peso(so[7]),
    .node7_pero(ro[7]),
    .node7_pedo(do_data[7]),
    .node7_polarity(pol[7]),
    .node8_pesi(si[8]),
    .node8_peri(ri[8]),
    .node8_pedi(di[8]),
    .node8_peso(so[8]),
    .node8_pero(ro[8]),
    .node8_pedo(do_data[8]),
    .node8_polarity(pol[8]),
    .node9_pesi(si[9]),
    .node9_peri(ri[9]),
    .node9_pedi(di[9]),
    .node9_peso(so[9]),
    .node9_pero(ro[9]),
    .node9_pedo(do_data[9]),
    .node9_polarity(pol[9]),
    .node10_pesi(si[10]),
    .node10_peri(ri[10]),
    .node10_pedi(di[10]),
    .node10_peso(so[10]),
    .node10_pero(ro[10]),
    .node10_pedo(do_data[10]),
    .node10_polarity(pol[10]),
    .node11_pesi(si[11]),
    .node11_peri(ri[11]),
    .node11_pedi(di[11]),
    .node11_peso(so[11]),
    .node11_pero(ro[11]),
    .node11_pedo(do_data[11]),
    .node11_polarity(pol[11]),
    .node12_pesi(si[12]),
    .node12_peri(ri[12]),
    .node12_pedi(di[12]),
    .node12_peso(so[12]),
    .node12_pero(ro[12]),
    .node12_pedo(do_data[12]),
    .node12_polarity(pol[12]),
    .node13_pesi(si[13]),
    .node13_peri(ri[13]),
    .node13_pedi(di[13]),
    .node13_peso(so[13]),
    .node13_pero(ro[13]),
    .node13_pedo(do_data[13]),
    .node13_polarity(pol[13]),
    .node14_pesi(si[14]),
    .node14_peri(ri[14]),
    .node14_pedi(di[14]),
    .node14_peso(so[14]),
    .node14_pero(ro[14]),
    .node14_pedo(do_data[14]),
    .node14_polarity(pol[14]),
    .node15_pesi(si[15]),
    .node15_peri(ri[15]),
    .node15_pedi(di[15]),
    .node15_peso(so[15]),
    .node15_pero(ro[15]),
    .node15_pedo(do_data[15]),
    .node15_polarity(pol[15])
);

 integer cycle=0, next_id=0, injected=0, delivered=0, aborted=0, outstanding=0;
 integer stall_fd,occ_fd,pkt_fd,event_fd,summary_fd,phase_fd,reset_fd;
 integer gather_fd[0:15];
 reg [8*64-1:0] gather_filename;
 reg [63:0] expected[0:MAX-1];
 integer state[0:MAX-1],release_cycle[0:MAX-1],inject_cycle[0:MAX-1];
 integer src[0:MAX-1],dest[0:MAX-1],vchan[0:MAX-1];
 integer base_id[0:15],seq[0:15];
 integer count=64,seed=1,load_pct=40,stall_cycles=0,sink=6,vc_mode=-1;
 integer seed_arg,start_cycle,release_edge=-1,last_delivery=-1,first_inject=-1,expected_total;
 reg [8*32-1:0] scenario="gather";
 integer s,d,v,k,id,n,t,phase_start,phase_start_ns,h,latency;
 reg [31:0] rng=1,ro_rng=1;
 reg [15:0] ready_pattern;
 `define ROUTER cardinal_router_inst
genvar gx, gy;
generate for (gx=0;gx<4;gx=gx+1) begin: probe_x
 for (gy=0;gy<4;gy=gy+1) begin: probe_y
router_probe #(.NODE(gx+4*gy)) probe (.clk(clk),.reset(reset),.polarity(pol[gx+4*gy]),.cycle(cycle),.event_fd(stall_fd),.occupancy_fd(occ_fd),
.requests({dut.genrow[gx].gencol[gy].`ROUTER.pe_input_controller_inst.request,dut.genrow[gx].gencol[gy].`ROUTER.w_input_controller_inst.request,dut.genrow[gx].gencol[gy].`ROUTER.s_input_controller_inst.request,dut.genrow[gx].gencol[gy].`ROUTER.e_input_controller_inst.request,dut.genrow[gx].gencol[gy].`ROUTER.n_input_controller_inst.request}),
.grants({dut.genrow[gx].gencol[gy].`ROUTER.pe_input_controller_inst.grant,dut.genrow[gx].gencol[gy].`ROUTER.w_input_controller_inst.grant,dut.genrow[gx].gencol[gy].`ROUTER.s_input_controller_inst.grant,dut.genrow[gx].gencol[gy].`ROUTER.e_input_controller_inst.grant,dut.genrow[gx].gencol[gy].`ROUTER.n_input_controller_inst.grant}),
.in_full({dut.genrow[gx].gencol[gy].`ROUTER.pe_input_controller_inst.full_odd,dut.genrow[gx].gencol[gy].`ROUTER.pe_input_controller_inst.full_even,dut.genrow[gx].gencol[gy].`ROUTER.w_input_controller_inst.full_odd,dut.genrow[gx].gencol[gy].`ROUTER.w_input_controller_inst.full_even,dut.genrow[gx].gencol[gy].`ROUTER.s_input_controller_inst.full_odd,dut.genrow[gx].gencol[gy].`ROUTER.s_input_controller_inst.full_even,dut.genrow[gx].gencol[gy].`ROUTER.e_input_controller_inst.full_odd,dut.genrow[gx].gencol[gy].`ROUTER.e_input_controller_inst.full_even,dut.genrow[gx].gencol[gy].`ROUTER.n_input_controller_inst.full_odd,dut.genrow[gx].gencol[gy].`ROUTER.n_input_controller_inst.full_even}),
.out_full({dut.genrow[gx].gencol[gy].`ROUTER.pe_output_controller_inst.full_odd,dut.genrow[gx].gencol[gy].`ROUTER.pe_output_controller_inst.full_even,dut.genrow[gx].gencol[gy].`ROUTER.w_output_controller_inst.full_odd,dut.genrow[gx].gencol[gy].`ROUTER.w_output_controller_inst.full_even,dut.genrow[gx].gencol[gy].`ROUTER.s_output_controller_inst.full_odd,dut.genrow[gx].gencol[gy].`ROUTER.s_output_controller_inst.full_even,dut.genrow[gx].gencol[gy].`ROUTER.e_output_controller_inst.full_odd,dut.genrow[gx].gencol[gy].`ROUTER.e_output_controller_inst.full_even,dut.genrow[gx].gencol[gy].`ROUTER.n_output_controller_inst.full_odd,dut.genrow[gx].gencol[gy].`ROUTER.n_output_controller_inst.full_even}),
.in_packets({dut.genrow[gx].gencol[gy].`ROUTER.pe_input_controller_inst.packet_out,dut.genrow[gx].gencol[gy].`ROUTER.w_input_controller_inst.packet_out,dut.genrow[gx].gencol[gy].`ROUTER.s_input_controller_inst.packet_out,dut.genrow[gx].gencol[gy].`ROUTER.e_input_controller_inst.packet_out,dut.genrow[gx].gencol[gy].`ROUTER.n_input_controller_inst.packet_out}),
.out_packets({dut.genrow[gx].gencol[gy].`ROUTER.pe_output_controller_inst.data_out,dut.genrow[gx].gencol[gy].`ROUTER.w_output_controller_inst.data_out,dut.genrow[gx].gencol[gy].`ROUTER.s_output_controller_inst.data_out,dut.genrow[gx].gencol[gy].`ROUTER.e_output_controller_inst.data_out,dut.genrow[gx].gencol[gy].`ROUTER.n_output_controller_inst.data_out}),
.out_ready({dut.genrow[gx].gencol[gy].`ROUTER.pe_output_controller_inst.ro,dut.genrow[gx].gencol[gy].`ROUTER.w_output_controller_inst.ro,dut.genrow[gx].gencol[gy].`ROUTER.s_output_controller_inst.ro,dut.genrow[gx].gencol[gy].`ROUTER.e_output_controller_inst.ro,dut.genrow[gx].gencol[gy].`ROUTER.n_output_controller_inst.ro}));
end end endgenerate
`undef ROUTER

 function integer distance(input integer a,b);
  integer x,y;begin x=(a%4)-(b%4);y=(a/4)-(b/4);distance=(x<0?-x:x)+(y<0?-y:y);end
 endfunction
 function [31:0] random_next(input [31:0] old);
  begin random_next=old*32'd1664525+32'd1013904223;end
 endfunction
 task allocate(input integer a,b,vc,r,output integer ident);
  integer hops; reg [63:0] packet;
  begin
   if(a==b) begin $display("FAIL"); $display("Self traffic is outside the project contract"); $finish; end 
   if(next_id>=MAX) begin $display("FAIL"); $display("Increase scoreboard MAX"); $finish; end 
   ident=next_id;next_id=next_id+1;hops=distance(a,b);packet=0;
   packet[63]=vc;packet[61:60]=b%4;packet[59:58]=b/4;
   packet[55:48]=(1<<hops)-1;packet[47:32]=a;packet[31:0]=ident;
   expected[ident]=packet;state[ident]=0;src[ident]=a;dest[ident]=b;vchan[ident]=vc;release_cycle[ident]=r;
  end
 endtask
 task send_one(input integer ident);
  begin
   @(negedge clk);si=0;
   while(!ri[src[ident]] || pol[src[ident]]==vchan[ident]) @(negedge clk);
   di[src[ident]]=expected[ident];si[src[ident]]=1;
   @(negedge clk);si=0;
  end
 endtask
 task drain;
  integer waited;
  begin waited=0;while(outstanding>0) begin @(negedge clk);waited=waited+1;if(waited>20000)begin $display("FAIL"); $display("Drain timeout: %0d packets remain",outstanding); $finish; end end
   repeat(8) @(negedge clk); // Catch late duplicate deliveries.
  end
 endtask
 task reset_network;
  begin
   @(negedge clk);reset=1;si=0;
   repeat(3) @(negedge clk);
   reset=0;ro=16'hffff;
  end
 endtask
 always @(posedge clk) begin : scoreboard
  integer j,p,dh,L;
  cycle<=cycle+1;
  if(cycle>250000) begin $display("FAIL"); $display("Global watchdog"); $finish; end 
  if(reset) begin
   for(j=0;j<next_id;j=j+1) if(state[j]==1) begin
    state[j]=3;aborted=aborted+1;outstanding=outstanding-1;
    $fwrite(event_fd,"%0d,reset_discard,%0d,%0d\n",cycle,src[j],j);
   end
   #0.01;
   if(so!==16'b0 || ri!==16'hffff || pol!==16'b0) begin $display("FAIL"); $display("Reset state mismatch"); $finish; end 
   $fwrite(reset_fd,"%0d,%h,%h,%h\n",cycle,so,ri,pol);
  end else begin
   if((^so)===1'bx || (^ri)===1'bx || (^pol)===1'bx) begin $display("FAIL"); $display("Unknown PE handshake"); $finish; end 
   if(pol!={16{pol[0]}}) begin $display("FAIL"); $display("Polarity desynchronization"); $finish; end 
   if((so & ~ro)!=0) begin $display("FAIL"); $display("Send without receiver readiness"); $finish; end 
   for(j=0;j<16;j=j+1) if(si[j]) begin
    if(!ri[j] || di[j][63]!==!pol[j]) begin $display("FAIL"); $display("Invalid injection source=%0d",j); $finish; end 
    p=di[j][31:0];if(p<0 || p>=next_id)begin $display("FAIL"); $display("Unknown injection ID"); $finish; end 
    if(state[p]!=0 || src[p]!=j || di[j]!==expected[p])begin $display("FAIL"); $display("Injection bookkeeping mismatch"); $finish; end 
    state[p]=1;inject_cycle[p]=cycle;injected=injected+1;outstanding=outstanding+1;
    if(first_inject<0)first_inject=cycle;
    $fwrite(event_fd,"%0d,inject,%0d,%0d\n",cycle,j,p);
   end
   for(j=0;j<16;j=j+1) if(so[j]) begin
    if((^do_data[j])===1'bx)begin $display("FAIL"); $display("Unknown delivered data"); $finish; end 
    p=do_data[j][31:0];if(p<0 || p>=next_id)begin $display("FAIL"); $display("Unknown delivered ID=%0d",p); $finish; end 
    if(state[p]!=1)begin $display("FAIL"); $display("Duplicate, unexpected, or reset-discarded ID=%0d state=%0d",p,state[p]); $finish; end 
    if(dest[p]!=j)begin $display("FAIL"); $display("Wrong destination ID=%0d expected=%0d actual=%0d",p,dest[p],j); $finish; end 
    if((do_data[j] & 64'hff00ffffffffffff)!==(expected[p] & 64'hff00ffffffffffff))begin $display("FAIL"); $display("Corruption ID=%0d",p); $finish; end 
    if(do_data[j][63]!==!pol[j])begin $display("FAIL"); $display("Delivered on wrong VC phase"); $finish; end 
    L=cycle-inject_cycle[p];dh=distance(src[p],dest[p]);
    if(scenario=="latency" && L!=2*(dh+1))begin $display("FAIL"); $display("Unloaded latency wrong: ID=%0d H=%0d L=%0d",p,dh,L); $finish; end 
    state[p]=2;delivered=delivered+1;outstanding=outstanding-1;last_delivery=cycle;
    $fwrite(pkt_fd,"%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d\n",p,src[p],dest[p],vchan[p],release_cycle[p],inject_cycle[p],cycle,L,inject_cycle[p]-release_cycle[p],dh,2*(dh+1),L-2*(dh+1));
    $fwrite(event_fd,"%0d,deliver,%0d,%0d\n",cycle,j,p);
    if(scenario=="gather")$fwrite(gather_fd[j],"Phase=%0d Time=%0t Destination=%0d Source=%0d Packet Value=%016h\n",j,$time,j,src[p],do_data[j]);
   end
  end
 end
 initial begin
  $timeformat(-9,0," ns",10);
  for(n=0;n<16;n=n+1)di[n]=0;
  if($value$plusargs("SCENARIO=%s",scenario))begin end
  if($value$plusargs("COUNT=%d",count))begin end
  if($value$plusargs("SEED=%d",seed))begin end
  if($value$plusargs("LOAD=%d",load_pct))begin end
  if($value$plusargs("STALL=%d",stall_cycles))begin end
  if($value$plusargs("VC=%d",vc_mode))begin end
  if(count<1 || count>2000 || load_pct<1 || load_pct>100 || stall_cycles<0)begin $display("FAIL"); $display("Bad configuration"); $finish; end 
  if(scenario!="latency" && scenario!="gather" && scenario!="uniform" && scenario!="uniform_blocked" && scenario!="hotspot" && scenario!="transpose" && scenario!="reset")begin $display("FAIL"); $display("Unknown scenario"); $finish; end 
  if(vc_mode < -1 || vc_mode>1)begin $display("FAIL"); $display("VC must be -1, 0, or 1"); $finish; end 
  rng=seed;ro_rng=seed ^ 32'h9e3779b9;
  stall_fd=$fopen("stalls.csv","w");occ_fd=$fopen("occupancy.csv","w");pkt_fd=$fopen("packets.csv","w");event_fd=$fopen("events.csv","w");phase_fd=$fopen("start_end_time.out","w");reset_fd=$fopen("reset.csv","w");
  if(!stall_fd || !occ_fd || !pkt_fd || !event_fd || !phase_fd || !reset_fd)begin $display("FAIL"); $display("Cannot open result files"); $finish; end 
  $fwrite(stall_fd,"cycle,node,input_port,output_port,vc,id,reason\n");$fwrite(occ_fd,"cycle,node,occupied_buffers\n");
  $fwrite(pkt_fd,"id,source,destination,vc,release_cycle,inject_cycle,deliver_cycle,mesh_latency,source_wait,hops,baseline_cycles,excess_cycles\n");
  $fwrite(event_fd,"cycle,event,node,id\n");$fwrite(reset_fd,"cycle,peso,peri,polarity\n");
  if(scenario=="gather")for(n=0;n<16;n=n+1)begin $sformat(gather_filename,"gather_phase%0d.res",n); gather_fd[n]=$fopen(gather_filename,"w");if(!gather_fd[n])begin $display("FAIL"); $display("Cannot open gather log"); $finish; end end
  if($test$plusargs("WAVES"))begin $dumpfile("mesh.vcd");$dumpvars(0,tb_gold_mesh_4x4);end
  reset_network();start_cycle=cycle;
  if(scenario=="latency")begin
   for(s=0;s<16;s=s+1)for(d=0;d<16;d=d+1)if(s!=d)for(v=0;v<2;v=v+1)begin
    allocate(s,d,v,cycle,id);send_one(id);drain();
   end
  end else if(scenario=="gather")begin
   for(d=0;d<16;d=d+1)begin
    phase_start=cycle;phase_start_ns=$time;
    for(s=0;s<16;s=s+1)if(s!=d)allocate(s,d,(s+d)%2,cycle,base_id[s]);
    for(s=0;s<16;s=s+1)seq[s]=(s==d);
    t=0;
    while(t<15)begin
     @(negedge clk);si=0;
     for(s=0;s<16;s=s+1)if(!seq[s] && ri[s] && pol[s]!=vchan[base_id[s]])begin
      si[s]=1;di[s]=expected[base_id[s]];seq[s]=1;t=t+1;
     end
    end
    @(negedge clk);si=0;drain();
    $fwrite(phase_fd,"Phase=%0d StartCycle=%0d EndCycle=%0d StartTime_ns=%0d EndTime_ns=%0d\n",d,phase_start,last_delivery,phase_start_ns,2+4*last_delivery);
   end
  end else if(scenario=="reset")begin
   ro=0;
   for(s=0;s<16;s=s+1)if(s!=sink)begin allocate(s,sink,s%2,cycle,id);send_one(id);end
   repeat(30)@(negedge clk);
   if(outstanding==0)begin $display("FAIL"); $display("Reset test did not create in-flight traffic"); $finish; end 
   reset_network();
   for(s=0;s<16;s=s+1)begin allocate(s,(s+5)%16,s%2,cycle,id);send_one(id);end
   drain();if(aborted!=15)begin $display("FAIL"); $display("Reset expected 15 discarded packets, got %0d",aborted); $finish; end 
  end else begin
   // Precompute identical offered traffic independent of readiness and stall duration.
   // Each source has an unbounded-in-TB queue of COUNT packets with geometric gaps.
   for(s=0;s<16;s=s+1)begin
    base_id[s]=next_id;seq[s]=0;t=start_cycle+1;
    for(k=0;k<count;k=k+1)begin
     rng=random_next(rng);while((rng%100)>=load_pct)begin t=t+1;rng=random_next(rng);end
     rng=random_next(rng);d=rng%15;if(d>=s)d=d+1;
     if(scenario=="hotspot")begin d=sink;if(s==sink)d=9;end
     if(scenario=="transpose")begin d=(s%4)*4+s/4;if(d==s)d=(s+1)%16;end
     v=(vc_mode<0)?k%2:vc_mode;
     allocate(s,d,v,t,id);t=t+1;
    end
   end
   expected_total=next_id;
   while(delivered<expected_total)begin
    @(negedge clk);si=0;ro=16'hffff;
    if(scenario=="hotspot" && cycle<start_cycle+stall_cycles)ro[sink]=0;
    if(scenario=="uniform_blocked")for(n=0;n<16;n=n+1)begin
     ro_rng=random_next(ro_rng);ro[n]=(ro_rng[23:22]!=0);
    end
    if(stall_cycles>0 && release_edge<0 && cycle>=start_cycle+stall_cycles)release_edge=cycle;
    for(s=0;s<16;s=s+1)if(seq[s]<count)begin
     id=base_id[s]+seq[s];
     if(cycle>=release_cycle[id] && ri[s] && pol[s]!=vchan[id])begin
      si[s]=1;di[s]=expected[id];seq[s]=seq[s]+1;
     end
    end
   end
   @(negedge clk);si=0;drain();
  end
  if(outstanding!=0 || injected!=delivered+aborted)begin $display("FAIL"); $display("Final scoreboard mismatch"); $finish; end 
  for(n=0;n<next_id;n=n+1)if(state[n]!=2 && state[n]!=3)begin $display("FAIL"); $display("Planned packet not completed: %0d",n); $finish; end 
  summary_fd=$fopen("summary.csv","w");
  $fwrite(summary_fd,"scenario,seed,count,load_pct,stall_cycles,vc_mode,injected,delivered,reset_discarded,errors,first_inject,last_delivery,release_edge\n");
  $fwrite(summary_fd,"%0s,%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d,0,%0d,%0d,%0d\n",scenario,seed,count,load_pct,stall_cycles,vc_mode,injected,delivered,aborted,first_inject,last_delivery,release_edge);
  $display("PASS mesh %0s injected=%0d delivered=%0d reset_discarded=%0d",scenario,injected,delivered,aborted);
  $finish;
 end
endmodule

`timescale 1ns/1ps
// Read-only RTL probes. Port order N=0 E=1 S=2 W=3 PE=4.
module router_probe #(parameter NODE=0)(
 input clk, reset, polarity,
 input signed [31:0] cycle,event_fd,occupancy_fd,
 input [24:0] requests,grants,
 input [9:0] in_full,out_full,
 input [319:0] in_packets,out_packets,
 input [4:0] out_ready
);
 integer i,j,occupancy; reg [4:0] req,gnt; reg [63:0] pkt;
 always @(posedge clk) if (!reset && event_fd!=0) begin
  occupancy=0;
  for(i=0;i<10;i=i+1) occupancy=occupancy+in_full[i]+out_full[i];
  $fwrite(occupancy_fd,"%0d,%0d,%0d\n",cycle,NODE,occupancy);
  for(i=0;i<5;i=i+1) begin
   req=requests[i*5+:5];gnt=grants[i*5+:5];pkt=in_packets[i*64+:64];
   if ((^req)===1'bx || (^gnt)===1'bx) begin $display("FAIL"); $display("Unknown request/grant node=%0d port=%0d",NODE,i); $finish; end 
   if ((gnt & ~req)!=0 || ((gnt & (gnt-1))!=0)) begin $display("FAIL"); $display("Invalid grant node=%0d port=%0d",NODE,i); $finish; end 
   if (|req && !(|gnt)) begin
    for(j=0;j<5;j=j+1) if(req[j]) begin
     if(out_full[2*j+polarity])
      $fwrite(event_fd,"%0d,%0d,%0d,%0d,%0d,%0d,output_full\n",cycle,NODE,i,j,polarity,pkt[31:0]);
     else
      $fwrite(event_fd,"%0d,%0d,%0d,%0d,%0d,%0d,arbitration\n",cycle,NODE,i,j,polarity,pkt[31:0]);
    end
   end
   pkt=out_packets[i*64+:64];
   if(out_full[2*i+(!polarity)] && !out_ready[i])
    $fwrite(event_fd,"%0d,%0d,%0d,%0d,%0d,%0d,downstream_blocked\n",cycle,NODE,i,i,!polarity,pkt[31:0]);
  end
 end
endmodule

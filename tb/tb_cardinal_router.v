`timescale 1ns/1ps
// Verilog-2001. No includes. Default DUT is cardinal_router at (1,1).
// Define SYNTHESIS_RTL only when compiling the alternative gold_router source.
// FAIL + $finish means failure. Require the final PASS and fresh summary.csv.
module tb_cardinal_router;
    localparam N=0, E=1, S=2, W=3, PE=4, MAX_PACKETS=8192;
    reg clk=0, reset=1;
    always #2 clk=~clk;
    reg [4:0] si=0, ready_ctl=5'b11111;
    wire [4:0] ri, so, ro;
    reg [63:0] di[0:4];
    wire [63:0] data_out[0:4];
    wire polarity;
    reg link_mode=0, peer_ready=1;
    wire peer_wri, peer_so, peer_polarity;
    wire [63:0] peer_data;
    assign ro={ready_ctl[4:2],(link_mode ? peer_wri : ready_ctl[E]),ready_ctl[N]};
    `ifdef SYNTHESIS_RTL
    gold_router
`else
    cardinal_router
`endif
    #(.X(1),.Y(1)) dut (
        .clk(clk),
        .reset(reset),
        .polarity(polarity),
        .nsi(si[0]),
        .ndi(di[0]),
        .nri(ri[0]),
        .nro(ro[0]),
        .nso(so[0]),
        .ndo(data_out[0]),
        .esi(si[1]),
        .edi(di[1]),
        .eri(ri[1]),
        .ero(ro[1]),
        .eso(so[1]),
        .edo(data_out[1]),
        .ssi(si[2]),
        .sdi(di[2]),
        .sri(ri[2]),
        .sro(ro[2]),
        .sso(so[2]),
        .sdo(data_out[2]),
        .wsi(si[3]),
        .wdi(di[3]),
        .wri(ri[3]),
        .wro(ro[3]),
        .wso(so[3]),
        .wdo(data_out[3]),
        .pesi(si[4]),
        .pedi(di[4]),
        .peri(ri[4]),
        .pero(ro[4]),
        .peso(so[4]),
        .pedo(data_out[4])
    );
`ifdef SYNTHESIS_RTL
    gold_router
`else
    cardinal_router
`endif
    #(.X(2),.Y(1)) neighbor (
        .clk(clk),
        .reset(reset),
        .polarity(peer_polarity),
        .nsi(1'b0),
        .ndi(64'b0),
        .nri(),
        .nro(1'b1),
        .nso(),
        .ndo(),
        .esi(1'b0),
        .edi(64'b0),
        .eri(),
        .ero(1'b1),
        .eso(),
        .edo(),
        .ssi(1'b0),
        .sdi(64'b0),
        .sri(),
        .sro(1'b1),
        .sso(),
        .sdo(),
        .wsi((link_mode && so[E])),
        .wdi(data_out[E]),
        .wri(peer_wri),
        .wro(1'b1),
        .wso(),
        .wdo(),
        .pesi(1'b0),
        .pedi(64'b0),
        .peri(),
        .pero(peer_ready),
        .peso(peer_so),
        .pedo(peer_data)
    );

    // Read-only probes for the assembled DUT. The independent model below
    // predicts these values; it does not use DUT grants to choose winners.
    wire [4:0] in_request[0:4], in_grant[0:4];
    wire [3:0] out_request[0:4], out_grant[0:4];
    wire [1:0] priority_even[0:4], priority_odd[0:4];
    wire [9:0] input_full, output_full;
    assign in_request[0]=dut.n_input_controller_inst.request;
    assign in_grant[0]=dut.n_input_controller_inst.grant;
    assign out_request[0]=dut.n_output_controller_inst.request;
    assign out_grant[0]=dut.n_output_controller_inst.grant;
    assign priority_even[0]=dut.n_output_controller_inst.priority_even;
    assign priority_odd[0]=dut.n_output_controller_inst.priority_odd;
    assign input_full[0+:2]={dut.n_input_controller_inst.full_odd,dut.n_input_controller_inst.full_even};
    assign output_full[0+:2]={dut.n_output_controller_inst.full_odd,dut.n_output_controller_inst.full_even};
    assign in_request[1]=dut.e_input_controller_inst.request;
    assign in_grant[1]=dut.e_input_controller_inst.grant;
    assign out_request[1]=dut.e_output_controller_inst.request;
    assign out_grant[1]=dut.e_output_controller_inst.grant;
    assign priority_even[1]=dut.e_output_controller_inst.priority_even;
    assign priority_odd[1]=dut.e_output_controller_inst.priority_odd;
    assign input_full[2+:2]={dut.e_input_controller_inst.full_odd,dut.e_input_controller_inst.full_even};
    assign output_full[2+:2]={dut.e_output_controller_inst.full_odd,dut.e_output_controller_inst.full_even};
    assign in_request[2]=dut.s_input_controller_inst.request;
    assign in_grant[2]=dut.s_input_controller_inst.grant;
    assign out_request[2]=dut.s_output_controller_inst.request;
    assign out_grant[2]=dut.s_output_controller_inst.grant;
    assign priority_even[2]=dut.s_output_controller_inst.priority_even;
    assign priority_odd[2]=dut.s_output_controller_inst.priority_odd;
    assign input_full[4+:2]={dut.s_input_controller_inst.full_odd,dut.s_input_controller_inst.full_even};
    assign output_full[4+:2]={dut.s_output_controller_inst.full_odd,dut.s_output_controller_inst.full_even};
    assign in_request[3]=dut.w_input_controller_inst.request;
    assign in_grant[3]=dut.w_input_controller_inst.grant;
    assign out_request[3]=dut.w_output_controller_inst.request;
    assign out_grant[3]=dut.w_output_controller_inst.grant;
    assign priority_even[3]=dut.w_output_controller_inst.priority_even;
    assign priority_odd[3]=dut.w_output_controller_inst.priority_odd;
    assign input_full[6+:2]={dut.w_input_controller_inst.full_odd,dut.w_input_controller_inst.full_even};
    assign output_full[6+:2]={dut.w_output_controller_inst.full_odd,dut.w_output_controller_inst.full_even};
    assign in_request[4]=dut.pe_input_controller_inst.request;
    assign in_grant[4]=dut.pe_input_controller_inst.grant;
    assign out_request[4]=dut.pe_output_controller_inst.request;
    assign out_grant[4]=dut.pe_output_controller_inst.grant;
    assign priority_even[4]=dut.pe_output_controller_inst.priority_even;
    assign priority_odd[4]=dut.pe_output_controller_inst.priority_odd;
    assign input_full[8+:2]={dut.pe_input_controller_inst.full_odd,dut.pe_input_controller_inst.full_even};
    assign output_full[8+:2]={dut.pe_output_controller_inst.full_odd,dut.pe_output_controller_inst.full_even};

    reg [8*64-1:0] label_text="startup";
    reg [8*64-1:0] next_label;
    integer case_id=0, case_kind=0, case_start_ns=0;
    integer case_injected=0, case_delivered=0, case_discarded=0;
    integer cycle=0, checks=0, next_id=0, injected=0, delivered=0, discarded=0;
    integer root_transfers=0, linked_deliveries=0, simultaneous_outputs=0;
    integer link_blocked_samples=0, loaded_resets=0;
    integer case_fd, event_fd, arb_fd, coverage_fd, summary_fd;
    integer packets_pending=0;
    reg [63:0] expected[0:MAX_PACKETS-1];
    integer state[0:MAX_PACKETS-1], input_port[0:MAX_PACKETS-1];
    integer expected_port[0:MAX_PACKETS-1], injection_cycle[0:MAX_PACKETS-1];
    integer path_linked[0:MAX_PACKETS-1];

    // Reference storage: index = 2*port + VC. State belongs to the model.
    reg model_in_full[0:9], model_out_full[0:9];
    reg [63:0] model_in_packet[0:9], model_out_packet[0:9];
    integer model_priority[0:9];
    reg [4:0] want_in_request[0:4], want_in_grant[0:4];
    integer route_hits[0:49], full_contention_hits[0:9];
    integer start_priority_hits[0:39], blocked_input_hits[0:9];
    integer blocked_output_hits[0:9], hop_hits[0:255];
    integer sent_per_input[0:4];
    reg [31:0] rng=32'h577b2026;
    integer p,o,v,k,round_no,id,hop,covered_routes,covered_priorities;

    function integer route;
        input [63:0] packet;
        begin
            if (packet[61:60]>1) route=E;
            else if (packet[61:60]<1) route=W;
            else if (packet[59:58]>1) route=S;
            else if (packet[59:58]<1) route=N;
            else route=PE;
        end
    endfunction

    // The four local arbiter slots map to ascending input port numbers,
    // excluding the output's own port (no U-turn / PE loopback).
    function integer slot_port;
        input integer output_index, slot_index;
        begin slot_port=(slot_index<output_index)?slot_index:slot_index+1; end
    endfunction

    task fail;
        input [8*160-1:0] message;
        begin
            $display("FAIL router case=%0s cycle=%0d time=%0t: %0s",label_text,cycle,$time,message);
            $finish;
        end
    endtask

    task begin_case;
        input [8*64-1:0] name;
        input integer kind;
        begin
            if(packets_pending!=0) fail("Previous case has pending packets");
            label_text=name;case_kind=kind;case_id=case_id+1;
            case_start_ns=$time;case_injected=injected;
            case_delivered=delivered;case_discarded=discarded;
        end
    endtask

    task end_case;
        begin
            if(packets_pending!=0) fail("Case did not drain");
            $fwrite(case_fd,"%0d,%0s,%0d,%0d,%0d,%0d,%0d,%0d\n",
                case_id,label_text,case_kind,case_start_ns,$time,
                injected-case_injected,delivered-case_delivered,discarded-case_discarded);
        end
    endtask

    task allocate;
        input integer ip,op,vc,hop_value;
        output integer ident;
        reg [63:0] packet;
        integer dx,dy;
        begin
            if(ip==op) fail("Test attempted an unsupported U-turn or PE loopback");
            if(next_id>=MAX_PACKETS) fail("Increase MAX_PACKETS");
            ident=next_id;next_id=next_id+1;
            dx=1;dy=1;
            case(op) N:dy=0; E:dx=2; S:dy=2; W:dx=0; endcase
            packet=0;packet[63]=vc;packet[61:60]=dx;packet[59:58]=dy;
            packet[55:48]=hop_value;
            case(ip)
                N:packet[47:32]=1; E:packet[47:32]=6;
                S:packet[47:32]=9; W:packet[47:32]=4; PE:packet[47:32]=5;
            endcase
            packet[31:16]=16'ha5a5 ^ ident;packet[15:0]=ident;
            expected[ident]=packet;state[ident]=0;
            input_port[ident]=ip;expected_port[ident]=op;path_linked[ident]=link_mode;
        end
    endtask

    task inject_id;
        input integer ident;
        integer ip,waited;
        begin
            ip=input_port[ident];waited=0;
            @(negedge clk);si=0;
            while(!ri[ip] || polarity==expected[ident][63]) begin
                @(negedge clk);waited=waited+1;
                if(waited>4000) fail("Injection timeout");
            end
            di[ip]=expected[ident];si[ip]=1;
            @(negedge clk);si=0;
        end
    endtask

    task drain;
        integer waited;
        begin
            waited=0;
            while(packets_pending>0) begin
                @(negedge clk);waited=waited+1;
                if(waited>4000) fail("Drain timeout: packet loss or deadlock");
            end
            repeat(6) @(negedge clk); // Also catch late duplicates.
        end
    endtask

    task apply_reset;
        reg [9:0] previous_in,previous_out;
        begin
            @(negedge clk);si=0;
            previous_in=input_full;previous_out=output_full;
            reset=1;
            #0.01;
            // State must not clear between clock edges. Combinational
            // handshake qualification during reset is allowed to differ.
            if(input_full!==previous_in || output_full!==previous_out)
                fail("Buffer occupancy changed asynchronously with reset");
            repeat(3) @(negedge clk);
            reset=0;ready_ctl=31;peer_ready=1;
        end
    endtask

    task inject_four;
        input integer op,vc;
        integer j,ident,waited;
        reg [4:0] mask;
        begin
            mask=5'b11111 ^ (5'b00001<<op);waited=0;
            @(negedge clk);si=0;
            while((ri & mask)!=mask || polarity==vc) begin
                @(negedge clk);waited=waited+1;
                if(waited>4000) fail("Four-input injection timeout");
            end
            for(j=0;j<5;j=j+1) if(j!=op) begin
                allocate(j,op,vc,1,ident);di[j]=expected[ident];
            end
            si=mask;
            @(negedge clk);si=0;
        end
    endtask

    // Every rising edge: end-to-end scoreboard and independent cycle model.
    always @(posedge clk) begin : monitor
        integer a,b,c,q,vc,ext,idx,target,count,selected,actual_id;
        integer prior_before,parallel_count,in_count,out_count;
        reg [3:0] req,want;
        reg expected_send;
        cycle<=cycle+1;
        if(cycle>100000) fail("Global watchdog");
        if(reset) begin
            in_count=0;out_count=0;
            for(a=0;a<10;a=a+1) begin
                if(model_in_full[a]===1'b1) in_count=in_count+1;
                if(model_out_full[a]===1'b1) out_count=out_count+1;
                model_in_full[a]=0;model_out_full[a]=0;model_priority[a]=0;
                model_in_packet[a]=0;model_out_packet[a]=0;
            end
            if(in_count>0 && out_count>0) loaded_resets=loaded_resets+1;
            for(a=0;a<next_id;a=a+1) if(state[a]==1 || state[a]==2) begin
                state[a]=4;discarded=discarded+1;packets_pending=packets_pending-1;
                $fwrite(event_fd,"%0d,%0s,%0d,%0d,reset_discard,%0d,%0d,%0d,%016h\n",
                    case_id,label_text,cycle,$time,a,input_port[a],expected_port[a],expected[a]);
            end
            #0.01;
            if(so!==0 || ri!==31 || polarity!==0 || input_full!==0 || output_full!==0)
                fail("Synchronous reset values incorrect");
            for(a=0;a<5;a=a+1)
                if(priority_even[a]!==0 || priority_odd[a]!==0) fail("Reset priority incorrect");
        end else begin
            if((^{si,ri,so,ro,polarity})===1'bx) fail("Unknown handshake or polarity");
            if(peer_polarity!==polarity) fail("Neighbor polarity not synchronized");
            if((so & ~ro)!=0) fail("Send while receiver not ready");
            vc=polarity;ext=!polarity;parallel_count=0;
            for(a=0;a<5;a=a+1) begin
                if(ri[a]!==!model_in_full[2*a+ext]) fail("Input readiness incorrect");
                if(input_full[2*a]!==model_in_full[2*a] || input_full[2*a+1]!==model_in_full[2*a+1])
                    fail("Input occupancy differs from reference");
                want_in_request[a]=0;want_in_grant[a]=0;
                if(model_in_full[2*a+vc]) want_in_request[a][route(model_in_packet[2*a+vc])]=1;
                if(in_request[a]!==want_in_request[a]) fail("Routing request incorrect");
                if(si[a]) begin
                    actual_id=di[a][15:0];
                    if(!ri[a] || di[a][63]!==ext[0]) fail("Stimulus violated input readiness/VC phase");
                    if(actual_id>=next_id || state[actual_id]!=0 || input_port[actual_id]!=a || di[a]!==expected[actual_id])
                        fail("Injection bookkeeping mismatch");
                    state[actual_id]=1;injection_cycle[actual_id]=cycle;
                    injected=injected+1;packets_pending=packets_pending+1;
                    $fwrite(event_fd,"%0d,%0s,%0d,%0d,inject,%0d,%0d,%0d,%016h\n",
                        case_id,label_text,cycle,$time,actual_id,a,expected_port[actual_id],di[a]);
                end
                if(so[a]) begin
                    parallel_count=parallel_count+1;
                    if((^data_out[a])===1'bx) fail("Unknown output packet");
                    actual_id=data_out[a][15:0];
                    if(actual_id>=next_id || state[actual_id]!=1) fail("Unexpected or duplicate output packet");
                    if(expected_port[actual_id]!=a || data_out[a][63]!==ext[0]) fail("Wrong output port or VC phase");
                    if((data_out[a]&64'hff00ffffffffffff)!==(expected[actual_id]&64'hff00ffffffffffff))
                        fail("Packet corruption outside permitted hop field");
                    root_transfers=root_transfers+1;
                    route_hits[10*input_port[actual_id]+2*a+ext]=route_hits[10*input_port[actual_id]+2*a+ext]+1;
                    hop_hits[expected[actual_id][55:48]]=hop_hits[expected[actual_id][55:48]]+1;
                    if(path_linked[actual_id]) begin
                        if(!link_mode || a!=E) fail("Linked packet took an unexpected path");
                        state[actual_id]=2;
                    end else begin
                        state[actual_id]=3;delivered=delivered+1;packets_pending=packets_pending-1;
                        if(case_kind==2 && cycle-injection_cycle[actual_id]!=2) fail("Unloaded single-router latency is not two cycles");
                    end
                    $fwrite(event_fd,"%0d,%0s,%0d,%0d,router_output,%0d,%0d,%0d,%016h\n",
                        case_id,label_text,cycle,$time,actual_id,input_port[actual_id],a,data_out[a]);
                end
            end
            if(parallel_count>1) simultaneous_outputs=simultaneous_outputs+1;
            if(link_mode && !ro[E]) link_blocked_samples=link_blocked_samples+1;
            if(peer_so) begin
                if(!link_mode || !peer_ready || (^peer_data)===1'bx) fail("Unexpected peer delivery");
                actual_id=peer_data[15:0];
                if(actual_id>=next_id || state[actual_id]!=2 || peer_data[63]!==ext[0]) fail("Peer packet state or phase incorrect");
                if((peer_data&64'hff00ffffffffffff)!==(expected[actual_id]&64'hff00ffffffffffff)) fail("Peer packet corrupted");
                state[actual_id]=3;delivered=delivered+1;packets_pending=packets_pending-1;linked_deliveries=linked_deliveries+1;
                $fwrite(event_fd,"%0d,%0s,%0d,%0d,peer_delivery,%0d,%0d,4,%016h\n",
                    case_id,label_text,cycle,$time,actual_id,input_port[actual_id],peer_data);
            end

            for(a=0;a<5;a=a+1) begin
                idx=2*a+vc;req=0;want=0;count=0;selected=-1;
                prior_before=model_priority[idx];
                if(priority_even[a]!==model_priority[2*a][1:0] || priority_odd[a]!==model_priority[2*a+1][1:0])
                    fail("Priority differs from independent reference");
                if(output_full[2*a]!==model_out_full[2*a] || output_full[2*a+1]!==model_out_full[2*a+1])
                    fail("Output occupancy differs from reference");
                for(b=0;b<4;b=b+1) begin
                    req[b]=want_in_request[slot_port(a,b)][a];
                    if(req[b]) count=count+1;
                end
                if(out_request[a]!==req) fail("Assembled router request wiring incorrect");
                if(!model_out_full[idx]) begin
                    for(b=0;b<4;b=b+1) begin
                        q=(prior_before+b)%4;
                        if(req[q] && selected<0) selected=q;
                    end
                    if(selected>=0) want[selected]=1;
                end
                if(out_grant[a]!==want) fail("Grant violates round-robin reference");
                expected_send=model_out_full[2*a+ext] && ro[a];
                if(so[a]!==expected_send) fail("Output send differs from reference");
                if(so[a] && data_out[a]!==model_out_packet[2*a+ext]) fail("Crossbar/buffer data differs from reference");
                if(model_out_full[2*a+ext] && !ro[a]) blocked_output_hits[2*a+ext]=blocked_output_hits[2*a+ext]+1;
                if(so[a]) model_out_full[2*a+ext]=0;
                if(selected>=0) begin
                    target=slot_port(a,selected);want_in_grant[target][a]=1;
                    model_out_packet[idx]=model_in_packet[2*target+vc];model_out_full[idx]=1;
                    if(count>1) model_priority[idx]=(selected+1)%4;
                    if(req==15) begin
                        full_contention_hits[idx]=full_contention_hits[idx]+1;
                        start_priority_hits[4*idx+prior_before]=start_priority_hits[4*idx+prior_before]+1;
                    end
                end
                if(req!=0 || so[a] || output_full[2*a] || output_full[2*a+1])
                    $fwrite(arb_fd,"%0d,%0s,%0d,%0d,%0d,%0d,%b,%b,%0d,%0d,%0d,%0d,%0d\n",
                        case_id,label_text,cycle,$time,a,vc,req,want,prior_before,model_priority[idx],output_full[idx],ro[a],so[a]);
            end
            for(a=0;a<5;a=a+1) begin
                if(in_grant[a]!==want_in_grant[a]) fail("Assembled router grant-return wiring incorrect");
                if(model_in_full[2*a+vc] && want_in_grant[a]==0) blocked_input_hits[2*a+vc]=blocked_input_hits[2*a+vc]+1;
                if(want_in_grant[a]!=0) model_in_full[2*a+vc]=0;
                if(si[a]) begin model_in_full[2*a+ext]=1;model_in_packet[2*a+ext]=di[a];end
            end
            checks=checks+1;
            #0.01;
            for(a=0;a<5;a=a+1) begin
                if(input_full[2*a]!==model_in_full[2*a] || input_full[2*a+1]!==model_in_full[2*a+1] ||
                   output_full[2*a]!==model_out_full[2*a] || output_full[2*a+1]!==model_out_full[2*a+1])
                    fail("Registered occupancy update incorrect");
                if(priority_even[a]!==model_priority[2*a][1:0] || priority_odd[a]!==model_priority[2*a+1][1:0])
                    fail("Registered priority update incorrect");
            end
        end
    end

    initial begin : stimulus
        integer j,done_count,attempts,op,ident;
        $timeformat(-9,0," ns",10);
        for(p=0;p<5;p=p+1) di[p]=0;
        for(p=0;p<50;p=p+1) route_hits[p]=0;
        for(p=0;p<40;p=p+1) start_priority_hits[p]=0;
        for(p=0;p<10;p=p+1) begin full_contention_hits[p]=0;blocked_input_hits[p]=0;blocked_output_hits[p]=0;end
        for(p=0;p<256;p=p+1) hop_hits[p]=0;
        case_fd=$fopen("router_cases.csv","w");event_fd=$fopen("router_events.csv","w");arb_fd=$fopen("router_arbitration.csv","w");
        if(!case_fd || !event_fd || !arb_fd) fail("Cannot open result files");
        $fwrite(case_fd,"case_id,label,kind,start_ns,end_ns,injected,delivered,reset_discarded\n");
        $fwrite(event_fd,"case_id,label,cycle,time_ns,event,id,input_port,output_port,packet_hex\n");
        $fwrite(arb_fd,"case_id,label,cycle,time_ns,output_port,internal_vc,requests,grants,priority_before,priority_after,output_full_before,ready,send\n");
        $dumpfile("router.vcd");$dumpvars(0,tb_cardinal_router);
        begin_case("startup_reset",1);apply_reset();drain();end_case();

        // Six easily illustrated examples appear first; both VCs are tested.
        for(k=0;k<6;k=k+1) for(v=0;v<2;v=v+1) begin
            case(k)
                0:begin p=PE;o=N;end 1:begin p=PE;o=E;end
                2:begin p=PE;o=S;end 3:begin p=PE;o=W;end
                4:begin p=N;o=PE;end 5:begin p=W;o=E;end
            endcase
            $sformat(next_label,"example%0d_in%0d_out%0d_vc%0d",k+1,p,o,v);
            begin_case(next_label,2);allocate(p,o,v,1,id);inject_id(id);drain();end_case();
        end
        // All 20 non-U-turn crossbar paths, both VCs. These are local port
        // stimuli; some are deliberately not reachable under end-to-end XY.
        for(p=0;p<5;p=p+1) for(o=0;o<5;o=o+1) if(p!=o) for(v=0;v<2;v=v+1) begin
            $sformat(next_label,"route_in%0d_out%0d_vc%0d",p,o,v);
            begin_case(next_label,2);allocate(p,o,v,3,id);inject_id(id);drain();end_case();
        end
        for(o=E;o<=W;o=o+2) for(v=0;v<2;v=v+1) begin
            $sformat(next_label,"xy_precedence_out%0d_vc%0d",o,v);
            begin_case(next_label,2);allocate(PE,o,v,3,id);
            expected[id][59:58]=(o==E)?0:2; // Both coordinates differ; X wins.
            inject_id(id);drain();end_case();
        end
        begin_case("hop_field_all_256_values",3);
        for(hop=0;hop<256;hop=hop+1) for(v=0;v<2;v=v+1) begin
            allocate(PE,E,v,hop,id);inject_id(id);drain();
        end
        end_case();

        // Fill one output VC and its upstream input VC; prove stable data,
        // backpressure, then exactly-once delivery on readiness release.
        for(o=0;o<5;o=o+1) for(v=0;v<2;v=v+1) begin
            $sformat(next_label,"blocked_out%0d_vc%0d",o,v);
            begin_case(next_label,4);ready_ctl[o]=0;p=(o==PE)?N:PE;
            allocate(p,o,v,1,id);inject_id(id);repeat(4) @(negedge clk);
            allocate(p,o,v,1,id);inject_id(id);repeat(6) @(negedge clk);
            if(!input_full[2*p+v] || !output_full[2*o+v]) fail("Blocking case did not fill both stages");
            ready_ctl[o]=1;drain();end_case();
        end

        // All four eligible inputs request each output simultaneously.
        // Four bursts rotate through every possible starting priority.
        for(o=0;o<5;o=o+1) for(v=0;v<2;v=v+1) begin
            apply_reset();
            for(round_no=0;round_no<4;round_no=round_no+1) begin
                $sformat(next_label,"contention_out%0d_vc%0d_burst%0d",o,v,round_no);
                begin_case(next_label,5);
                ready_ctl[o]=(round_no==0);inject_four(o,v);
                repeat(8) @(negedge clk);ready_ctl[o]=1;
                drain();end_case();
            end
        end

        begin_case("reset_with_both_vcs_loaded",1);ready_ctl=0;
        inject_four(E,0);inject_four(E,1);repeat(6) @(negedge clk);
        if(input_full==0 || output_full==0 || packets_pending!=8) fail("Loaded reset setup failed");
        apply_reset();drain();end_case();
        begin_case("post_reset_no_stale_packets",2);
        for(o=0;o<5;o=o+1) begin p=(o==PE)?N:PE;allocate(p,o,o%2,1,id);inject_id(id);drain();end
        end_case();

        // Sustained four-source contention, 32 packets/input, both VCs,
        // independently changing downstream readiness, at each output.
        for(o=0;o<5;o=o+1) begin
            $sformat(next_label,"sustained_out%0d",o);begin_case(next_label,6);
            for(p=0;p<5;p=p+1) sent_per_input[p]=0;
            done_count=0;attempts=0;
            while(done_count<128) begin
                @(negedge clk);si=0;attempts=attempts+1;
                if(attempts>10000) fail("Sustained traffic timeout");
                rng=rng*32'd1664525+32'd1013904223;
                ready_ctl=31;ready_ctl[o]=rng[22]|rng[23];
                for(p=0;p<5;p=p+1) if(p!=o && sent_per_input[p]<32 && ri[p] && polarity!=(sent_per_input[p]%2)) begin
                    allocate(p,o,sent_per_input[p]%2,1,ident);di[p]=expected[ident];si[p]=1;
                    sent_per_input[p]=sent_per_input[p]+1;done_count=done_count+1;
                end
            end
            @(negedge clk);si=0;ready_ctl=31;drain();end_case();
        end
        begin_case("mixed_outputs_random_backpressure",6);
        for(p=0;p<5;p=p+1) sent_per_input[p]=0;
        done_count=0;attempts=0;
        while(done_count<640) begin
            @(negedge clk);si=0;attempts=attempts+1;
            if(attempts>15000) fail("Mixed traffic timeout");
            for(p=0;p<5;p=p+1) begin
                rng=rng*32'd1664525+32'd1013904223;ready_ctl[p]=rng[22]|rng[23];
                if(sent_per_input[p]<128 && ri[p] && polarity!=(sent_per_input[p]%2)) begin
                    op=rng[29:28];if(op>=p) op=op+1;
                    allocate(p,op,sent_per_input[p]%2,rng[15:8],ident);
                    di[p]=expected[ident];si[p]=1;sent_per_input[p]=sent_per_input[p]+1;done_count=done_count+1;
                end
            end
        end
        @(negedge clk);si=0;ready_ctl=31;drain();end_case();

        // A real neighbor is used only for this section, so the requested
        // inter-router handshake is demonstrated, not just emulated ready.
        apply_reset();link_mode=1;
        begin_case("two_router_link_blocked_then_released",7);peer_ready=0;
        for(k=0;k<8;k=k+1) begin allocate(PE,E,k%2,1,id);inject_id(id);end
        repeat(8) @(negedge clk);
        if(ro[E]!==0 || packets_pending!=8) fail("Real neighbor did not backpressure the link");
        peer_ready=1;drain();end_case();
        begin_case("two_router_link_unblocked",7);
        for(k=0;k<8;k=k+1) begin allocate(PE,E,k%2,1,id);inject_id(id);end
        drain();end_case();link_mode=0;

        // Coverage gates: this bench cannot PASS just because it stayed idle.
        covered_routes=0;covered_priorities=0;
        coverage_fd=$fopen("router_coverage.csv","w");
        $fwrite(coverage_fd,"metric,index,hits\n");
        for(p=0;p<5;p=p+1) for(o=0;o<5;o=o+1) if(p!=o) for(v=0;v<2;v=v+1) begin
            id=10*p+2*o+v;if(route_hits[id]==0) fail("Missing port/VC routing coverage");
            covered_routes=covered_routes+1;$fwrite(coverage_fd,"route,%0d,%0d\n",id,route_hits[id]);
        end
        for(p=0;p<40;p=p+1) begin
            if(start_priority_hits[p]==0) fail("Missing four-request starting-priority coverage");
            covered_priorities=covered_priorities+1;$fwrite(coverage_fd,"four_request_start_priority,%0d,%0d\n",p,start_priority_hits[p]);
        end
        for(p=0;p<10;p=p+1) begin
            if(!full_contention_hits[p] || !blocked_output_hits[p] || !blocked_input_hits[p]) fail("Missing contention/backpressure coverage");
            $fwrite(coverage_fd,"four_request_grant,%0d,%0d\n",p,full_contention_hits[p]);
            $fwrite(coverage_fd,"blocked_output,%0d,%0d\n",p,blocked_output_hits[p]);
            $fwrite(coverage_fd,"blocked_input,%0d,%0d\n",p,blocked_input_hits[p]);
        end
        for(p=0;p<256;p=p+1) begin
            if(hop_hits[p]==0) fail("Missing hop-field value coverage");
            $fwrite(coverage_fd,"hop_value,%0d,%0d\n",p,hop_hits[p]);
        end
        if(loaded_resets!=1 || discarded!=8 || linked_deliveries!=16 || link_blocked_samples==0 || simultaneous_outputs==0)
            fail("Required reset/link/concurrency coverage missing");
        if(injected!=delivered+discarded || packets_pending!=0 || injected!=next_id) fail("Final conservation failure");
        for(p=0;p<next_id;p=p+1) if(state[p]!=3 && state[p]!=4) fail("Unfinished packet");
        $fclose(case_fd);$fclose(event_fd);$fclose(arb_fd);$fclose(coverage_fd);
        summary_fd=$fopen("summary.csv","w");
        $fwrite(summary_fd,"checks,cases,injected,delivered,reset_discarded,port_vc_routes,four_request_priority_cases,hop_values,linked_deliveries,link_blocked_samples,parallel_output_cycles,errors\n");
        $fwrite(summary_fd,"%0d,%0d,%0d,%0d,%0d,%0d,%0d,256,%0d,%0d,%0d,0\n",
            checks,case_id,injected,delivered,discarded,covered_routes,covered_priorities,linked_deliveries,link_blocked_samples,simultaneous_outputs);
        $display("PASS router checks=%0d cases=%0d injected=%0d delivered=%0d reset_discarded=%0d routes=%0d contention_priority_cases=%0d",
            checks,case_id,injected,delivered,discarded,covered_routes,covered_priorities);
        $finish;
    end
endmodule

// Supplemental EE577B Phase 2 verification, Verilog-2001.
// Uses only the published CPU ports and provided memory instances. No CPU
// internal register names, hierarchy, or implementation timing is assumed.
// Cases run in ONE simulator process, with 5-cycle synchronous resets.
`timescale 1ns/10ps
`include "./include/imem.v"
`include "./include/dmem.v"
module tb_phase2_sequence;
reg CLK, RESET;
wire [0:31] inst_in, pc_out, addr_out;
wire [0:63] d_in, d_out;
wire memEn, memWrEn;
cardinal_cpu CPU (.clk(CLK), .reset(RESET), .inst_in(inst_in), .d_in(d_in),
                  .pc_out(pc_out), .addr_out(addr_out), .memEn(memEn),
                  .memWrEn(memWrEn), .d_out(d_out));
imem IM (.memAddr(pc_out[22:29]), .dataOut(inst_in));
dmem DM (.clk(CLK), .memEn(memEn), .memWrEn(memWrEn),
         .memAddr(addr_out[24:31]), .dataIn(d_out), .dataOut(d_in));
always #2 CLK = ~CLK;
reg [63:0] expected_memory [0:255];
reg [95:0] expected_stores [0:1023];
reg [8*256:1] list_file, directory, filename, active_case, poison_path, probe_path;
integer list_fd, metadata_fd, status, i, cycle, store_count, expected_count;
integer expected_end_pc, errors, before_errors, programs, failed_programs;
integer interruptions, cut, interrupt_index, trace_enabled;
reg monitor_enabled, finished;

// Sample the public memory interface exactly when the supplied memory samples it.
always @(posedge CLK) begin
    if (monitor_enabled && !RESET) begin
        if ((memEn !== 1'b0 && memEn !== 1'b1) ||
            (memWrEn !== 1'b0 && memWrEn !== 1'b1)) begin
            $display("FAIL unknown memory control in %0s", active_case);
            errors = errors + 1;
        end
        if (memWrEn === 1'b1 && memEn !== 1'b1) begin
            $display("FAIL write enable without memory enable in %0s", active_case);
            errors = errors + 1;
        end
        if (memEn === 1'b1 && memWrEn === 1'b1) begin
            if (trace_enabled != 0) begin
                if (store_count >= expected_count) begin
                    $display("FAIL unexpected store in %0s: addr=%h data=%h", active_case, addr_out, d_out);
                    errors = errors + 1;
                end else if ({addr_out, d_out} !== expected_stores[store_count]) begin
                    $display("FAIL store %0d in %0s: expected=%h got=%h", store_count, active_case,
                             expected_stores[store_count], {addr_out,d_out});
                    errors = errors + 1;
                end
            end
            store_count = store_count + 1;
        end
    end
end

task prepare_case;
    input [8*256:1] case_directory;
    begin
        monitor_enabled = 0;
        @(negedge CLK); RESET = 1;
        // Observe AFTER each active reset edge. Do not assume an asynchronous
        // reset or cancellation at the first edge in the external memory model.
        repeat (5) begin
            @(negedge CLK);
            if (pc_out !== 32'd0 || memEn !== 1'b0 || memWrEn !== 1'b0) begin
                $display("FAIL reset outputs before %0s: PC=%h memEn=%b memWrEn=%b", case_directory,pc_out,memEn,memWrEn);
                errors = errors + 1;
            end
        end
        // Reinitialize external memories only once reset has cleared the CPU.
        active_case = case_directory;
        $sformat(filename, "%0s/imem.fill",case_directory);$readmemh(filename,IM.MEM);
        $sformat(filename, "%0s/dmem.fill",case_directory);$readmemh(filename,DM.MEM);
        $sformat(filename, "%0s/expected.hex",case_directory);$readmemh(filename,expected_memory);
        $sformat(filename, "%0s/meta.txt",case_directory);
        metadata_fd=$fopen(filename,"r");
        if (metadata_fd==0) begin $display("FAIL cannot open metadata %0s",filename);$finish;end
        status=$fscanf(metadata_fd,"%d %d %d",expected_count,expected_end_pc,trace_enabled);
        $fclose(metadata_fd);
        if (status!=3 || expected_count<0 || expected_count>1024) begin
            $display("FAIL invalid metadata %0s",filename);$finish;
        end
        if (expected_count>0) begin
            $sformat(filename,"%0s/stores.fill",case_directory);
            $readmemh(filename,expected_stores,0,expected_count-1);
        end
        store_count=0;cycle=0;finished=0;
        RESET=0;
    end
endtask

task execute_case;
    begin
        monitor_enabled=1;
        while (!finished && cycle<5000) begin
            @(negedge CLK);cycle=cycle+1;
            if (inst_in===32'd0) begin
                finished=1;
                if (pc_out!==expected_end_pc) begin
                    $display("FAIL termination PC in %0s: expected=%h got=%h",active_case,expected_end_pc,pc_out);
                    errors=errors+1;
                end
            end
        end
        if (!finished) begin $display("FAIL timeout in %0s",active_case);errors=errors+1;end
        repeat (5) @(negedge CLK);
        monitor_enabled=0;
        if (trace_enabled!=0 && store_count!=expected_count) begin
            $display("FAIL store count in %0s: expected=%0d got=%0d",active_case,expected_count,store_count);
            errors=errors+1;
        end
        for(i=0;i<256;i=i+1) begin
            if (DM.MEM[i]!==expected_memory[i]) begin
                $display("FAIL memory %0d in %0s: expected=%h got=%h",i,active_case,expected_memory[i],DM.MEM[i]);
                errors=errors+1;
            end
        end
        programs=programs+1;
        if(errors==before_errors) $display("CASE PASS %0s cycles=%0d stores=%0d",active_case,cycle,store_count);
        else begin
            failed_programs=failed_programs+1;
            $display("CASE FAIL %0s new_errors=%0d",active_case,errors-before_errors);
        end
    end
endtask

initial begin
    CLK=0;RESET=1;monitor_enabled=0;errors=0;programs=0;failed_programs=0;interruptions=0;
    if(!$value$plusargs("CASELIST=%s",list_file))list_file="tests/phase2/sequence.list";
    if(!$value$plusargs("POISON=%s",poison_path))poison_path="tests/phase2/programs/reset_poison";
    if(!$value$plusargs("PROBE=%s",probe_path))probe_path="tests/phase2/programs/reset_probe";
    list_fd=$fopen(list_file,"r");
    if(list_fd==0)begin $display("FAIL cannot open case list %0s",list_file);$finish;end
    status=$fscanf(list_fd,"%s",directory);
    while(status==1)begin
        before_errors=errors;prepare_case(directory);execute_case;
        status=$fscanf(list_fd,"%s",directory);
    end
    $fclose(list_fd);
    // Interrupt live execution at early pipeline occupancy and later points.
    // The subsequent probe observes all architectural registers through stores.
    for(interrupt_index=0;interrupt_index<14;interrupt_index=interrupt_index+1)begin
        if(interrupt_index<10)cut=interrupt_index+1;
        else case(interrupt_index)10:cut=16;11:cut=32;12:cut=64;13:cut=74;endcase
        before_errors=errors;
        prepare_case(poison_path);
        repeat(cut)@(negedge CLK);
        $display("RESET INTERRUPT after %0d cycles",cut);
        prepare_case(probe_path);execute_case;
        interruptions=interruptions+1;
    end
    if(errors==0 && programs>14)$display("SEQUENCE PASSED programs=%0d reset_interruptions=%0d",programs,interruptions);
    else $display("SEQUENCE FAILED programs=%0d failed_programs=%0d errors=%0d",programs,failed_programs,errors);
    $finish;
end
initial begin
    #10000000;
    $display("FAIL global watchdog timeout");$finish;
end
endmodule

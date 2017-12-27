//
// Copyright (c) 2016, Intel Corporation
// All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
//
// Redistributions of source code must retain the above copyright notice, this
// list of conditions and the following disclaimer.
//
// Redistributions in binary form must reproduce the above copyright notice,
// this list of conditions and the following disclaimer in the documentation
// and/or other materials provided with the distribution.
//
// Neither the name of the Intel Corporation nor the names of its contributors
// may be used to endorse or promote products derived from this software
// without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
// ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
// LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
// CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
// SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
// INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
// CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
// ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
// POSSIBILITY OF SUCH DAMAGE.

`timescale 1 ns / 100 ps

module gemm_dp_gen_tb ();

    parameter PIPELINE_DEPTH = 18;
    parameter DATA_WIDTH = 16;
    parameter FRAC_WIDTH = 13;
    parameter VECTOR_LENGTH = 16;
    parameter PE_LATENCY = 1;
    parameter RES_PIPE = 1;
    parameter OUT_DELAY = 1;
    parameter NUM_ROWS = 1;
    parameter NUM_COLS = 1;
    parameter VECTOR_WIDTH = DATA_WIDTH*VECTOR_LENGTH;


    reg clk;

    reg rst;
    reg ena;

    reg di_ena;

    reg acc_fin;
    reg acc_res;

    reg drain_rdy [0:NUM_COLS-1];
    reg drain_valid [0:NUM_COLS-1];

    reg fd_a_wr_en;
    reg fd_a_rd_en;
    reg fd_a_loaded;
    reg fd_a_full;

    reg fd_b_wr_en;
    reg fd_b_rd_en;
    reg fd_b_loaded;
    reg fd_b_full;

    reg [511:0] drain_interconnect_output;


    reg [VECTOR_WIDTH-1:0] debug_grid_feeder_a [0:NUM_ROWS-1];
    reg [VECTOR_WIDTH-1:0] debug_grid_feeder_b [0:NUM_COLS-1]; 

    reg [DATA_WIDTH*2-1:0] debug_grid_output [0:NUM_COLS-1]; 
    reg [DATA_WIDTH*2-1:0] debug_acc [0:NUM_ROWS-1][0:NUM_COLS-1]; 
    reg [DATA_WIDTH*2-1:0] debug_a_row [0:NUM_ROWS-1]; 

    reg [15:0] fa_k0 = 0; // 32
    reg [15:0] fa_k1 = 0; // 64
    reg [15:0] fa_k2 = 0; // 96
    reg [15:0] fa_k3 = 0; // 128
    reg [15:0] fa_k4 = 0; // 160
    reg [15:0] fa_k5 = 0; // 192
    reg [15:0] fa_k6 = 0; // 224
    reg [15:0] fa_k7 = 0; // 256
    reg [15:0] fa_k8 = 0; // 32
    reg [15:0] fa_k9 = 0; // 64
    reg [15:0] fa_k10 = 0; // 96
    reg [15:0] fa_k11 = 0; // 128
    reg [15:0] fa_k12 = 0; // 160
    reg [15:0] fa_k13 = 0; // 192
    reg [15:0] fa_k14 = 0; // 224
    reg [15:0] fa_k15 = 0; // 256
    
    reg [15:0] fa_l0 = 0; // 32
    reg [15:0] fa_l1 = 0; // 64
    reg [15:0] fa_l2 = 0; // 96
    reg [15:0] fa_l3 = 0; // 128
    reg [15:0] fa_l4 = 0; // 160
    reg [15:0] fa_l5 = 0; // 192
    reg [15:0] fa_l6 = 0; // 224
    reg [15:0] fa_l7 = 0; // 256
    reg [15:0] fa_l8 = 0; // 32
    reg [15:0] fa_l9 = 0; // 64
    reg [15:0] fa_l10 = 0; // 96
    reg [15:0] fa_l11 = 0; // 128
    reg [15:0] fa_l12 = 0; // 160
    reg [15:0] fa_l13 = 0; // 192
    reg [15:0] fa_l14 = 0; // 224
    reg [15:0] fa_l15 = 0; // 256

      
    reg [15:0] fb_k0 = 0; // 32
    reg [15:0] fb_k1 = 0; // 64
    reg [15:0] fb_k2 = 0; // 96
    reg [15:0] fb_k3 = 0; // 128
    reg [15:0] fb_k4 = 0; // 160
    reg [15:0] fb_k5 = 0; // 192
    reg [15:0] fb_k6 = 0; // 224
    reg [15:0] fb_k7 = 0; // 256
    reg [15:0] fb_k8 = 0; // 32
    reg [15:0] fb_k9 = 0; // 64
    reg [15:0] fb_k10 = 0; // 96
    reg [15:0] fb_k11 = 0; // 128
    reg [15:0] fb_k12 = 0; // 160
    reg [15:0] fb_k13 = 0; // 192
    reg [15:0] fb_k14 = 0; // 224
    reg [15:0] fb_k15 = 0; // 256
    
    reg [15:0] fb_l0 = 0; // 32
    reg [15:0] fb_l1 = 0; // 64
    reg [15:0] fb_l2 = 0; // 96
    reg [15:0] fb_l3 = 0; // 128
    reg [15:0] fb_l4 = 0; // 160
    reg [15:0] fb_l5 = 0; // 192
    reg [15:0] fb_l6 = 0; // 224
    reg [15:0] fb_l7 = 0; // 256
    reg [15:0] fb_l8 = 0; // 32
    reg [15:0] fb_l9 = 0; // 64
    reg [15:0] fb_l10 = 0; // 96
    reg [15:0] fb_l11 = 0; // 128
    reg [15:0] fb_l12 = 0; // 160
    reg [15:0] fb_l13 = 0; // 192
    reg [15:0] fb_l14 = 0; // 224
    reg [15:0] fb_l15 = 0; // 256

    	// Feeder DUT
    gemm_dp_gen # (
        DATA_WIDTH, 
        FRAC_WIDTH,
        VECTOR_LENGTH, 
        PE_LATENCY, 
        RES_PIPE,
        OUT_DELAY,
        NUM_ROWS,
        NUM_COLS) dut0
    (
        .clk            (clk),
    
        .rst            (rst),
        .ena            (ena),
       
        .di_ena         (di_ena),

        .acc_fin        (acc_fin),
        .acc_res        (acc_res),

        .drain_rdy      (drain_rdy),
        .drain_valid    (drain_valid),

        .fd_a_wr_en     (fd_a_wr_en),
        .fd_a_rd_en     (fd_a_rd_en),
        .fd_a_loaded    (fd_a_loaded),
        .fd_a_full      (fd_a_full),

        .fd_a_wr_data   ( {fa_l15, fa_l14, fa_l13, fa_l12, fa_l11, fa_l10, fa_l9, fa_l8, fa_l7, fa_l6, fa_l5, fa_l4, fa_l3, fa_l2, fa_l1, fa_l0, fa_k15, fa_k14, fa_k13, fa_k12, fa_k11, fa_k10, fa_k9, fa_k8, fa_k7, fa_k6, fa_k5, fa_k4, fa_k3, fa_k2, fa_k1, fa_k0} ),

        .fd_b_wr_en     (fd_b_wr_en),
        .fd_b_rd_en     (fd_b_rd_en),
        .fd_b_loaded    (fd_b_loaded),
        .fd_b_full      (fd_b_full),

        .fd_b_wr_data   ( {fb_l15, fb_l14, fb_l13, fb_l12, fb_l11, fb_l10, fb_l9, fb_l8, fb_l7, fb_l6, fb_l5, fb_l4, fb_l3, fb_l2, fb_l1, fb_l0, fb_k15, fb_k14, fb_k13, fb_k12, fb_k11, fb_k10, fb_k9, fb_k8, fb_k7, fb_k6, fb_k5, fb_k4, fb_k3, fb_k2, fb_k1, fb_k0} ),

        .drain_interconnect_output  (drain_interconnect_output),

        .debug_grid_feeder_a    (debug_grid_feeder_a),
        .debug_grid_feeder_b    (debug_grid_feeder_b),
        .debug_grid_output      (debug_grid_output),
        .debug_acc  (debug_acc),
        .debug_a_row (debug_a_row)
    );

    reg ena_q;
    
    integer j = 0;
    integer i = 0;
    integer k = 0;

    event terminate_sim;
    event rst_trigger;
    event rst_trigger_done;
    event toggle_ena;


    always
        #1 clk = ~clk;

	initial
	begin
        $display($time, " << Simulation Starting >> ");
        clk = 1'b0;
        rst = 1'b0;
        ena = 1'b0;
       
        di_ena = 1'b0;

        acc_fin = 1'b0;
        acc_res = 1'b0;
        
        drain_rdy[0] = 1'b0;
        drain_rdy[1] = 1'b0;
        
        fd_a_wr_en = 1'b0;
        fd_a_rd_en = 1'b0;
       
        fd_b_wr_en = 1'b0;
        fd_b_rd_en = 1'b0;
        @(negedge clk);

        -> rst_trigger; 
        @(rst_trigger_done);
        -> toggle_ena; // ON 

        //drain_rdy[0] = 1'b1;
        //drain_rdy[1] = 1'b1;
        di_ena = 1'b1;

        /*
        load_fa(j,j+1,j+2,j+3,j+4,j+5,j+6,j+7,j+8,j+9,j+10,j+11,j+12,j+13,j+14,j+15,
                j+16,j+17,j+18,j+19,j+20,j+21,j+22,j+23,j+24,j+25,j+26,j+27,j+28,j+29,j+30,j+31);
        load_fb(j,j+1,j+2,j+3,j+4,j+5,j+6,j+7,j+8,j+9,j+10,j+11,j+12,j+13,j+14,j+15,
                j+16,j+17,j+18,j+19,j+20,j+21,j+22,j+23,j+24,j+25,j+26,j+27,j+28,j+29,j+30,j+31);
        */
     
        // FOR FILLING ROWS AND COLS
        
        k = 0;
        load_fa(1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
                1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1);
        for (j=0; j<NUM_ROWS; j=j+1 ) begin
            repeat (15*17) begin
                load_fb(1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
                        1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1);
                @(negedge clk);
            end
        end
        load_fb(1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
                1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1);
        load_fa(1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
                2,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1);
        @(negedge clk);
        
        /*  
        // FOR FILLING ROWS 
        for ( j=0; j<NUM_ROWS; j=j+1 ) begin
            k = 0;
            load_fb(1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
                    1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0);
            repeat (15*17 + 1) begin
                load_fa(j+1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
                        j+1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0);
                @(negedge clk);
                k=k+1;
            end
        end 
        */ 
        /*
        // FOR FILLING COLS
        for ( j=0; j<NUM_COLS; j=j+1 ) begin
            k = 0;
            load_fa(1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
                    1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0);
            repeat (15*17 + 1) begin
                load_fb(j+1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
                        j+1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0);
                @(negedge clk);
                k=k+1;
            end
        end 
        */ 

        load_fa(0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
                0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0);
        load_fb(0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
                0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0);
        @(negedge clk);
        @(negedge clk);
        ena_q = 1'b1;    
        
        repeat (40000) begin
            @(negedge clk);
            //acc_fin[0] = 1'b1;
       end

		$display($time, " << Simulation Finished >> ");
        -> terminate_sim;
	end

    // -------------
    // Control Logic
    // -------------
    reg [10:0] s_counter = 0;
    reg [10:0]  b_counter = 1;
    reg [10:0]  acc_fin_counter = 0;
    reg acc_start = 1'b0;
    reg acc_fin_counter_start = 1'b0;

    initial begin
        forever begin
            @(posedge clk);
            fd_a_wr_en = ~fd_a_loaded & di_ena;
            fd_b_wr_en = ~fd_b_loaded & di_ena;
        end
    end

    initial begin
        forever begin
            @(posedge clk);
            for ( i=0; i<NUM_COLS; i=i+1 ) begin
                drain_rdy[i] <= 1'b1;
            end
        end
    end

    reg ena_qq;
    reg ena_qqq;
    initial begin
        forever begin
            @(posedge clk);
            //ena_q <= fd_a_loaded & fd_b_loaded;
            ena_qq <= ena_q;
            ena_qqq <= ena_qq;
            ena <= ena_qqq;
            fd_a_rd_en <= fd_a_loaded & fd_b_loaded;
            fd_b_rd_en <= fd_a_loaded & fd_b_loaded;
        end
    end

    initial begin
        forever begin
            @ (posedge clk);
            if (ena) begin
                s_counter <= s_counter + 1;
            end
        end
    end

    initial begin
        forever begin
            @(posedge clk);
            if (s_counter == 1022) begin
                acc_res <= 1'b1;
            end
            if (s_counter == 1023) begin
                s_counter <= 0;
                b_counter <= b_counter + 1;
                acc_res <= 1'b1;
            end
        end
    end
    
    initial begin
        forever begin
            @(posedge clk);
            if (b_counter > 15) begin
                b_counter <= 0;
                acc_fin <= 1'b1;
                acc_fin_counter_start <= 1'b1;
            end
        end
    end

    initial begin
        forever begin
            @(posedge clk);
            if(acc_fin_counter_start) begin
                acc_fin_counter <= acc_fin_counter + 1;
            end
        end
    end

    initial begin
        forever begin
            @(posedge clk);
            if(acc_fin_counter == 1023) begin
                acc_fin <= 1'b0;
                acc_fin_counter <= 0;
                acc_fin_counter_start <= 1'b0;
            end
        end
    end
    // -------
    // Monitor
    // -------    
    initial
	begin
		$monitor($time, " << LOADED VALUES >>\n \
                     \tRESULT:\t%h\n",
                     drain_interconnect_output);
	end
    /*	
    initial
	begin
		$monitor($time, " << LOADED VALUES >>\n \
                     \trst:\t%h\n \
                     \tena:\t%h\n \
                     \tacc_fin:\t%h\n \
                     \tacc_res:\t%h\n \
                     \tdi_ena:\t%h\n \
                     \tdrain_rdy:\t%h\n \
                     \tfd_a_wr_data:\t%h\n \
                     \tfd_a_wr_en:\t%h\n \
                     \tfd_a_rd_en:\t%h\n \
                     \tfd_b_wr_data:\t%h\n \
                     \tfd_b_wr_en:\t%h\n \
                     \tfd_b_rd_en:\t%h\n \
                     \n\t\t << Data Signals >>\n \
                     \tRESULT:\t%h\n \
                     \tfd_a_loaded:\t%h\n \
                     \tfd_a_full:\t%h\n \
                     \tfd_b_loaded:\t%h\n \
                     \tfd_b_full:\t%h\n \
                     \n\t\t << DEBUG Signals >>\n \
                     \tdebug_grid_feeder_a:\t%h\n \
                     \tdebug_grid_feeder_b:\t%h\n \
                     \tdebug_grid_output:\t%h\n",
                     rst,
                     ena[0],
                     acc_fin[0],
                     acc_res[0],
                     di_ena,
                     drain_rdy[0],
                     {fa_l15, fa_l14, fa_l13, fa_l12, fa_l11, fa_l10, fa_l9, fa_l8, fa_l7, fa_l6, fa_l5, fa_l4, fa_l3, fa_l2, fa_l1, fa_l0, fa_k15, fa_k14, fa_k13, fa_k12, fa_k11, fa_k10, fa_k9, fa_k8, fa_k7, fa_k6, fa_k5, fa_k4, fa_k3, fa_k2, fa_k1, fa_k0},
                     fd_a_wr_en,
                     fd_a_rd_en,
                     {fb_l15, fb_l14, fb_l13, fb_l12, fb_l11, fb_l10, fb_l9, fb_l8, fb_l7, fb_l6, fb_l5, fb_l4, fb_l3, fb_l2, fb_l1, fb_l0, fb_k15, fb_k14, fb_k13, fb_k12, fb_k11, fb_k10, fb_k9, fb_k8, fb_k7, fb_k6, fb_k5, fb_k4, fb_k3, fb_k2, fb_k1, fb_k0},
                     fd_b_wr_en,
                     fd_b_rd_en,
                     drain_interconnect_output,
                     fd_a_loaded,
                     fd_a_full,   
                     fd_b_loaded,
                     fd_b_full,
                     debug_grid_feeder_a[0],
                     debug_grid_feeder_b[0],
                     debug_grid_output[0]);   
	end
    */	
    
    // ------------------------
    // Terminate the Simulation
    // ------------------------
    initial
    begin
        @ (terminate_sim);
        $finish;
    end

    // -------------
    // Toggle Enable
    // -------------
    /*
    initial
    begin
        forever
        begin
            @ (toggle_ena);
            if(ena)
            begin
                $display($time, " << TOGGLE ENABLE - OFF >> ");
            end
            else
            begin
                $display($time, " << TOGGLE ENABLE - ON >> ");
            end
            ena = ~ena;
        end
    end
    */
    // ---------------
    // Trigger a Reset
    // ---------------
    initial
    begin
        forever
        begin
            @ (rst_trigger);
            @ (negedge clk);
            $display($time, " << TRIGGER RESET >> ");
            rst = 1'b1;
            @ (negedge clk);
            rst = 1'b0;
            -> rst_trigger_done;
        end
    end
    
    task load_fa;
        input signed [15:0] r0_0;
        input signed [15:0] r0_1;
        input signed [15:0] r0_2;
        input signed [15:0] r0_3;
        input signed [15:0] r0_4;
        input signed [15:0] r0_5;
        input signed [15:0] r0_6;
        input signed [15:0] r0_7;
        input signed [15:0] r0_8;
        input signed [15:0] r0_9;
        input signed [15:0] r0_10;
        input signed [15:0] r0_11;
        input signed [15:0] r0_12;
        input signed [15:0] r0_13;
        input signed [15:0] r0_14;
        input signed [15:0] r0_15;
        input signed [15:0] r1_0;
        input signed [15:0] r1_1;
        input signed [15:0] r1_2;
        input signed [15:0] r1_3;
        input signed [15:0] r1_4;
        input signed [15:0] r1_5;
        input signed [15:0] r1_6;
        input signed [15:0] r1_7;
        input signed [15:0] r1_8;
        input signed [15:0] r1_9;
        input signed [15:0] r1_10;
        input signed [15:0] r1_11;
        input signed [15:0] r1_12;
        input signed [15:0] r1_13;
        input signed [15:0] r1_14;
        input signed [15:0] r1_15;

        begin
        
        fa_k0 = r0_0;
        fa_k1 = r0_1;
        fa_k2 = r0_2;
        fa_k3 = r0_3;
        fa_k4 = r0_4;
        fa_k5 = r0_5;
        fa_k6 = r0_6;
        fa_k7 = r0_7;
        fa_k8 = r0_8;
        fa_k9 = r0_9;
        fa_k10 = r0_10;
        fa_k11 = r0_11;
        fa_k12 = r0_12;
        fa_k13 = r0_13;
        fa_k14 = r0_14;
        fa_k15 = r0_15;

        fa_l0 = r1_0;
        fa_l1 = r1_1;
        fa_l2 = r1_2;
        fa_l3 = r1_3;
        fa_l4 = r1_4;
        fa_l5 = r1_5;
        fa_l6 = r1_6;
        fa_l7 = r1_7;
        fa_l8 = r1_8;
        fa_l9 = r1_9;
        fa_l10 = r1_10;
        fa_l11 = r1_11;
        fa_l12 = r1_12;
        fa_l13 = r1_13;
        fa_l14 = r1_14;
        fa_l15 = r1_15;

        end
    endtask 

    task load_fb;
        input signed [15:0] c0_0;
        input signed [15:0] c0_1;
        input signed [15:0] c0_2;
        input signed [15:0] c0_3;
        input signed [15:0] c0_4;
        input signed [15:0] c0_5;
        input signed [15:0] c0_6;
        input signed [15:0] c0_7;
        input signed [15:0] c0_8;
        input signed [15:0] c0_9;
        input signed [15:0] c0_10;
        input signed [15:0] c0_11;
        input signed [15:0] c0_12;
        input signed [15:0] c0_13;
        input signed [15:0] c0_14;
        input signed [15:0] c0_15;
        input signed [15:0] c1_0;
        input signed [15:0] c1_1;
        input signed [15:0] c1_2;
        input signed [15:0] c1_3;
        input signed [15:0] c1_4;
        input signed [15:0] c1_5;
        input signed [15:0] c1_6;
        input signed [15:0] c1_7;
        input signed [15:0] c1_8;
        input signed [15:0] c1_9;
        input signed [15:0] c1_10;
        input signed [15:0] c1_11;
        input signed [15:0] c1_12;
        input signed [15:0] c1_13;
        input signed [15:0] c1_14;
        input signed [15:0] c1_15;

        begin
        
        fb_k0 = c0_0;
        fb_k1 = c0_1;
        fb_k2 = c0_2;
        fb_k3 = c0_3;
        fb_k4 = c0_4;
        fb_k5 = c0_5;
        fb_k6 = c0_6;
        fb_k7 = c0_7;
        fb_k8 = c0_8;
        fb_k9 = c0_9;
        fb_k10 = c0_10;
        fb_k11 = c0_11;
        fb_k12 = c0_12;
        fb_k13 = c0_13;
        fb_k14 = c0_14;
        fb_k15 = c0_15;

        fb_l0 = c1_0;
        fb_l1 = c1_1;
        fb_l2 = c1_2;
        fb_l3 = c1_3;
        fb_l4 = c1_4;
        fb_l5 = c1_5;
        fb_l6 = c1_6;
        fb_l7 = c1_7;
        fb_l8 = c1_8;
        fb_l9 = c1_9;
        fb_l10 = c1_10;
        fb_l11 = c1_11;
        fb_l12 = c1_12;
        fb_l13 = c1_13;
        fb_l14 = c1_14;
        fb_l15 = c1_15;

        end
    endtask 
endmodule


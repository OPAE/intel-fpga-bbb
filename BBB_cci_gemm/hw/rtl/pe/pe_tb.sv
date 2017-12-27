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

module pe_tb ();

    parameter PIPELINE_DEPTH = 17 + 3;
    parameter DATA_WIDTH = 16;
    parameter VECTOR_LENGTH = 16;

    reg clk;
    
    // rst
    reg rst_in;
    reg rst_out;
    
    // ena
    reg ena_in;
    reg ena_out;

    // acc_fin
    reg acc_fin_in;
    reg acc_fin_out;

    // acc_res
    reg acc_res_in;
    reg acc_res_out;

    reg [31:0]  debug_acc;

	// Vector A
	reg signed [31:0] in_a_1;
	reg signed [31:0] in_a_2;
	reg signed [31:0] in_a_3;
	reg signed [31:0] in_a_4;
	reg signed [31:0] in_a_5;
	reg signed [31:0] in_a_6;
	reg signed [31:0] in_a_7;
	reg signed [31:0] in_a_8;
	
    reg signed [31:0] out_a_1;
	reg signed [31:0] out_a_2;
	reg signed [31:0] out_a_3;
	reg signed [31:0] out_a_4;
	reg signed [31:0] out_a_5;
	reg signed [31:0] out_a_6;
	reg signed [31:0] out_a_7;
	reg signed [31:0] out_a_8;

	// Vector B
	reg signed [31:0] in_b_1;
	reg signed [31:0] in_b_2;
	reg signed [31:0] in_b_3;
	reg signed [31:0] in_b_4;
	reg signed [31:0] in_b_5;
	reg signed [31:0] in_b_6;
	reg signed [31:0] in_b_7;
	reg signed [31:0] in_b_8;
	
    reg signed [31:0] out_b_1;
	reg signed [31:0] out_b_2;
	reg signed [31:0] out_b_3;
	reg signed [31:0] out_b_4;
	reg signed [31:0] out_b_5;
	reg signed [31:0] out_b_6;
	reg signed [31:0] out_b_7;
	reg signed [31:0] out_b_8;

    // drain_res
    reg [31:0] drain_res_in;
    reg [31:0] drain_res_out;

    // Systolic Drain
    reg drain_neig_valid;
    reg drain_neig_rdy;
    reg drain_valid;
    reg drain_rdy;


    integer i;
    integer k = 0;

    integer block_output_i = 0;
    reg [31:0] block_output [0:1023];

    integer block_expect_i = 0;
    reg [31:0] block_expect [0:1023];
    

    reg [31:0] new_output;
    reg [31:0] expected_output [0:PIPELINE_DEPTH];
    reg [31:0] expected_drain_output = 0;


    reg [31:0] block_sum [0:1023];

	// PE DUT
	pe u0 (
		.clk            (clk),
        .rst_in         (rst_in),
        .ena_in         (ena_in),
        .acc_fin_in     (acc_fin_in),
        .acc_res_in     (acc_res_in),
        
        .a_in           ( {in_a_8, in_a_7, in_a_6, in_a_5, in_a_4, in_a_3, in_a_2, in_a_1} ),
        .b_in           ( {in_b_8, in_b_7, in_b_6, in_b_5, in_b_4, in_b_3, in_b_2, in_b_1} ),
        .drain_res_in   (drain_res_in),

        .rst_out        (rst_out),
        .ena_out        (ena_out),
        .acc_fin_out    (acc_fin_out),
        .acc_res_out    (acc_res_out),

        .a_out          ( {out_a_8, out_a_7, out_a_6, out_a_5, out_a_4, out_a_3, out_a_2, out_a_1} ),
        .b_out          ( {out_b_8, out_b_7, out_b_6, out_b_5, out_b_4, out_b_3, out_b_2, out_b_1} ),
        .drain_res_out  (drain_res_out),

        .drain_neig_valid   (drain_neig_valid),
        .drain_neig_rdy     (drain_neig_rdy),
        .drain_valid        (drain_valid),
        .drain_rdy          (drain_rdy),

        .acc                (debug_acc) 
	);

    event terminate_sim;
    event rst_trigger;
    event rst_trigger_done;
    event toggle_ena;
    event drain_output;
    event drain_output_done;


    always
        #10 clk = ~clk;

	initial
	begin
        $display($time, " << Simulation Starting >> ");
        ena_in = 1'b0;
        acc_res_in = 1'b0; 
        acc_fin_in = 1'b0; 
        drain_neig_valid = 1'b0;
        drain_neig_rdy = 1'b0;
        clk = 1'b0;
        load_dot16_zero;
        @(negedge clk);

        -> rst_trigger; 
        @(rst_trigger_done);
        -> toggle_ena; // ON 
        
        k = 0;
        repeat (1023) begin
            load_dot16(1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                       1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0);
            @(negedge clk);
            k = k + 1;
        end
            
        acc_res_in = 1'b1; 
        load_dot16(1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                   1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0);
        @(negedge clk);
        
        k = 0;
        repeat (1024) begin
            load_dot16(1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                       1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0);
            @(negedge clk);
            k = k + 1;
        end
       
        -> toggle_ena; // OFF
        repeat (10) begin
            load_dot16_zero;
            @(negedge clk);
        end
        ->toggle_ena; // ON

        k = 0;
        repeat (1024) begin
            load_dot16(1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                       1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0);
            @(negedge clk);
            k = k + 1;
        end
         
        k = 0;
        repeat(PIPELINE_DEPTH) begin
            load_dot16(1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                       1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0);
            @(negedge clk);
            k = k + 1;
        end
        acc_fin_in = 1'b1;

        repeat (1024 - PIPELINE_DEPTH) begin
            load_dot16(1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                       1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0);
            @(negedge clk);
            k = k + 1;
        end
       
        //acc_fin_in = 1'b0;
        drain_neig_rdy = 1'b1; 
        repeat (PIPELINE_DEPTH) begin
            load_dot16_zero;
            @(negedge clk);
        end
       
        acc_fin_in = 1'b0;
        k = 0;
        repeat (1024 + PIPELINE_DEPTH) begin
            load_dot16_zero;
            drain_neig_valid = 1'b1;
            drain_res_in = k;
            @(negedge clk);
            k = k + 1;
        end
           
        /*

        k = 0;
        repeat (1024) begin
            load_dot16(k, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                       1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0);
            @(negedge clk);
            k = k + 1;
        end
         
        // Start Putting the results into the drain fifo 
        // Into drain fifo is starting at the right time
        acc_fin_in = 1'b1;
        k = 0;
        repeat (1024) begin
            load_dot16(k, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                       1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0);
            @(negedge clk);
            k = k + 1;
        end
         
        acc_fin_in = 1'b0;
        drain_neig_rdy = 1'b1;
        -> drain_output;
        k = 0;
        repeat (1024) begin
            load_dot16(k, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                       1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0);
            @(negedge clk);
            k = k + 1;
        end
         
        repeat (PIPELINE_DEPTH) begin
            load_dot16_zero;
            @(negedge clk);
        end
         
        */ 

		$display($time, " << Simulation Finished >> ");
        -> terminate_sim;
	end

	
	initial
	begin
		$monitor($time, " << LOADED VALUES >>\n \
                     \ta: [%h, %h, %h, %h, %h, %h, %h, %h, %h, %h, %h, %h, %h, %h, %h, %h]\n \
                     \tb: [%h, %h, %h, %h, %h, %h, %h, %h, %h, %h, %h, %h, %h, %h, %h, %h]\n \
                     \tena:\t%h\n \
                     \n\t\t << Testbench Signals >>\n \
                     \tPE EXP Output:\t%d\n \
                     \n\t\t << Data Signals >>\n \
                     \tPE Drain Valid:\t%h\n \
                     \tPE Drain Ready:\t%h\n \
                     \tPE Debug Acc:\t%h\n \
                     \tPE Output:\t%d\n",
                        in_a_1[15:0], 
                        in_a_1[31:16], 
                        in_a_2[15:0], 
                        in_a_2[31:16],
                        in_a_3[15:0], 
                        in_a_3[31:16],
                        in_a_4[15:0], 
                        in_a_4[31:16],
                        in_a_5[15:0], 
                        in_a_5[31:16],
                        in_a_6[15:0], 
                        in_a_6[31:16],
                        in_a_7[15:0], 
                        in_a_7[31:16],
                        in_a_8[15:0], 
                        in_a_8[31:16],
                        in_b_1[15:0], 
                        in_b_1[31:16], 
                        in_b_2[15:0], 
                        in_b_2[31:16],
                        in_b_3[15:0], 
                        in_b_3[31:16],
                        in_b_4[15:0], 
                        in_b_4[31:16],
                        in_b_5[15:0], 
                        in_b_5[31:16],
                        in_b_6[15:0], 
                        in_b_6[31:16],
                        in_b_7[15:0], 
                        in_b_7[31:16],
                        in_b_8[15:0], 
                        in_b_8[31:16],
                        ena_in,
                        expected_drain_output, 
                        drain_valid,
                        drain_rdy,
                        debug_acc,
                        drain_res_out); 
	end


    // --------------------------
    // Verify the Expected Output
    // --------------------------
    /*
    always @ (posedge clk)
        if (expected_output[0] + block_sum[0] != out_c)
        begin
            $display($time, " << RESULT MISS MATCH >> ");
            $display("\t\t\tExpected Value: %h\t Got: %h", block_sum[0] + expected_output[0], out_c);
            -> terminate_sim;
        end
    */

    // ---------------------
    // Drain the Output FIFO
    // ---------------------
    /*
    always @ (posedge clk) begin   
        if(drain & ena) begin
            block_output[block_output_i] = out_c;
            block_output_i = block_output_i + 1;
        end
            
        if (block_output_i == 1025) begin
            block_output_i = 0;
            drain = 1'b0;
            $display($time, " << DRAINING COMPLETE >> ");
            -> drain_output_done;
        end
    end

    initial begin
        forever begin
            @ (drain_output);
            $display($time, " << DRAINING OUTPUT >> ");
            drain = 1'b1;
            block_output_i = 0;
        end
    end
    */  


    // ---------------------    
    // Verfiy Drained Result
    // ---------------------
    /*
    initial begin
        forever begin
            @ (drain_output_done);
            for(block_expect_i = 0; block_expect_i < 1024; block_expect_i = block_expect_i + 1) begin
                if(block_expect[block_expect_i] != block_output[block_expect_i]) begin
                    $display ($time, " << Block Miss-Match >> ");
                end
            end
        end
    end
    */

    // -------------------------
    // Shift the Expected Result
    // -------------------------
    initial
    begin
        forever
        begin
            @ (posedge clk);
            if(ena_in)
            begin
                for (i=0; i<PIPELINE_DEPTH-1; i=i+1)
                begin
                    expected_output[i] <= expected_output[i+1];
                end
                expected_output[PIPELINE_DEPTH-1] = new_output;
            end
        end
    end
    
    // -------------------
    // Shift the block sum
    // -------------------
    initial
    begin
        forever
        begin
            @ (posedge clk);
            if(ena_in)
            begin
                for (i=0; i<1023; i=i+1)
                begin
                    block_sum[i] <= block_sum[i+1];
                end
                block_sum[1023] = block_sum[0] + expected_output[0];
            end
        end
    end

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
    initial
    begin
        forever
        begin
            @ (toggle_ena);
            if(ena_in)
            begin
                $display($time, " << TOGGLE ENABLE - OFF >> ");
            end
            else
            begin
                $display($time, " << TOGGLE ENABLE - ON >> ");
            end
            ena_in = ~ena_in;
        end
    end

    // ---------------
    // Trigger a Reset
    // ---------------
    initial
    begin
        forever
        begin
            @ (rst_trigger);
            load_dot16_zero;
            @ (negedge clk);
            $display($time, " << TRIGGER RESET >> ");
            flush_pipeline;
            flush_block_sum;
            rst_in = 1'b1;
            @ (negedge clk);
            rst_in = 1'b0;
            -> rst_trigger_done;
        end
    end
    
    // ----------------------
    // Tasks for Loading Data
    // ----------------------
    
    task load_dot16;
        input signed [15:0] a1;
        input signed [15:0] a2;
        input signed [15:0] a3;
        input signed [15:0] a4;
        input signed [15:0] a5;
        input signed [15:0] a6;
        input signed [15:0] a7;
        input signed [15:0] a8;
        input signed [15:0] a9;
        input signed [15:0] a10;
        input signed [15:0] a11;
        input signed [15:0] a12;
        input signed [15:0] a13;
        input signed [15:0] a14;
        input signed [15:0] a15;
        input signed [15:0] a16;
        input signed [15:0] b1;
        input signed [15:0] b2;
        input signed [15:0] b3;
        input signed [15:0] b4;
        input signed [15:0] b5;
        input signed [15:0] b6;
        input signed [15:0] b7;
        input signed [15:0] b8;
        input signed [15:0] b9;
        input signed [15:0] b10;
        input signed [15:0] b11;
        input signed [15:0] b12;
        input signed [15:0] b13;
        input signed [15:0] b14;
        input signed [15:0] b15;
        input signed [15:0] b16;

        begin
            in_a_1[15:0]    = a1;
            in_a_1[31:16]   = a2;
            in_a_2[15:0]    = a3;
            in_a_2[31:16]   = a4;
            in_a_3[15:0]    = a5;
            in_a_3[31:16]   = a6;
            in_a_4[15:0]    = a7;
            in_a_4[31:16]   = a8;
            in_a_5[15:0]    = a9;
            in_a_5[31:16]   = a10;
            in_a_6[15:0]    = a11;
            in_a_6[31:16]   = a12;
            in_a_7[15:0]    = a13;
            in_a_7[31:16]   = a14;
            in_a_8[15:0]    = a15;
            in_a_8[31:16]   = a16;
            in_b_1[15:0]    = b1;
            in_b_1[31:16]   = b2;
            in_b_2[15:0]    = b3;
            in_b_2[31:16]   = b4;
            in_b_3[15:0]    = b5;
            in_b_3[31:16]   = b6;
            in_b_4[15:0]    = b7;
            in_b_4[31:16]   = b8;
            in_b_5[15:0]    = b9;
            in_b_5[31:16]   = b10;
            in_b_6[15:0]    = b11;
            in_b_6[31:16]   = b12;
            in_b_7[15:0]    = b13;
            in_b_7[31:16]   = b14;
            in_b_8[15:0]    = b15;
            in_b_8[31:16]   = b16;

             new_output = a1*b1
                                                    + a2*b2
                                                    + a3*b3
                                                    + a4*b4
                                                    + a5*b5
                                                    + a6*b6
                                                    + a7*b7
                                                    + a8*b8
                                                    + a9*b9
                                                    + a10*b10
                                                    + a11*b11
                                                    + a12*b12
                                                    + a13*b13
                                                    + a14*b14
                                                    + a15*b15
                                                    + a16*b16; 
        end
    endtask 

    task load_dot16_urand_range;
        input signed [15:0] max;
        input signed [15:0] min;

        begin
        load_dot16($urandom_range(max,min), $urandom_range(max,min), $urandom_range(max,min), $urandom_range(max,min), $urandom_range(max,min), $urandom_range(max,min), $urandom_range(max,min), $urandom_range(max,min), $urandom_range(max,min), $urandom_range(max,min), $urandom_range(max,min), $urandom_range(max,min), $urandom_range(max,min), $urandom_range(max,min), $urandom_range(max,min), $urandom_range(max,min),
                   $urandom_range(max,min), $urandom_range(max,min), $urandom_range(max,min), $urandom_range(max,min), $urandom_range(max,min), $urandom_range(max,min), $urandom_range(max,min), $urandom_range(max,min), $urandom_range(max,min), $urandom_range(max,min), $urandom_range(max,min), $urandom_range(max,min), $urandom_range(max,min), $urandom_range(max,min), $urandom_range(max,min), $urandom_range(max,min));

        end
    endtask 
    
    task load_dot16_rand;
        begin
        load_dot16($random, $random, $random, $random, $random, $random, $random, $random, $random, $random, $random, $random, $random, $random, $random, $random,
                   $random, $random, $random, $random, $random, $random, $random, $random, $random, $random, $random, $random, $random, $random, $random, $random);
        end
    endtask 
    
    task load_dot16_zero;
        begin
            load_dot16(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                       0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0);
        end
    endtask 

    task flush_pipeline;
        begin
            new_output = 0;
            for(i=0; i<PIPELINE_DEPTH; i=i+1)
            begin
                expected_output[i] = 0;
            end
        end
    endtask
    
    task flush_block_sum;
        begin
            for(i=0; i<1025; i=i+1)
            begin
                block_sum[i] = 0;
            end
        end
    endtask

endmodule

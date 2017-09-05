// ***************************************************************************
//                               INTEL CONFIDENTIAL
//
//        Copyright (C) 2008-2014 Intel Corporation All Rights Reserved.
//
// The source code contained or described herein and all  documents related to
// the  source  code  ("Material")  are  owned  by  Intel  Corporation  or its
// suppliers  or  licensors.    Title  to  the  Material  remains  with  Intel
// Corporation or  its suppliers  and licensors.  The Material  contains trade
// secrets  and  proprietary  and  confidential  information  of  Intel or its
// suppliers and licensors.  The Material is protected  by worldwide copyright
// and trade secret laws and treaty provisions. No part of the Material may be
// used,   copied,   reproduced,   modified,   published,   uploaded,  posted,
// transmitted,  distributed,  or  disclosed  in any way without Intel's prior
// express written permission.
//
// No license under any patent,  copyright, trade secret or other intellectual
// property  right  is  granted  to  or  conferred  upon  you by disclosure or
// delivery  of  the  Materials, either expressly, by implication, inducement,
// estoppel or otherwise.  Any license under such intellectual property rights
// must be express and approved by Intel in writing.
//
// Engineer :           Pratik Marolia
// Creation Date :    11-08-2014
// Last Modified :    Tue 23 Aug 2016 11:31:35 AM PDT
// Module Name :    fair_arbiter.sv
// Project :             
// Description :    
//
// ***************************************************************************

module fair_arbiter #(parameter NUM_INPUTS=2'h2, LNUM_INPUTS=$clog2(NUM_INPUTS))
(
    input   logic                    clk,
    input   logic                    reset,
    input   logic [NUM_INPUTS-1:0]   in_valid,
    input   logic [NUM_INPUTS-1:0]   hold_priority,     // do not shift the priority
    output  logic [LNUM_INPUTS-1:0]  out_select,
    output  logic [NUM_INPUTS-1:0]   out_select_1hot,
    output  logic                    out_valid
);
generate if(NUM_INPUTS<=4)  
begin   : gen_4way_arbiter
fair_arbiter_4way #(.NUM_INPUTS(NUM_INPUTS), 
                    .LNUM_INPUTS(LNUM_INPUTS)
                    )
inst_fair_arbiter_4way
(   .clk(clk),
    .reset(reset),
    .in_valid(in_valid),
    .hold_priority(hold_priority),
    .out_select(out_select),
    .out_select_1hot(out_select_1hot),
    .out_valid(out_valid)
);
end
else
begin : gen_mask_arb
fair_arbiter_w_mask #(.NUM_INPUTS(NUM_INPUTS),
                      .LNUM_INPUTS(LNUM_INPUTS)
                    )
inst_fair_arbiter_w_mask
(    .clk(clk),
    .reset(reset),
    .in_valid(in_valid),
    .hold_priority(hold_priority),
    .out_select(out_select),
    .out_select_1hot(out_select_1hot),
    .out_valid(out_valid)
);
end
endgenerate
endmodule

module fair_arbiter_4way #(parameter NUM_INPUTS=2'h2, LNUM_INPUTS=$clog2(NUM_INPUTS))
(
    input   logic                    clk,
    input   logic                    reset,
    input   logic [NUM_INPUTS-1:0]   in_valid,
    input   logic [NUM_INPUTS-1:0]   hold_priority,     // do not shift the priority
    output  logic [LNUM_INPUTS-1:0]  out_select,
    output  logic [NUM_INPUTS-1:0]   out_select_1hot,
    output  logic                    out_valid
);

reg [3:0]   fixed_width_in_valid;
reg [1:0]   fixed_width_last_select;
reg [3:0]   fixed_width_last_select_1hot;
reg         hold_out_valid;

always @(*)
begin
    fixed_width_in_valid=0;
    fixed_width_in_valid[NUM_INPUTS-1:0]=in_valid;
    
    out_valid = |in_valid;
    casez({fixed_width_last_select, fixed_width_in_valid})
                       {2'h0, 4'b??1?}  : begin  out_select  = 2'h1;
                                                 out_select_1hot = 4'b0010;
                       end
                       {2'h0, 4'b?1??}  : begin  out_select  = 2'h2;
                                                 out_select_1hot = 4'b0100;
                       end
                       {2'h0, 4'b1???}  : begin  out_select  = 2'h3;
                                                 out_select_1hot = 4'b1000;
                       end
                       {2'h0, 4'b???1}  : begin  out_select  = 2'h0;
                                                 out_select_1hot = 4'b0001;
                       end

                       {2'h1, 4'b?1??}  : begin  out_select  = 2'h2;
                                                 out_select_1hot = 4'b0100;
                       end
                       {2'h1, 4'b1???}  : begin  out_select  = 2'h3;
                                                 out_select_1hot = 4'b1000;
                       end
                       {2'h1, 4'b???1}  :begin   out_select  = 2'h0;
                                                 out_select_1hot = 4'b0001;
                       end
                       {2'h1, 4'b??1?}  :begin   out_select  = 2'h1;
                                                 out_select_1hot = 4'b0010;
                       end

                       {2'h2, 4'b1???}  :begin   out_select  = 2'h3;
                                                 out_select_1hot = 4'b1000;
                       end
                       {2'h2, 4'b???1}  :begin   out_select  = 2'h0;
                                                 out_select_1hot = 4'b0001;
                       end
                       {2'h2, 4'b??1?}  :begin   out_select  = 2'h1;
                                                 out_select_1hot = 4'b0010;
                       end
                       {2'h2, 4'b?1??}  :begin   out_select  = 2'h2;
                                                 out_select_1hot = 4'b0100;
                       end

                       {2'h3, 4'b???1}  :begin   out_select  = 2'h0;
                                                 out_select_1hot = 4'b0001;
                       end
                       {2'h3, 4'b??1?}  :begin   out_select  = 2'h1;
                                                 out_select_1hot = 4'b0010;
                       end
                       {2'h3, 4'b?1??}  :begin   out_select  = 2'h2;
                                                 out_select_1hot = 4'b0100;
                       end
                       {2'h3, 4'b1???}  :begin   out_select  = 2'h3;
                                                 out_select_1hot = 4'b1000;
                       end
                       default          :begin   out_select  = 2'h0;
                                                 out_select_1hot = 4'b0000;
                       end
    endcase
    if(hold_out_valid)
    begin
        out_select = fixed_width_last_select;
        out_select_1hot = fixed_width_last_select_1hot;
    end
end

always_ff@(posedge clk)
begin
    hold_out_valid <= 1'b0;
    if(out_valid) 
    begin
        fixed_width_last_select[LNUM_INPUTS-1:0] <= out_select;
        fixed_width_last_select_1hot[NUM_INPUTS-1:0] <= out_select_1hot;
        if(hold_priority[out_select])
            hold_out_valid <= 1'b1;
    end


     if(reset)
     begin
        fixed_width_last_select <= 0;
     end
end

   

endmodule

module fair_arbiter_w_mask #(parameter NUM_INPUTS=2'h2, LNUM_INPUTS=$clog2(NUM_INPUTS))

(
    input   logic                    clk,
    input   logic                    reset,
    input   logic [NUM_INPUTS-1:0]   in_valid,
    input   logic [NUM_INPUTS-1:0]   hold_priority,     // do not shift the priority
    output  logic [LNUM_INPUTS-1:0]  out_select,
    output  logic [NUM_INPUTS-1:0]   out_select_1hot,
    output  logic                    out_valid
);
    logic [LNUM_INPUTS-1:0] lsb_select, msb_select;
    logic [NUM_INPUTS-1:0]  lsb_mask;                       // bits [out_select-1:0]='0
    logic [NUM_INPUTS-1:0]  msb_mask;                       // bits [NUM_INPUTS-1:out_select]='0
    logic                   msb_in_notEmpty;

    always @(posedge clk)
    begin
        if(out_valid) 
        begin 
            if(hold_priority[out_select]==0)
            begin
                msb_mask    <= ~({{NUM_INPUTS-1{1'b1}}, 1'b0}<<out_select); 
                lsb_mask    <=   {{NUM_INPUTS-1{1'b1}}, 1'b0}<<out_select;
            end
            else
            begin
                msb_mask    <= 0;
                lsb_mask    <= 0;
                lsb_mask[out_select]    <= 1'b1;
            end
       end

        if(reset)
        begin
            msb_mask <= '1;
            lsb_mask <= '0;
        end
    end

    wire    [NUM_INPUTS-1:0]    msb_in = in_valid & lsb_mask;
    wire    [NUM_INPUTS-1:0]    lsb_in = in_valid & msb_mask;
    
    always_comb
    begin
        msb_in_notEmpty = |msb_in;
        out_valid       = |in_valid;
        lsb_select = 0;
        msb_select = 0;
        // search from lsb to msb
        for(int i=NUM_INPUTS-1'b1; i>=0; i--)
        begin
            if(lsb_in[i])
                lsb_select = i;
            if(msb_in[i])
                msb_select = i;
        end
        out_select = msb_in_notEmpty ? msb_select : lsb_select;
        out_select_1hot = 0;
        out_select_1hot[out_select] = 1'b1;
    end
endmodule


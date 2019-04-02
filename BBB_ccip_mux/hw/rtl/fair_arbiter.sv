//
// Copyright (c) 2018, Intel Corporation
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


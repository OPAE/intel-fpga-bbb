//
// Copyright (c) 2017, Intel Corporation
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


module trunc # (
		IN_WIDTH = 18,
		OUT_WIDTH = 16
		) (
		   in_data,
		   out_data
		   );

   // -------------------------------------------------------------------------

   localparam MSB = IN_WIDTH-1;
   localparam MSB_REMOVE = MSB-1 - (IN_WIDTH - OUT_WIDTH - 1);
   localparam MAX_POS = {1'b0, {(OUT_WIDTH-1){1'b1}}};
   localparam MAX_NEG = {1'b1, {(OUT_WIDTH-1){1'b0}}};

   // -------------------------------------------------------------------------

   input   wire  [IN_WIDTH-1:0]  in_data;
   output  wire [OUT_WIDTH-1:0]  out_data;

   // -------------------------------------------------------------------------

   wire [OUT_WIDTH-1:0] 	 sat_val;
   wire [OUT_WIDTH-1:0] 	 trunc_res;
   wire 			 sgn;
   wire 			 sat;

   // -------------------------------------------------------------------------

   // Perform the truncation
   // Calculate the basic truncation result
   assign trunc_res = in_data[OUT_WIDTH-1:0];

   // Extract the sign bit
   assign sgn = in_data[MSB];

   // Determine the saturation value
   assign sat_val = sgn ? MAX_NEG : MAX_POS;

   // Determine if the truncation removes any information in the MSB
   // For NEG, if any zeros have been removed than information has been lost
   // For POS, if any ones have been removed thand information has been lost
   assign sat = sgn ? ~&in_data[MSB-1:MSB_REMOVE] : |in_data[MSB-1:MSB_REMOVE]; 

   // Finally, if we need to either return the sat value or the trunc value.
   assign out_data = sat ? sat_val : trunc_res;

   // -------------------------------------------------------------------------

endmodule

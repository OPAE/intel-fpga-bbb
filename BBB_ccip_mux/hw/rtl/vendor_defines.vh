//-------------------------------------------------------------------------
//  TOOL and VENDOR Specific configurations
// ------------------------------------------------------------------------
// The TOOL and VENDOR definition necessary to correctly configure PAR project
// package currently supports
// Vendors : Xilinx & Altera
// Tools   : Synplify & Quartus II & Vivado
`define TOOL_QUARTUS
`define VENDOR_ALTERA
`ifndef VENDOR_DEFINES_VH
`define VENDOR_DEFINES_VH

    // Generate error if Vendor not defined
    `ifdef VENDOR_XILINX
            `ifdef VENDOR_ALTERA
                    ***Select only one VENDOR option***
            `endif
    `else
            `ifndef VENDOR_ALTERA
                    ***Select atleast one VENDOR option***
            `endif        
    `endif
    
    `ifdef VENDOR_ALTERA
        `define GRAM_AUTO "no_rw_check"                         // defaults to auto
        `define GRAM_BLCK "no_rw_check, M20K"
        `define GRAM_DIST "no_rw_check, MLAB"
    `endif
    
    //-------------------------------------------
    // Generate error if TOOL not defined
    `ifdef TOOL_QUARTUS
            `ifdef TOOL_SYNPLIFY
                    ***Select only one TOOL option***
            `endif
            `ifdef TOOL_VIVADO
                    ***Select only one TOOL option***
            `endif
    
    `elsif TOOL_SYNPLIFY
            `ifdef TOOL_QUARTUS
                    ***Select atleast one TOOL option***
            `endif        
            `ifdef TOOL_VIVADO
                    ***Select atleast one TOOL option***
            `endif        
    `else
            `ifndef TOOL_VIVADO
                    ***Select atleast one TOOL option***
            `endif                
    `endif
    
    `ifdef TOOL_QUARTUS
        `define GRAM_STYLE ramstyle
        `define NO_RETIMING  dont_retime
        `define NO_MERGE dont_merge
        `define KEEP_WIRE syn_keep = 1
    `endif
    
    `ifdef TOOL_SYNPLIFY
        `define GRAM_STYLE syn_ramstyle
        `define NO_RETIMING syn_allow_retiming=0
        `define NO_MERGE syn_preserve=1
        `define KEEP_WIRE syn_keep=1
    
        `ifdef VENDOR_XILINX
            `define GRAM_AUTO "no_rw_check"
            `define GRAM_BLCK "block_ram"
            `define GRAM_DIST "select_ram"
        `endif
    
    `endif 
    
    `ifdef TOOL_VIVADO  
        `define GRAM_STYLE ram_style
        `define NO_RETIMING dont_touch="true"
        `define NO_MERGE dont_touch="true"
        `define KEEP_WIRE keep="true"
    
        `ifdef VENDOR_XILINX
            `define GRAM_AUTO "auto_gram"
            `define GRAM_BLCK "block"
            `define GRAM_DIST "distributed"
        `endif
    `endif 


`endif

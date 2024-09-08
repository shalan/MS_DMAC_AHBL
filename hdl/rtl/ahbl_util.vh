/*
	Copyright 2020 Mohamed Shalan

	Licensed under the Apache License, Version 2.0 (the "License");
	you may not use this file except in compliance with the License.
	You may obtain a copy of the License at:

	http://www.apache.org/licenses/LICENSE-2.0

	Unless required by applicable law or agreed to in writing, software
	distributed under the License is distributed on an "AS IS" BASIS,
	WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
	See the License for the specific language governing permissions and
	limitations under the License.
*/

`define     SLAVE_OFF_BITS   last_HADDR[15:0]

`define AHB_REG(name, size, offset, init)   \
        reg [size-1:0] name; \
        wire ``name``_sel = wr_enable & (`SLAVE_OFF_BITS == offset); \
        always @(posedge HCLK or negedge HRESETn) \
            if (~HRESETn) \
                ``name`` <= 'h``init``; \
            else if (``name``_sel) \
                ``name`` <= HWDATA[``size``-1:0];\

`define REG_FIELD(reg_name, fld_name, from, to)\
    wire [``to``-``from``:0] ``reg_name``_``fld_name`` = reg_name[to:from]; 

`define AHB_READ assign HRDATA = 

`define AHB_REG_READ(name, offset) (`SLAVE_OFF_BITS == offset) ? name : 

`define AHB_SLAVE_IFC(prefix)   \
    input wire          ``prefix``HSEL,\
    input wire [31:0]   ``prefix``HADDR,\
    input wire [1:0]    ``prefix``HTRANS,\
    input wire          ``prefix``HWRITE,\
    input wire          ``prefix``HREADY,\
    input wire [31:0]   ``prefix``HWDATA,\
    input wire [2:0]    ``prefix``HSIZE,\
    output wire         ``prefix``HREADYOUT,\
    output wire [31:0]  ``prefix``HRDATA


`define AHB_MASTER_IFC(prefix) \
    output wire [31:0]  ``prefix``HADDR,\
    output wire [1:0]   ``prefix``HTRANS,\
    output wire [2:0] 	``prefix``HSIZE,\
    output wire         ``prefix``HWRITE,\
    output wire [31:0]  ``prefix``HWDATA,\
    input wire          ``prefix``HREADY,\
    input wire [31:0]   ``prefix``HRDATA 


`define AHB_SLAVE_EPILOGUE \
    reg             last_HSEL; \
    reg [31:0]      last_HADDR; \
    reg             last_HWRITE; \
    reg [1:0]       last_HTRANS; \
    \
    always@ (posedge HCLK or negedge HRESETn) begin\
        if(!HRESETn) begin \
            last_HSEL       <= 0;   \
            last_HADDR      <= 0;  \
            last_HWRITE     <= 0; \
            last_HTRANS     <= 0; \
        end else if(HREADY) begin\
            last_HSEL       <= HSEL;   \
            last_HADDR      <= HADDR;  \
            last_HWRITE     <= HWRITE; \
            last_HTRANS     <= HTRANS; \
        end\
    end\
    \
    wire rd_enable = last_HSEL & (~last_HWRITE) & last_HTRANS[1]; \
    wire wr_enable = last_HSEL & (last_HWRITE) & last_HTRANS[1];


`define     SLAVE_SIGNAL(signal, indx)    S``indx``_``signal``

`define HSEL_GEN(SLAVE_ID)\
    assign ``SLAVE_ID``_HSEL    = (PAGE     == ``SLAVE_ID``_PAGE);\
    wire ``SLAVE_ID``_AHSEL   = (APAGE    == ``SLAVE_ID``_PAGE);

`define AHB_MUX\
    assign {HREADY, HRDATA} =

`define AHB_MUX_SLAVE(SLAVE_ID)\
    (``SLAVE_ID``_AHSEL) ? {``SLAVE_ID``_HREADYOUT, ``SLAVE_ID``_HRDATA} :

`define AHB_MUX_DEFAULT\
    {1'b1, 32'hFEADBEEF};\

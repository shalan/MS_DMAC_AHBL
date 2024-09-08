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

`timescale          1ns/1ps
`default_nettype    none

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

/*
    DMA Controller
    0x00:   CTRL Register 
            0: EN
            8-11: Transfer tigger; only 0000 (S/W) is supported
            16-17: Source data type; 0: byte, 1: half word, 2: word
            10-20: Source Address Auto increment value (0, 1, 2, and 4)
            24-25: Destination data type; 0: byte, 1: half word, 2: word
            26-28: Destination Address Auto increment value (0, 1, 2, and 4)
    0x04:   Status Register
            0: Done
    0x08:   Source Address (SADDR) Register
    0x0C:   Destination Address (DADDR) Register
    0x10:   Frame Size (FSZ) Register
    0x14:   SW Trigger (SW) Register 
    0x18:   Frame Count (FC) Register
*/

/*
    To do:
        - DEST_AI & SRC_AI fields to be updated to 3 bits each
        - The increment steps are determined by DEST_AI & SRC_AI
*/

module MS_DMAC_AHBL (
    input   wire    HCLK,
    input   wire    HRESETn,
    
    output  wire    IRQ,

    // AHB-Lite Slave Interface
    
    input wire          HSEL,
    input wire [31:0]   HADDR,
    input wire [1:0]    HTRANS,
    input wire          HWRITE,
    input wire          HREADY,
    input wire [31:0]   HWDATA,
    input wire [2:0]    HSIZE,
    output wire         HREADYOUT,
    output wire [31:0]  HRDATA,

    // AHB-Lite Master Interface
    
    output wire [31:0]  M_HADDR,
    output wire [1:0]   M_HTRANS,
    output wire [2:0] 	M_HSIZE,
    output wire         M_HWRITE,
    output wire [31:0]  M_HWDATA,
    input wire          M_HREADY,
    input wire [31:0]   M_HRDATA,

    // Peripherals IRQ lines
    input   wire    PIRQ
);

    localparam  CTRL_REG_OFF    =   8'h00, 
                STATUS_REG_OFF  =   8'h04, 
                SADDR_REG_OFF   =   8'h08,
                DADDR_REG_OFF   =   8'h0C,
                SIZE_REG_OFF    =   8'h10,
                TRIG_REG_OFF    =   8'h14,
                FC_REG_OFF      =   8'h18;

    wire [31:0] STATUS_REG;
    wire done;

    assign      STATUS_REG  = {31'h0,done};
    assign      IRQ         = (CTRL_REG_TRIGGER == 4'b0) ?  done : (done & (FC_REG == 8'b1));

    //
    // AHB Slave Logic
    //
    
    // CTRL Register Fields
    
    wire [0-0:0] CTRL_REG_EN = CTRL_REG[0:0];
    
    wire [11-8:0] CTRL_REG_TRIGGER = CTRL_REG[11:8];
    
    wire [17-16:0] CTRL_REG_SRC_TYPE = CTRL_REG[17:16];
    
    wire [20-18:0] CTRL_REG_SRC_AI = CTRL_REG[20:18];
    
    wire [25-24:0] CTRL_REG_DEST_TYPE = CTRL_REG[25:24];
    
    wire [28-26:0] CTRL_REG_DEST_AI = CTRL_REG[28:26];
    
    reg             last_HSEL;
    reg [31:0]      last_HADDR;
    reg             last_HWRITE;
    reg [1:0]       last_HTRANS;

    always@ (posedge HCLK or negedge HRESETn) begin
        if(!HRESETn) begin
            last_HSEL       <= 0;
            last_HADDR      <= 0;
            last_HWRITE     <= 0;
            last_HTRANS     <= 0;
        end else if(HREADY) begin
            last_HSEL       <= HSEL;
            last_HADDR      <= HADDR;
            last_HWRITE     <= HWRITE;
            last_HTRANS     <= HTRANS;
        end
    end

    wire rd_enable = last_HSEL & (~last_HWRITE) & last_HTRANS[1];
    wire wr_enable = last_HSEL & (last_HWRITE) & last_HTRANS[1];

    
        reg [32-1:0] CTRL_REG;
        wire CTRL_REG_sel = wr_enable & (last_HADDR[15:0] == CTRL_REG_OFF);
        always @(posedge HCLK or negedge HRESETn)
            if (~HRESETn)
                CTRL_REG <= 'h0;
            else if (CTRL_REG_sel)
                CTRL_REG <= HWDATA[32-1:0];
   
    
        reg [32-1:0] SADDR_REG;
        wire SADDR_REG_sel = wr_enable & (last_HADDR[15:0] == SADDR_REG_OFF);
        always @(posedge HCLK or negedge HRESETn)
            if (~HRESETn)
                SADDR_REG <= 'h0;
            else if (SADDR_REG_sel)
                SADDR_REG <= HWDATA[32-1:0];

    
        reg [32-1:0] DADDR_REG;
        wire DADDR_REG_sel = wr_enable & (last_HADDR[15:0] == DADDR_REG_OFF);
        always @(posedge HCLK or negedge HRESETn)
            if (~HRESETn)
                DADDR_REG <= 'h0;
            else if (DADDR_REG_sel)
                DADDR_REG <= HWDATA[32-1:0];

    
        reg [16-1:0] SIZE_REG;
        wire SIZE_REG_sel = wr_enable & (last_HADDR[15:0] == SIZE_REG_OFF);
        always @(posedge HCLK or negedge HRESETn)
            if (~HRESETn)
                SIZE_REG <= 'h0;
            else if (SIZE_REG_sel)
                SIZE_REG <= HWDATA[16-1:0];

    //`AHB_REG(FC_REG, 8, FC_REG_OFF, 0)
     
    reg [7:0]       FC_REG;
    wire FC_REG_sel = wr_enable & (last_HADDR[7:0] == FC_REG_OFF);
    always @(posedge HCLK or negedge HRESETn)
    begin
        if (~HRESETn)
            FC_REG <= 8'h0;
        else if (FC_REG_sel)
            FC_REG <= HWDATA[7:0];
        else if(done && (state == WD_STATE))
            FC_REG <= FC_REG - 1'b1;
    end  


    reg             TRIG_REG;
    wire TRIG_REG_sel = wr_enable & (last_HADDR[7:0] == TRIG_REG_OFF);
    always @(posedge HCLK or negedge HRESETn)
    begin
        if (~HRESETn)
            TRIG_REG <= 1'h0;
        else if (TRIG_REG_sel)
            TRIG_REG <= HWDATA[0];
        else if(done)
            TRIG_REG <= 1'h0;
    end  

    

    assign HRDATA =
        (last_HADDR[15:0] == CTRL_REG_OFF) ? CTRL_REG :
        (last_HADDR[15:0] == STATUS_REG_OFF) ? STATUS_REG :
        (last_HADDR[15:0] == SADDR_REG_OFF) ? SADDR_REG :
        (last_HADDR[15:0] == DADDR_REG_OFF) ? DADDR_REG :
        (last_HADDR[15:0] == SIZE_REG_OFF) ? SIZE_REG :
        (last_HADDR[15:0] == TRIG_REG_OFF) ? TRIG_REG :
        (last_HADDR[15:0] == FC_REG_OFF) ? FC_REG :
        32'hDEADBEEF; 

    //
    // AHB MAster Logic
    //
    
    wire trigger =  (TRIG_REG && (CTRL_REG_TRIGGER == 4'b0)) ||
                    (|(PIRQ & CTRL_REG_TRIGGER) != 1'b0);

    // The DMAC FSM
    localparam  IDLE_STATE  =   5'b00001,
                RA_STATE    =   5'b00010, 
                RD_STATE    =   5'b00100,
                WA_STATE    =   5'b01000,
                WD_STATE    =   5'b10000;

    reg [4:0] state, nstate;

    always @(posedge HCLK or negedge HRESETn)
        if(!HRESETn) state <= IDLE_STATE;
        else state <= nstate;

    always @*
        case(state)
            IDLE_STATE: if(trigger & CTRL_REG_EN) 
                            nstate = RA_STATE; 
                        else 
                            nstate = IDLE_STATE;
            RA_STATE:   if(M_HREADY) nstate = RD_STATE; else nstate = RA_STATE;
            RD_STATE:   if(M_HREADY) nstate = WA_STATE; else nstate = RD_STATE;
            WA_STATE:   if(M_HREADY) nstate = WD_STATE; else nstate = WA_STATE;
            WD_STATE:   if(M_HREADY) begin
                            if(done)
                                nstate = IDLE_STATE;
                            else  
                                nstate = RA_STATE; 
                        end else nstate = WD_STATE;
        endcase 

    // The Address Sequence Generator
    reg  [15:0] CNTR;
    wire [17:0] R_CNTR  = (CTRL_REG_SRC_AI == 4) ? CNTR << 2 :
                          (CTRL_REG_SRC_AI == 2) ? CNTR << 1 : 
                          (CTRL_REG_SRC_AI == 1) ? CNTR      : CNTR;
    wire [17:0] W_CNTR  = (CTRL_REG_DEST_AI == 4) ? CNTR << 2 :
                          (CTRL_REG_DEST_AI == 2) ? CNTR << 1 : 
                          (CTRL_REG_DEST_AI == 1) ? CNTR      : CNTR;
    wire [31:0] R_ADDR = (CTRL_REG_SRC_AI != 0) ? (SADDR_REG + R_CNTR) : SADDR_REG;
    wire [31:0] W_ADDR = (CTRL_REG_DEST_AI != 0) ? (DADDR_REG + W_CNTR) : DADDR_REG;

    always @(posedge HCLK or negedge HRESETn)
        if(!HRESETn) 
            CNTR <= 16'h0;
        else if (TRIG_REG_sel) 
            CNTR <= 16'h0;
        else if(done && (state == WD_STATE))
            CNTR <= 16'h0;
        else if((state==WD_STATE) & M_HREADY & (CTRL_REG_SRC_AI | CTRL_REG_DEST_AI)/* & TRIG_REG*/) 
            CNTR <= CNTR + 16'h1;

    assign done = (CNTR == SIZE_REG) & CTRL_REG_EN;

    assign HREADYOUT = 1'b1;

    // MASTER Port
    reg [31:0] rdata;

    always @(posedge HCLK)
        if((state == RD_STATE) & M_HREADY)
            rdata <= M_HRDATA;

    assign M_HADDR = (state == RA_STATE) ? R_ADDR : W_ADDR;
    assign M_HTRANS =  M_HREADY & ((state == RA_STATE) || (state == WA_STATE)) ? 2'h2 : 2'h0;
    assign M_HWDATA = (state == WD_STATE)  ? rdata : 32'hEEEEEEEE;
    assign M_HWRITE = (state == WA_STATE)  ? 1'b1 : 1'b0; 
    assign M_HSIZE = (state == RA_STATE) ? CTRL_REG_SRC_TYPE : CTRL_REG_DEST_TYPE;

endmodule

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

`include            "ahbl_util.vh"

/*
    DMA Controller
    0x00:   CTRL Register 
            0: EN
            1-4: Transfer tigger; only 0000 (S/W) is supported
            8-9: Source data type; 0: byte, 1: half word, 2: word
            10: Source Address Auto increment
            16-17: Destination data type; 0: byte, 1: half word, 2: word
            18: Destination Address Auto increment
    0x04:   Status Register
            0: Done
    0x08:   Source Address (SADDR) Register
    0x0C:   Destination Address (DADDR) Register
    0x10:   Frame Size (FSZ) Register
    0x14:   SW Trigger (SW) Register 
    0x18:   Frame Count (FC) Register
*/

module MS_DMAC_AHBL (
    input   wire    HCLK,
    input   wire    HRESETn,
    
    output  wire    IRQ,

    // AHB-Lite Slave Interface
    `AHB_SLAVE_IFC(),

    // AHB-Lite Master Interface
    `AHB_MASTER_IFC(M_),

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

    `AHB_SLAVE_EPILOGUE

    `AHB_REG(CTRL_REG, 32, CTRL_REG_OFF, 0)   
    `AHB_REG(SADDR_REG, 32, SADDR_REG_OFF, 0)
    `AHB_REG(DADDR_REG, 32, DADDR_REG_OFF, 0)
    `AHB_REG(SIZE_REG, 16, SIZE_REG_OFF, 0)
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

    // CTRL Register Fields
    `REG_FIELD(CTRL_REG, EN, 0, 0)
    `REG_FIELD(CTRL_REG, TRIGGER, 8, 11)
    `REG_FIELD(CTRL_REG, SRC_TYPE, 16, 17)
    `REG_FIELD(CTRL_REG, SRC_AI, 18, 18)
    `REG_FIELD(CTRL_REG, DEST_TYPE, 24, 25)
    `REG_FIELD(CTRL_REG, DEST_AI, 26, 26)

    `AHB_READ
        `AHB_REG_READ(CTRL_REG, CTRL_REG_OFF)
        `AHB_REG_READ(STATUS_REG, STATUS_REG_OFF)
        `AHB_REG_READ(SADDR_REG, SADDR_REG_OFF)
        `AHB_REG_READ(DADDR_REG, DADDR_REG_OFF)
        `AHB_REG_READ(SIZE_REG, SIZE_REG_OFF)
        `AHB_REG_READ(TRIG_REG, TRIG_REG_OFF)
        `AHB_REG_READ(FC_REG, FC_REG_OFF)
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
    wire [17:0] R_CNTR_TYPE = CNTR << CTRL_REG_SRC_TYPE;
    wire [17:0] W_CNTR_TYPE = CNTR << CTRL_REG_DEST_TYPE;
    wire [31:0] R_ADDR = (CTRL_REG_SRC_AI) ? (SADDR_REG + R_CNTR_TYPE) : SADDR_REG;
    wire [31:0] W_ADDR = CTRL_REG_DEST_AI ? (DADDR_REG + W_CNTR_TYPE) : DADDR_REG;

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

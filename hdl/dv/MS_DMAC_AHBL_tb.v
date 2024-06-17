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

`include            "tb_utils.vh"

module MS_DMAC_AHBL_tb;

    localparam  CTRL_REG_OFF    =   8'h00, 
                STATUS_REG_OFF  =   8'h04, 
                SADDR_REG_OFF   =   8'h08,
                DADDR_REG_OFF   =   8'h0C,
                SIZE_REG_OFF    =   8'h10,
                TRIG_REG_OFF    =   8'h14,
                FC_REG_OFF      =   8'h18;

    

    wire        IRQ;
    reg         PIRQ;

    reg         HSEL;
    reg[31:0]   HADDR;
    reg[1:0]    HTRANS;
    reg         HWRITE;
    reg         HREADY;
    reg[31:0]   HWDATA;
    reg[2:0]    HSIZE;
    wire        HREADYOUT;
    wire[31:0]  HRDATA;

    wire [31:0]  M_HADDR;
    wire [1:0]   M_HTRANS;
    wire [2:0] 	 M_HSIZE;
    wire         M_HWRITE;
    wire [31:0]  M_HWDATA;
    reg          M_HREADY;
    reg [31:0]   M_HRDATA;

    `TB_CLK(HCLK, 20)          
    `TB_SRSTN(HRESETn, HCLK, 173)
    `TB_DUMP("MS_DMAC_AHBL_tb.vcd", MS_DMAC_AHBL_tb, 0)
    `TB_FINISH(100_1000)     

    `include            "ahbl_tasks.vh"

    MS_DMAC_AHBL DUV (
        .HCLK(HCLK),
        .HRESETn(HRESETn),
    
        .IRQ(IRQ),
        .PIRQ(PIRQ),

        .HSEL(HSEL),
        .HADDR(HADDR),
        .HTRANS(HTRANS),
        .HWRITE(HWRITE),
        .HREADY(HREADY),
        .HWDATA(HWDATA),
        .HSIZE(HSIZE),
        .HREADYOUT(HREADYOUT),
        .HRDATA(HRDATA),

        .M_HADDR(M_HADDR),
        .M_HTRANS(M_HTRANS),
        .M_HSIZE(M_HSIZE),
        .M_HWRITE(M_HWRITE),
        .M_HWDATA(M_HWDATA),
        .M_HREADY(M_HREADY),
        .M_HRDATA(M_HRDATA)
    );
    
    initial begin
        PIRQ = 0;
        HREADY = 1;
        M_HREADY = 1;
        M_HRDATA = 32'hCAFEBABE;

        // Wait for the reset to be de-asserted
        @(posedge HRESETn);
        ahbl_w_write(SADDR_REG_OFF, 32'h4000_0000);
        ahbl_w_write(DADDR_REG_OFF, 32'h4000_0000);
        ahbl_w_write(SIZE_REG_OFF, 16'h0004);
        ahbl_w_write(FC_REG_OFF, 8'h02);
        ahbl_w_write(CTRL_REG_OFF, 32'h06_06_01_01);

        // Trigger the DMAC twice using PIRQ
        #57;
        @(posedge HCLK) PIRQ = 1;
        @(posedge M_HTRANS[1]) PIRQ = 0;

        `TB_WAIT_FOR_CLOCK_CYC(HCLK, 25)

        @(posedge HCLK) PIRQ = 1;
        @(posedge M_HTRANS[1]) PIRQ = 0;

        `TB_WAIT_FOR_CLOCK_CYC(HCLK, 25)

        // Switch to SW Triggering
        ahbl_w_write(CTRL_REG_OFF, 32'h06_06_00_01);
        `TB_WAIT_FOR_CLOCK_CYC(HCLK, 5)
        ahbl_w_write(TRIG_REG_OFF, 1'h1);
    end
    
endmodule
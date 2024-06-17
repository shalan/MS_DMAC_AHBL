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
    task ahbl_w_read;
        input [31:0] addr;
        begin
            //@(posedge HCLK);
            wait (HREADY == 1'b1);
            @(posedge HCLK);
            #1;
            HSEL = 1'b1;
            HTRANS = 2'b10;
            // First Phase
            HADDR = addr;
            HWRITE = 1'b0;
            @(posedge HCLK);
            HSEL = 1'b0;
            HTRANS = 2'b00;
            #2;
            wait (HREADY == 1'b1);
            @(posedge HCLK) 
                #1 $display("Read 0x%8x from 0x%8x", HRDATA, addr);
        end
    endtask

    task ahbl_w_write;
        input [31:0] addr;
        input [31:0] data;
        begin
            //@(posedge HCLK);
            wait (HREADY == 1'b1);
            @(posedge HCLK);
            #1;
            HSEL = 1'b1;
            HTRANS = 2'b10;
            // First Phase
            HADDR = addr;
            HWRITE = 1'b1;
            @(posedge HCLK);
            HWDATA = data;
            HSEL = 1'b0;
            HTRANS = 2'b00;
            #2;
            wait (HREADY == 1'b1);
        end
    endtask

    
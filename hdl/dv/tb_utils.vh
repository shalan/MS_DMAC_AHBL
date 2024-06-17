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

`define     TB_CLK(clk, period)                 reg clk=0; always #(period/2) clk = !clk;
`define     TB_SRSTN(rstn, clk, duration)       reg rstn=0; initial begin #duration; @(posedge clk) rstn = 1; end
`define     TB_ESRST(rst, pol, clk, duration, e_rst_start, e_rst_done)   \ 
                                                event e_rst_start, e_rst_done; \
                                                initial forever begin \
                                                    @(e_rst_start); \
                                                    rst = pol; \
                                                    #duration; \
                                                    @(posedge clk) rst = ~pol; \
                                                    -> e_rst_done; \
                                                end
`define     TB_DUMP(file, mod, level)           initial begin $dumpfile(file); $dumpvars(level, mod); end
`define     TB_FINISH(length)                   initial begin #``length``; $display("Verification Failed: Timeout");$finish; end
`define     TB_WAIT_FOR_CLOCK_CYC(clk, count)   repeat(count) begin @(posedge clk); end
// FPGA projects using Verilog/ VHDL 
// fpga4student.com
// Verilog code for D Flip FLop
// Verilog code for falling edge D flip flop 
module FallingEdge_DFlipFlop(D,clk,Q);
	
	input D; // Data input 
	input clk; // clock input 
	output reg Q; // output Q 
	
	always @(negedge clk) 
	begin
		 Q = D; 
	end 
endmodule 
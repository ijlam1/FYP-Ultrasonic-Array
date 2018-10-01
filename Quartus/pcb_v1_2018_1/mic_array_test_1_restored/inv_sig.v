/* Module that takes an input signal and inverts it */

module inv_sig(clk_in, sig_in, sig_out);

	/* Defining inputs and outputs */
	input clk_in;						// high frequency clock
	input sig_in;						// input signal to invert
	output sig_out;					// output signal (inverted input)
	
	/* Defining intermediary signals */
	reg sig_reg;
	
	always @(posedge clk_in) begin
		
		/* On a rising clock edge, invert input signal */
		sig_reg = !sig_in;
		
	end
	
	assign sig_out = sig_reg;
	
endmodule
		
/* Module that connects the 40kHz clock signal to the GPIO pin */

module transmitter_connection(clk_in, clk_40khz, transmitter_pin, transmitter_on);

	/* Defining inputs and outputs */
	input clk_in;						// high frequency clock
	input clk_40khz;					// 40khz clock
	output transmitter_pin;			// pin which the transmitter is connected to
	input transmitter_on;			// input determining when the transmitter is on
	
	/* Defining intermediary signals */
	reg transmitter_pin_reg;
	
	always @(posedge clk_in) begin
		
		/* Test if want to turn transmitter on */
		if (transmitter_on) begin
			
			/* If transmitter is meant to be on */
			transmitter_pin_reg = clk_40khz;
			
		end
		else begin
			
			/* If want transmitter to be off */
			transmitter_pin_reg = 0;
			
		end
		
	end
	
	assign transmitter_pin = transmitter_pin_reg;
	
endmodule
		
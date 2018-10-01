/* Module that divides input clock by a certain number, defined by div_num */

module clk_div (clk, clk_out, reset);
	
	/* Defining inputs and outputs */
	input clk;
	output clk_out;
	input reset;
 
	/* Defining intermediary signals */
	reg [2:0] counter;
	wire [2:0] counter_next;		// wire to act as storage variable
	reg clk_track;		// variable to track clock out value

 
	/* Always block triggered on rising clock edge or reset input */
	always @(posedge clk or posedge reset) begin
		
		/* If statement for reset signal */
		if (reset) begin
			counter <= 0;
			clk_track <= 1'b0;
		end
		
		/* Else if for counter reaching div_num value*/
		else if (counter_next == 6)
			begin
				counter <= 0;
				clk_track <= ~clk_track;
			end
		
		/* Else to iterate counter to the next value */
		else
			counter <= counter_next;
		end
		
		assign counter_next = counter+1;
		assign clk_out = clk_track;
		
endmodule





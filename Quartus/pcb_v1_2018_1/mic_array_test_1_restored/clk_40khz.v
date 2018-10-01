/* Module that divides 50MHz input clock by 1250 */

module clk_40khz (clk, clk_out, reset);
	
	/* Defining inputs and outputs */
	input clk;
	output clk_out;
	input reset;
 
	/* Defining intermediary signals */
	reg [9:0] counter;
	wire [9:0] counter_next;		// wire to act as storage variable
	reg clk_track;		// variable to track clock out value

 
	/* Always block triggered on rising clock edge or reset input */
	always @(posedge clk or posedge reset) begin
		
		/* If statement for reset signal */
		if (reset) begin
			counter <= 0;
			clk_track <= 1'b0;
		end
		
		/* Else if toggling output clock after counter reaches 625*/
		else if (counter_next == 625)
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





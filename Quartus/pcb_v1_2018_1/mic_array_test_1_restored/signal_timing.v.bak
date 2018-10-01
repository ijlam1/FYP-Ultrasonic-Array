/* Module that accepts a clock input and sends out control signals at certain times */

module signal_timing(clk_in, reset, transmitter_on, mic_on, mic_rec_delay);
	
	/* Defining inputs and outputs */
	input clk_in;			// input clk, set to 40kHz
	input reset;			// active low reset, assign to switch
	output transmitter_on;		// output signal used to determine at what points the ultrasonic transmitter should be on
	output mic_on;					// output signal used to determine at what point the mics turn on
	input [31:0] mic_rec_delay;			// input defining how long the delay between the transmit pulse turns on and the recording of mic data, in microseconds
	
	/* Defining intermediary signals */
	reg [31:0] counter;					// counter incrementing on every rising clock edge
	reg transmitter_on_wire;
	reg mic_on_wire;
	

	
	always @(posedge clk_in or posedge reset) begin
		
		/* If statement checking if reset is low */
		if (reset) begin
			
			/* if reset is low, reset counter, turn off transmitter and mic */
			counter = 0;
			transmitter_on_wire = 0;
			mic_on_wire = 0;
		end
		else begin
			
			/* if reset is not low, test counter conditions then increment counter */
			//mic_on_wire = 1;		// turning on mics
			
			/* Turning on transmitter after mics have been on 6ms */
			/* Due to signal capture parameters, mic data is saved after approximately 6ms */
			if ((240 < counter) && (counter < 280)) begin
				transmitter_on_wire = 1;
			end
			else begin
				
				/* Turning off transmitter outside of on window */
				transmitter_on_wire = 0;
			end
			
			/* Turning on mics after set number of milliseconds after transmit pulse starts*/
			/* Note: 40khz clock, therefore, 40 counter counts per millisecond */
			/* Set mic_rec_delay = 0 to capture when transmit pulse turns on */
			if (counter > (40*mic_rec_delay)/1000) begin
				mic_on_wire = 1;
			end
			
		
			/* Incrementing counter */
			counter = counter + 1;
		
		end
		
	end
	
	/* Assigning intermediary wires to outputs */
	assign transmitter_on = transmitter_on_wire;
	assign mic_on = mic_on_wire;
	
	
endmodule
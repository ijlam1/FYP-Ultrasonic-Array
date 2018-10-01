/* Module connecting the mic output PDM signal to the CIC Filter with a 16 bit output */
/* This code is written by Roger Zou, Student ID: 26029901 */
/* Last modified on: 25.07.2018 */

module mic_cicfilter_connection  (clk_in, mic_in, filter_out, switch_reset, out_valid_clk);

	/* Defining inputs and outputs */
	input clk_in;						// input clock frequency used to drive the registers of the cic filter
											// same clock that samples the microphones
	input mic_in;						// input signal from a microphone, PDM coded bit stream
	output [15:0] filter_out;		// 16-bit output of the cic filter, will be decimated by R = 14
	input switch_reset;				// using an input to manually reset the filter
	output out_valid_clk;			// out_valid defines when the output of the filter is valid, and is effectively the downsampled clock rate, (50Mhz/12)/(R=14)
											// out_valid_clk is an optional output

	// CIC Filter inputs
	//reg clk;    					// defined by clk_in
	wire reset_n;					// active low reset, consider connecting up to a button on the FPGA initially for testing, need to reset before CIC filter properly functions
	wire clken;						// optional top level clock enable, set to always be on, as in testbench
	reg[0:0] in_data;				// set to mic_in
	wire[15:0] out_data;			// assign to filter_out
	wire[1:0] in_error;			// assume no input error
	wire[1:0] out_error;			// can connect up to monitor if error in output, otherwise don't need to
	wire in_valid;					// input data from mics should always be valid, therefore, set to 1
	wire out_ready;				// downstream module should always be read to receive data, set to 1
	wire in_ready;					// will be set to 1 if filter ready to receive data
	wire out_valid;				// asserted when output data is valid, monitor this to extract out_data?
	
	
	// Clock enable always enabled
	assign clken = 1'b1;
	
	// out_ready always ready
	assign out_ready = 1'b1;
	
	// no input error
	assign in_error = 2'b0;
	
	// initialising register variables
//	initial
//   begin
//      // Reset Generation
//      reset_n = 1'b0;
//      #92 reset_n = 1'b1;
//		
//		// input data from mics always valid
//		in_valid <= 1'b1;
//		
//   end
//	
	assign reset_n = 1'b1;
	assign in_valid = 1'b1;
	
	//////////////////////////////////////////////////////////////////////////////////////////////
   // Move mic data into in_data if CIC Filter ready to receive                                                                 
   //////////////////////////////////////////////////////////////////////////////////////////////
	always @ (posedge clk_in)
	begin
		if (in_ready == 1'b1)
		begin
			in_data <= mic_in;
		end
	end
	
	////////////////////////////////////////////////////////////////////////////////////////////
   // Write data output to 16 bit output                                               
   ////////////////////////////////////////////////////////////////////////////////////////////
//   always @ (posedge clk_in)
//   begin
//      if (out_valid == 1'b1)
//      begin
//         filter_out <= out_data;
//      end
//   end
//	
	assign filter_out = out_data;
	assign out_valid_clk = out_valid;
	
  ////////////////////////////////////////////////////////////////////////////////////////////
  // CIC Module Instantiation                                                               
  ////////////////////////////////////////////////////////////////////////////////////////////
  
	cic_filter cic_filter_inst (
      .clk(clk_in),
      .clken(clken),
      .reset_n(switch_reset),
      .in_ready(in_ready),
      .in_valid(in_valid),
      .in_data(in_data),
      .out_data(out_data),
      .in_error(in_error),
      .out_error(out_error),
      .out_ready(out_ready),
      .out_valid(out_valid)
      );

	
endmodule
	

	
/* CIC filter instantiation and input-output definitions 
module cic_filter (
	clk,
	clken,
	reset_n,
	in_data,
	in_valid,
	out_ready,
	in_error,
	out_data,
	in_ready,
	out_valid,
	out_error);


	input		clk;
	input		clken;
	input		reset_n;
	input		in_data;
	input		in_valid;
	input		out_ready;
	input	[1:0]	in_error;
	output	[15:0]	out_data;
	output		in_ready;
	output		out_valid;
	output	[1:0]	out_error;


	cic_filter_cic	cic_filter_cic_inst(
		.clk(clk),
		.clken(clken),
		.reset_n(reset_n),
		.in_data(in_data),
		.in_valid(in_valid),
		.out_ready(out_ready),
		.in_error(in_error),
		.out_data(out_data),
		.in_ready(in_ready),
		.out_valid(out_valid),
		.out_error(out_error));
endmodule
*/
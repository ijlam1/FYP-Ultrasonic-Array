/* Top level module that instantiates inputs and ouptuts */

module mic_array_test_1(SW, KEY, LEDR, LEDG, HEX7, HEX6, HEX5, HEX4, HEX3, HEX2, HEX1, HEX0, GPIO_1, CLOCK_27, CLOCK_50);		// Declares input and output ports
		input [17:0] SW;		// input switches
		input [3:0] KEY;			// KEYs are naturally 1 and 0 when depressed
		output [17:0] LEDR;		// red LED outputs
		output [8:0] LEDG;
		output [6:0] HEX0, HEX1, HEX2, HEX3, HEX4, HEX5, HEX6, HEX7;		// HEX0 display output
		input CLOCK_27;		// 27 MHz clock input
		input CLOCK_50;		// 50 MHz clock input
		
		/* GPIO Pin Input/Output Definitions */
		inout [35:0] GPIO_1;			// assigning GPIO_1 as an input/output
		
		//********************************************************//
		//                 Hardware Connections                   //
		//********************************************************//
		/* Connecting Switches to Red LEDs */
		//assign LEDR[17:0] = SW[17:0];
		
		
		/* Connecting Key[3] to LEDG[7] */
		assign LEDG[7] = !KEY[3];
		
		
		
		//*********************************************************//
		/*               Hex Display Connections                   */
		//*********************************************************//
		assign HEX3 = 7'b0101111;						// writing 'r' to HEX display 3 to represent 'record'
		assign HEX2 = 7'b0100001;						// writing 'd' to HEX display 2 to represent 'delay'
		assign HEX7 = 7'b0000111;						// writing 't' to HEX display 7 to represent 'transmit'
		assign HEX6 = 7'b0001100;						// writing 'P' to HEX display 6 to represent 'Pulse'
		
		/* Setting up wire to hold delay value of data recording in ms */
		wire [4:0] mic_rec_delay_ms;
		assign mic_rec_delay_ms = SW[4:0];			// mic recording delay defined by binary value of switches 4 to 0
		hexdisplay_2dig H1_H0(SW[4:0],HEX1,HEX0);
		
		/* Setting up wire to hold transmitter pulse time recording in 1/10 ms*/
		wire [3:0] trans_on_time_wire;
		assign trans_on_time_wire = SW[17:14];
		hexdisplay_2dig_v2 H7_H6(SW[17:14],HEX5,HEX4);
		
		
		//********************************************************//
		//               Creating Clock Signals                   //
		//********************************************************//
		
		wire my_clock;
		assign GPIO_1[13] = my_clock;

		wire my_clock_40khz;
		//assign GPIO_1[11] = my_clock_40khz;			// turning on ultrasonic transmitter
		clk_div clk_div_12(CLOCK_50, my_clock, 0);	// my_clock output is 4.167 MHz				
		clk_40khz clk_40(CLOCK_50, my_clock_40khz, 0);				// my_clock 40khz is a 40khz clock signal
		
		/* Inverting 40khz clock signal */
		wire my_clock_40khz_inv;
		inv_sig inv_sig_1(CLOCK_50, my_clock_40khz, my_clock_40khz_inv);
		
		
		//*********************************************************//
		/*             Setting up control signals                  */
		//*********************************************************//
		wire mic_on;
		wire transmitter_on;
		wire [31:0] transmitter_on_time;					// transmitter on time in 1/10 millisecods, ie. transmitter_on_time = 10 corresponds to 1 millisecond on
		wire [31:0] mic_rec_delay_us;
		assign mic_rec_delay_us = mic_rec_delay_ms*1000;
		assign transmitter_on_time = trans_on_time_wire;
		signal_timing signal_connections(my_clock_40khz, KEY[3], transmitter_on, mic_on, mic_rec_delay_us, transmitter_on_time);
		
		/* Connecting transmitter inputs */
		transmitter_connection transmitter_connect_p(CLOCK_50, my_clock_40khz, GPIO_1[5], transmitter_on);
		transmitter_connection transmitter_connect_n(CLOCK_50, my_clock_40khz_inv, GPIO_1[4], transmitter_on);
		//assign GPIO_1[5] = my_clock_40khz;
		//assign GPIO_1[4] = my_clock_40khz_inv;
		
		
		//*******************************************************//
		//-------------- Flip Flop Instantiations ---------------//
		/* Rising Clock Sampled Mics */
		wire mic1_out;
		wire mic3_out;
		wire mic5_out;
		wire mic7_out;
		wire mic9_out;
		wire mic11_out;
		wire mic13_out;
		wire mic15_out;
		
		RisingEdge_DFlipFlop dflipflop_mic1(GPIO_1[21], my_clock, mic1_out);
		RisingEdge_DFlipFlop dflipflop_mic3(GPIO_1[19], my_clock, mic3_out);
		RisingEdge_DFlipFlop dflipflop_mic5(GPIO_1[25], my_clock, mic5_out);
		RisingEdge_DFlipFlop dflipflop_mic7(GPIO_1[23], my_clock, mic7_out);
		RisingEdge_DFlipFlop dflipflop_mic9(GPIO_1[31], my_clock, mic9_out);
		RisingEdge_DFlipFlop dflipflop_mic11(GPIO_1[29], my_clock, mic11_out);
		RisingEdge_DFlipFlop dflipflop_mic13(GPIO_1[35], my_clock, mic13_out);
		RisingEdge_DFlipFlop dflipflop_mic15(GPIO_1[33], my_clock, mic15_out);
		
		
		/* Falling Clock Sampled Mics */
		wire mic2_out;
		wire mic4_out;
		wire mic6_out;
		wire mic8_out;
		wire mic10_out;
		wire mic12_out;
		wire mic14_out;
		wire mic16_out;
		
		FallingEdge_DFlipFlop dflipflop_mic2(GPIO_1[21], my_clock, mic2_out);
		FallingEdge_DFlipFlop dflipflop_mic4(GPIO_1[19], my_clock, mic4_out);
		FallingEdge_DFlipFlop dflipflop_mic6(GPIO_1[25], my_clock, mic6_out);
		FallingEdge_DFlipFlop dflipflop_mic8(GPIO_1[23], my_clock, mic8_out);
		FallingEdge_DFlipFlop dflipflop_mic10(GPIO_1[31], my_clock, mic10_out);
		FallingEdge_DFlipFlop dflipflop_mic12(GPIO_1[29], my_clock, mic12_out);
		FallingEdge_DFlipFlop dflipflop_mic14(GPIO_1[35], my_clock, mic14_out);
		FallingEdge_DFlipFlop dflipflop_mic16(GPIO_1[33], my_clock, mic16_out);
		
		
		
		
		//*******************************************************//
		// Using a switch as a manual reset for the cic filters
		//wire switch_reset_cic;
		//assign switch_reset_cic = SW[0];
		
		wire [15:0] filter_out_mic_7;
		assign LEDR[16:1] = filter_out_mic_7;				// lighting up the red LEDs with a filter output
		wire [15:0] filter_out_mic_1;
		wire [15:0] filter_out_mic_2;
		wire [15:0] filter_out_mic_3;
		wire [15:0] filter_out_mic_4;
		wire [15:0] filter_out_mic_5;
		wire [15:0] filter_out_mic_6;
		wire [15:0] filter_out_mic_8;
		wire [15:0] filter_out_mic_9;
		wire [15:0] filter_out_mic_10;
		wire [15:0] filter_out_mic_11;
		wire [15:0] filter_out_mic_12;
		wire [15:0] filter_out_mic_13;
		wire [15:0] filter_out_mic_14;
		wire [15:0] filter_out_mic_15;
		wire [15:0] filter_out_mic_16;
		
		/* Instantiating Mic and CIC Filter connections */
		mic_cicfilter_connection  mic_7_cic(my_clock, mic7_out, filter_out_mic_7,mic_on);
		mic_cicfilter_connection  mic_1_cic(my_clock, mic1_out, filter_out_mic_1,mic_on);
		mic_cicfilter_connection  mic_2_cic(my_clock, mic2_out, filter_out_mic_2,mic_on);
		mic_cicfilter_connection  mic_3_cic(my_clock, mic3_out, filter_out_mic_3,mic_on);
		mic_cicfilter_connection  mic_4_cic(my_clock, mic4_out, filter_out_mic_4,mic_on);
		mic_cicfilter_connection  mic_5_cic(my_clock, mic5_out, filter_out_mic_5,mic_on);
		mic_cicfilter_connection  mic_6_cic(my_clock, mic6_out, filter_out_mic_6,mic_on);
		mic_cicfilter_connection  mic_8_cic(my_clock, mic8_out, filter_out_mic_8,mic_on);
		mic_cicfilter_connection  mic_9_cic(my_clock, mic9_out, filter_out_mic_9,mic_on);
		mic_cicfilter_connection  mic_10_cic(my_clock, mic10_out, filter_out_mic_10,mic_on);
		mic_cicfilter_connection  mic_11_cic(my_clock, mic11_out, filter_out_mic_11,mic_on);
		mic_cicfilter_connection  mic_12_cic(my_clock, mic12_out, filter_out_mic_12,mic_on);
		mic_cicfilter_connection  mic_13_cic(my_clock, mic13_out, filter_out_mic_13,mic_on);
		mic_cicfilter_connection  mic_14_cic(my_clock, mic14_out, filter_out_mic_14,mic_on);
		mic_cicfilter_connection  mic_15_cic(my_clock, mic15_out, filter_out_mic_15,mic_on);
		mic_cicfilter_connection  mic_16_cic(my_clock, mic16_out, filter_out_mic_16,mic_on);
		
		
		
		//*******************************************************//
		
endmodule
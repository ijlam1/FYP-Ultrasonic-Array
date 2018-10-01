/* Module that takes a 4 bit input and outputs a 2 7 bit numbers to be displayed on 2 HEX Outputs */
/* Differs from version 1 as displays zero,number instead of blank, number for numbers 1 to 10 */
module hexdisplay_2dig_v2(binary, hex1, hex0);
	input [4:0] binary;
	output reg [6:0] hex0;
	output reg [6:0] hex1;
	always @(binary)
		/* Case statement determining output hex display values */
		case (binary)
			0: begin hex0 <= 7'b1000000; hex1 <= 7'b1000000; end
			1: begin hex0 <= 7'b1111001; hex1 <= 7'b1000000; end
			2: begin hex0 <= 7'b0100100; hex1 <= 7'b1000000; end
			3: begin hex0 <= 7'b0110000; hex1 <= 7'b1000000; end
			4: begin hex0 <= 7'b0011001; hex1 <= 7'b1000000; end
			5: begin hex0 <= 7'b0010010; hex1 <= 7'b1000000; end
			6: begin hex0 <= 7'b0000010; hex1 <= 7'b1000000; end
			7: begin hex0 <= 7'b1111000; hex1 <= 7'b1000000; end
			8: begin hex0 <= 7'b0000000; hex1 <= 7'b1000000; end
			9: begin hex0 <= 7'b0011000; hex1 <= 7'b1000000; end
			10: begin hex0 <= 7'b1000000; hex1 <= 7'b1111001; end
			11: begin hex0 <= 7'b1111001; hex1 <= 7'b1111001; end
			12: begin hex0 <= 7'b0100100; hex1 <= 7'b1111001; end
			13: begin hex0 <= 7'b0110000; hex1 <= 7'b1111001; end
			14: begin hex0 <= 7'b0011001; hex1 <= 7'b1111001; end
			15: begin hex0 <= 7'b0010010; hex1 <= 7'b1111001; end
			16: begin hex0 <= 7'b0000010; hex1 <= 7'b1111001; end
			17: begin hex0 <= 7'b1111000; hex1 <= 7'b1111001; end
			18: begin hex0 <= 7'b0000000; hex1 <= 7'b1111001; end
			19: begin hex0 <= 7'b0011000; hex1 <= 7'b1111001; end
			20: begin hex0 <= 7'b1000000; hex1 <= 7'b0100100; end
			21: begin hex0 <= 7'b1111001; hex1 <= 7'b0100100; end
			22: begin hex0 <= 7'b0100100; hex1 <= 7'b0100100; end
			23: begin hex0 <= 7'b0110000; hex1 <= 7'b0100100; end
			24: begin hex0 <= 7'b0011001; hex1 <= 7'b0100100; end
			25: begin hex0 <= 7'b0010010; hex1 <= 7'b0100100; end
			26: begin hex0 <= 7'b0000010; hex1 <= 7'b0100100; end
			27: begin hex0 <= 7'b1111000; hex1 <= 7'b0100100; end
			28: begin hex0 <= 7'b0000000; hex1 <= 7'b0100100; end
			29: begin hex0 <= 7'b0011000; hex1 <= 7'b0100100; end
			30: begin hex0 <= 7'b1000000; hex1 <= 7'b0110000; end
			31: begin hex0 <= 7'b1111001; hex1 <= 7'b0110000; end
			default: begin hex0 <= 7'b1111111; hex1 <= 7'b1111111; end
   endcase
 endmodule

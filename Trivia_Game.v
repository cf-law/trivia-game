
module Trivia_Game( SW, KEY, HEX0, HEX2, HEX4, HEX5, LEDR, LEDG);
	input [3:0]SW;
	input [2:0]KEY;
	output [7:0]HEX0; // used to display score
	output [7:0] HEX2;
	output [7:0] HEX4; // used to display question number
	output [7:0] HEX5; // used to display question number
	output [16:0]LEDR;
	output [6:0] LEDG;
	
	wire r;
	wire [1:0]W_S; // represents WinStreaks output, W_S = 2'b11 means there is a win streak
	wire res; // 1 if player got a question right, 0 o/w
	wire [3:0]score;
	wire [7:0]q_num; // represents the question number
	wire [16:0] Totally_not_LEDR;
	wire [2:0] win_history;
	
	display_q(.resetn(~KEY[0]), .go(KEY[1]), .ans(SW[3:0]), .score(score), .W_S(W_S[1:0]), .curr_res(res), .q_num(q_num));
	WinStreak(.in(res), .clock(KEY[1]), .reset(KEY[0]), .out(W_S));
	Score(.in(res), .clock(KEY[1]), .W_S(W_S[0] & W_S[1]), .reset(KEY[0]), .out(score));
	display_W_S(.W_S(W_S[1] & W_S[0]), .out(LEDR[16:0]));

	display_wins(.clock(KEY[1]), .res(res), .resetn(KEY[0]), .wins(win_history[2:0]));

	
	hex_display(.IN(score), .OUT(HEX0)); // score display
	hex_display(.IN(W_S[1] & W_S[0]), .OUT(HEX2)); // win streak display
	
	hex_display(.IN(q_num[3:0]), .OUT(HEX4)); // q num display
	hex_display(.IN(q_num[7:4]), .OUT(HEX5)); // q num display

	assign LEDG[2:0] = win_history[2:0];
endmodule

module display_wins(clock, res, resetn, wins);
	input res;
	input clock;
	input resetn;
	output [2:0]wins;
	
	reg curr_wins; // stores current wins (history)
	
	localparam A = 3'b000, B = 3'b001, C = 3'b010, D = 3'b011, E = 3'b100, F = 3'b101, G = 3'b110, H = 3'b111;
	reg [2:0] curr, next; // stores current and next states
	
	always@(*)
	begin: state_table
		case(curr)
			A: begin
				if (res) next <= B;
				else next <= A;
				end
			B: begin
				if (res) next <= D;
				else next <= C;
				end
			C: begin
				if (res) next <= F;
				else next <= E;
				end
			D: begin
				if (res) next <= H;
				else next <= G;
				end
			E: begin
				if (res) next <= B;
				else next <= A;
				end
			F: begin
				if (res) next <= D;
				else next <= C;
				end
			G: begin
				if (res) next <= F;
				else next <= E;
				end
			H: begin
				if (res) next <= H;
				else next <= G;
				end
		endcase
	end
	
	// registers store change in state on clock posedge only
	always @(posedge clock)
	begin: state_FFs
		if (resetn == 1'b0)
			curr <= A;
		else
			curr = next;
	end

	assign wins[2:0] = next[2:0];
endmodule

module display_W_S(W_S, out);
	input W_S;
	output [16:0] out;
	reg [16:0] disp;
	always@(*)
	begin
		if(W_S) begin
			disp[16:0] = 17'b01010101010101010;
		end
		else begin
			disp[16:0] = 17'b00000000000000000;
		end
	end
	assign out = disp;
endmodule


module Score(in, clock, W_S, reset, out);
	input in;
	input [1:0] W_S;
	input clock;
	input reset;
	output [3:0]out;
	
	reg scr; // represents the current_score

	localparam A = 4'b0000, B = 4'b0001, C = 4'b0010, D = 4'b0011, E = 4'b0100, F = 4'b0101, G = 4'b0110, H = 4'b0111, I = 4'b1000, J = 4'b1001, K = 4'b1010;
	reg [3:0] curr, next; // represents the current and next states
	
	always@(*)
	begin: state_table
		case(curr)
			A: begin
				if(W_S) next <= C;
				else if(!in) next <= A;
				else next <= B;
				end
			B: begin
				if(W_S) next <= D;
				else if(!in) next <= A;
				else next <= C;
				end
			C: begin
				if(W_S) next <= E;
				else if(!in) next <= B;
				else next <= D;
				end
			D: begin
				if(W_S) next <= F;
				else if(!in) next <= C;
				else next <= E;
				end
			E: begin
				if(W_S) next <= G;
				else if(!in) next <= D;
				else next <= F;
				end
			F: begin
				if(W_S) next <= H;
				else if(!in) next <= E;
				else next <= G;
				end
			G: begin
				if(W_S) next <= I;
				else if(!in) next <= F;
				else next <= H;
				end
			H: begin
				if(W_S) next <= J;
				else if(!in) next <= G;
				else next <= I;
				end
			I: begin
				if(W_S) next <= K;
				else if(!in) next <= H;
				else next <= J;
				end
			J: begin
				if(!in) next <= I;
				else next <= K;
				end
			K: begin
				if(!in) next <= J;
				else next <= K;
				end
			default: next <= A;
		endcase
	end
	
	// registers store change in state on clock posedge only
	always @(posedge clock)
	begin: state_FFs
		if(reset == 1'b0)
			curr <= A;
		else
			curr = next;
	end

	assign out[3:0] = next;

endmodule

module WinStreak(in, clock, reset, out);
	input in;
	input clock;
	input reset;
	output [1:0]out;

	localparam A = 2'b00, B = 2'b01, C = 2'b10, D = 2'b11;	
	reg [1:0] curr, next; // represents current and next states

	always @(*)
	begin: state_table
		case(curr)
			A: begin
				if (!in) next <= A;
				else next <= B;
				end
			B: begin
				if (!in) next <= A;
				else next <= C;
				end
			C: begin
				if (!in) next <= A;
				else next <= D;
				end
			D: begin
				if (!in) next <= A;
				else next <= D;
				end
			default: next = A;
		endcase
	end

	// registers store change in state on clock posedge only
	always @(posedge clock)
	begin: state_FFs
		if(reset == 1'b0)
			curr <= A;
		else
			curr = next;
	end

	assign out[1:0] = next;
endmodule

module hex_display(IN, OUT);
    input [3:0] IN;
	 output reg [7:0] OUT;
	 
	 always @(*)
	 begin
		case(IN[3:0])
			4'b0000: OUT = 7'b1000000;
			4'b0001: OUT = 7'b1111001;
			4'b0010: OUT = 7'b0100100;
			4'b0011: OUT = 7'b0110000;
			4'b0100: OUT = 7'b0011001;
			4'b0101: OUT = 7'b0010010;
			4'b0110: OUT = 7'b0000010;
			4'b0111: OUT = 7'b1111000;
			4'b1000: OUT = 7'b0000000;
			4'b1001: OUT = 7'b0011000;
			4'b1010: OUT = 7'b0001000;
			4'b1011: OUT = 7'b0000011;
			4'b1100: OUT = 7'b1000110;
			4'b1101: OUT = 7'b0100001;
			4'b1110: OUT = 7'b0000110;
			4'b1111: OUT = 7'b0001110;
			
			default: OUT = 7'b0111111;
		endcase

	end
endmodule


module display_q(resetn, go, ans, score, W_S, curr_res, q_num);
	
	input [1:0]W_S;
	input resetn, go;
	input [3:0] ans;
	input [3:0]score;
	output reg curr_res;
	output [7:0] q_num;
   reg [6:0] current_state, next_state; 
	reg [2:0] num_games;
	reg res;
	reg x;
   localparam  S_CHOOSE		= 6'd0,
					 S_LOAD_1        = 6'd1,
                S_LOAD_2        = 6'd2,
                S_LOAD_3        = 6'd3,
                S_LOAD_4        = 6'd4,
                S_LOAD_5		= 6'd5,
					 S_LOAD_6		= 6'd6,
					 S_LOAD_7		= 6'd7,
					 S_LOAD_8		= 6'd8,
					 S_LOAD_9		= 6'd9,
					 S_LOAD_10		= 6'd10,
					 S_LOAD_11	    = 6'd11,
					 S_LOAD_12		= 6'd12,
					 S_LOAD_13		= 6'd13,
					 S_LOAD_14		= 6'd14,
					 S_LOAD_15		= 6'd15,
					 S_LOAD_16		= 6'd16,
					 S_LOAD_17	    = 6'd17,
					 S_LOAD_18		= 6'd18,
					 S_LOAD_19		= 6'd19,
					 S_LOAD_20		= 6'd20,
					 S_GAME_OVER		= 6'd21;

					 
	//initial begin
		//current_state = S_LOAD_1;
		
	//end
	assign q_num = current_state;
	//assign q_num = 6'd0;				 
    // Output logic aka all of our datapath control signals
    always @(*)
    begin
        case (current_state)
			S_CHOOSE: begin
				next_state <= S_LOAD_1;
				res = 1'b0;
			end
         S_LOAD_1: begin
			next_state <= S_LOAD_2;
				res = (ans == 4'b0100);
         end
         S_LOAD_2: begin
			next_state <= S_LOAD_3;
			res = (ans == 4'b1000);

         end
			S_LOAD_3: begin
			next_state <= S_LOAD_4;
			res = (ans == 4'b0010);

			end
			S_LOAD_4: begin
			next_state <= S_LOAD_5;
			res = (ans == 4'b1000);
			end
			S_LOAD_5: begin
			next_state <= S_LOAD_6;
			res = (ans == 4'b0010);
			end
		
			S_LOAD_6: begin
			next_state <= S_LOAD_7;
			res = (ans == 4'b0010);
			end
			S_LOAD_7: begin
			next_state <= S_LOAD_8;
			res = (ans == 4'b0010);
			end
			S_LOAD_8: begin
			next_state <= S_LOAD_9;
			res = (ans == 4'b1000);
			end
			S_LOAD_9: begin
			next_state <= S_LOAD_10;
			res = (ans == 4'b0010);
			end
			S_LOAD_10: begin
			next_state <= S_LOAD_11;
			res = (ans == 4'b1000);
			end

			S_LOAD_11: begin
			next_state <= S_LOAD_12;
			res = (ans == 4'b0100);
			end
			S_LOAD_12: begin
			next_state <= S_LOAD_13;
			res = (ans == 4'b0010);
			end	
			S_LOAD_13: begin
			next_state <= S_LOAD_14;
			res = (ans == 4'b1000);
			end	
			S_LOAD_14: begin
			next_state <= S_LOAD_15;
			res = (ans == 4'b0001);
			end	
			S_LOAD_15: begin
			next_state <= S_LOAD_16;
			res = (ans == 4'b0001);
			end	

			S_LOAD_16: begin
			next_state <= S_LOAD_17;
			res = (ans == 4'b0010);
			end	
			S_LOAD_17: begin
			next_state <= S_LOAD_18;
			res = (ans == 4'b0100);
			end	
			S_LOAD_18: begin
			next_state <= S_LOAD_19;
			res = (ans == 4'b1000);
			end	
			S_LOAD_19: begin
			next_state <= S_LOAD_20;
			res = (ans == 4'b0001);
			end	
			S_LOAD_20: begin
			next_state <= S_GAME_OVER;
			res = (ans == 4'b1000); 
			end	

			S_GAME_OVER: begin
				//every light turns on and the board blows up into confetti
				next_state = S_GAME_OVER;
			end
			default: next_state = S_CHOOSE;
        endcase
    end // enable_signals

	 //assign curr_res = res;
	 
	 	// registers store change in state on clock posedge only
	always @(posedge (go))
	begin
		if (resetn) begin
			current_state = S_CHOOSE;
			curr_res = 1'b0;
		end
		else if ((score == 4'b1001) & (res == 1'b1)) begin // if score reaches 10 always moves the state to game over
			current_state = S_GAME_OVER;
		end
		else if ((score == 4'b1000) & (W_S[1] == 1'b1) & (res == 1'b1)) begin
			current_state = S_GAME_OVER;
		end
		else begin
		curr_res = res & ~resetn;
		current_state = next_state & ~{resetn, resetn, resetn, resetn, resetn, resetn}; // jacob is fucking insane
		end
	end
	 
	 
endmodule

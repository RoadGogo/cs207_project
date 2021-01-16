
module HEX8(
		Clk,
		Rst_n,
		disp_data,
		sel,
		seg
	);

	input Clk;	//50M
	input Rst_n;
	
	input [31:0]disp_data;
	
	output [7:0] sel;
	output [7:0] seg;
	
	reg [16:0]divider_cnt;//25000-1
	
	reg [2:0]clk_1K;
	reg [7:0]sel_r;
	reg [7:0]seg_r;
	reg [3:0]data_tmp;

//1Khz·ÖÆµ
	always@(posedge Clk or negedge Rst_n)
	if(!Rst_n)
		divider_cnt <= 17'd0;
	else if(divider_cnt == 17'd99999)//17'd99999
		divider_cnt <= 17'd0;
	else
		divider_cnt <= divider_cnt + 1'b1;

	
	always@(posedge Clk or negedge Rst_n)
	if(!Rst_n)
		clk_1K <= 3'd0;
	else if(divider_cnt == 17'd99999)//17'd99999
		if(clk_1K == 3'd7)
			clk_1K <= 3'd0;
		else clk_1K <= clk_1K+3'd1;
	else
		clk_1K <= clk_1K;
		

	always@(*)
	case(clk_1K)
		3'd0:sel_r = 8'b11111110;
		3'd1:sel_r = 8'b11111101;
		3'd2:sel_r = 8'b11111011;
		3'd3:sel_r = 8'b11110111;
		3'd4:sel_r = 8'b11101111;
        3'd5:sel_r = 8'b11011111;
        3'd6:sel_r = 8'b10111111;
        3'd7:sel_r = 8'b01111111;
		default:sel_r = 8'b11111111;
	endcase
		
	always@(*)
		case(sel_r)
			8'b11111110:data_tmp = disp_data[3:0];
			8'b11111101:data_tmp = disp_data[7:4];
			8'b11111011:data_tmp = disp_data[11:8];
			8'b11110111:data_tmp = disp_data[15:12];
			8'b11101111:data_tmp = disp_data[19:16];
            8'b11011111:data_tmp = disp_data[23:20];
            8'b10111111:data_tmp = disp_data[27:24];
            8'b01111111:data_tmp = disp_data[31:28];
			default:data_tmp = 4'b0000;
		endcase
		
	always@(*)
       case(data_tmp)
        4'h0:seg_r = 8'b11000000;
        4'h1:seg_r = 8'b11111001;
        4'h2:seg_r = 8'b10100100;
        4'h3:seg_r = 8'b10110000;
        4'h4:seg_r = 8'b10011001;
        4'h5:seg_r = 8'b10010010;
        4'h6:seg_r = 8'b10000010;
        4'h7:seg_r = 8'b11111000;
        4'h8:seg_r = 8'b10000000;
        4'h9:seg_r = 8'b10010000;
        4'ha:seg_r = 8'b10001000;
        4'hb:seg_r = 8'b10000011;
        4'hc:seg_r = 8'b11000110;
        4'hd:seg_r = 8'b10100001;
        4'he:seg_r = 8'b10000110;
        4'hf:seg_r = 8'b10001110;
       endcase
		
	assign sel = sel_r;
	assign seg = seg_r;
endmodule

module control_module
(
    input clk,    //100Mhz
    input rst,    //系统复位
    input s1_flag,//确认购买按键按下标志
    input s2_flag,//回到查询阶段按键按下标志
    input s3_flag,//确认补货按键按下标志
    input s4_flag,//投币确认按键按下标志
    input s5_flag,//补货确认按键按下标志
    input[19:0] sw,//sw[0]货道1，sw[1]:0代表货道1中的第一个商品;1代表货道1中的第二个商品
                   //sw[2]货道2，sw[3]:0代表货道2中的第一个商品;1代表货道2中的第二个商品
                   //sw[4]sw[5],代表选择商品的价格；sw[6]~sw[9],代表投币的金额
                   //sw[10]~sw[17],代表补充商品的数量;sw[18]查看各商品的售出数量;sw[19]查看总销售金额
   output reg [31:0] dispay_num,
   output reg beep//蜂鸣器
);

reg buy_judge;

parameter S2=2'b00,S5=2'b01,S7=2'b10,S10=2'b11;  
parameter M1=4'b0001,M5=4'b0010,M10=4'b0100,M20=4'b1000; 
parameter query=2'b00,payment=2'b01,replenish=2'b10;

reg [3:0] price; //商品的价格
reg [7:0] price_all; //投币的总金额
reg [7:0] price_givechange; //找零的金额
reg [7:0] S2_num,S5_num,S7_num,S10_num;//各个商品的数量
reg [7:0] S2_sell,S5_sell,S7_sell,S10_sell;//各个商品售出的数量
reg move_flag;//滚动显示标志位
wire [23:0] display_move;//查询状态显示的当前滚动信息
reg [23:0] display_huodao;//显示货道的商品信息
reg [95:0] display_moveall;////查询状态显示的所有滚动信息
reg [29:0] Hz_cnt,Hz_cnt1; //1s计数
reg clk_1Hz,clk_2Hz,en_cnt;
reg [1:0] state;
reg [2:0] payment_flag,replenish_flag;
reg [7:0] time_payment,beep_cnt;
reg [15:0] price_sum;//销售总额
reg [16:0] time_cnt;

assign display_move = display_moveall[95:72];

//购买商品流程--状态机
always@(posedge clk or negedge rst)
begin
    if(!rst)
    begin
        buy_judge <= 0;
        price_all <= 8'd0; 
        price_givechange <= 8'd0;
        move_flag <= 1;
        en_cnt <= 0;
        display_huodao <= 24'd0;
        //display_move <= {4'd1,4'd1,S2_num,8'd2};//初始化为第一个货道，第一个商品，剩余数量，商品价格
        display_moveall<={4'd1,4'd1,S2_num,8'h02,4'd1,4'd2,S5_num,8'h05,4'd2,4'd3,S7_num,8'h07,4'd2,4'd4,S10_num,8'h10};
        S2_num <= 8'd0;
        S5_num <= 8'd0;
        S7_num <= 8'd0;
        S10_num <= 8'd0;
        S2_sell <= 8'd0;
        S5_sell <= 8'd0;
        S7_sell <= 8'd0;
        S10_sell <= 8'd0;
        state <= query;
        payment_flag <= 3'b000;
        replenish_flag <= 3'b000;
        time_payment <= 8'h00;
        price_sum <= 16'h0000;
    end
    else begin
        case(state) 
             query:
             begin 
                display_moveall<={4'd1,4'd1,S2_num,8'h02,4'd1,4'd2,S5_num,8'h05,4'd2,4'd3,S7_num,8'h07,4'd2,4'd4,S10_num,8'h10};
                if(move_flag)//显示滚动信息
                begin
                    en_cnt <= 1;
                    if(clk_1Hz)
                        display_moveall <= {display_moveall[72:0],display_moveall[95:72]};//循环左移滚动显示商品信息
                    else display_moveall <= display_moveall;  
                end
                else en_cnt <= 0;
                //显示货道信息
                if(sw[0])
                begin
                    move_flag <= 0;
                    display_huodao <= (!sw[1])?{4'd1,4'd1,S2_num,8'h02}:{4'd1,4'd2,S5_num,8'h05};
                end
                else if(sw[2])
                begin
                    move_flag <= 0;
                    display_huodao <= (!sw[3])?{4'd2,4'd3,S7_num,8'h07}:{4'd2,4'd4,S10_num,8'h10};
                end
                else move_flag <= 1;
                
                if(s1_flag)//进入付款阶段
                begin
                    state <= payment;
                    en_cnt <= 0;
                    price_all <= 8'd0;
                    buy_judge <= 1'b0;
                    time_payment <= 8'h60;//付款设定时间60s
                end
                else if(s3_flag)//进入补货阶段
                    state <= replenish;
                else state <= query;
                payment_flag <= 3'b000;
                replenish_flag <= 3'b000;
             end 
             payment:
             begin 
                en_cnt <= 1;
                //阶段改变
                if(s2_flag||(((price==8'd2&&S2_num==8'd0)||(price==8'd5&&S5_num==8'd0)||
                  (price==8'd7&&S7_num==8'd0)||(price==8'd10&&S10_num==8'd0))&&!buy_judge))//进入查询阶段
                begin
                    en_cnt <= 0;
                    price_all <= 8'd0;
                    if(s2_flag)
                    begin
                        display_moveall<={4'd1,4'd1,S2_num,8'h02,4'd1,4'd2,S5_num,8'h05,4'd2,4'd3,S7_num,8'h07,4'd2,4'd4,S10_num,8'h10};
                        state <= query;
                    end
                    else begin
                        payment_flag <= 3'b001; //数码管显示22222222
                        //if(beep_cnt>7)
                          //  state <= query;
                    end
                end
                else state <= payment;
                
                if(price == 8'd0) 
                begin en_cnt <=1;
                payment_flag <= 3'b111;
                time_payment <= 8'h00;
                end
                
                
                if(!((price==8'd2&&S2_num==8'd0)||(price==8'd5&&S5_num==8'd0)||
                                  (price==8'd7&&S7_num==8'd0)||(price==8'd10&&S10_num==8'd0))&&price!=8'd0)begin
                //付款倒计时
                if(clk_1Hz)
                    if(time_payment[3:0] != 0)
                        time_payment[3:0] <= time_payment[3:0]-4'd1;
                    else begin
                        if(time_payment[7:4] != 0)
                        begin
                            time_payment[3:0] <= 4'h9;
                            time_payment[7:4] <= time_payment[7:4]-4'd1;
                        end
                        else begin
                            time_payment[7:4] <= 4'h0;
                            if(beep_cnt>7)
                               state <= query;
                            en_cnt <= 0;
                        end
                    end
                else time_payment <= time_payment;
                //投币金额计算
                if(s4_flag)
                    case({sw[9:6]}) 
                       M1:  //所投钱币+1 
                         price_all <= price_all + 7'd1;  
                       M5: //所投钱币+5 
                         price_all <= price_all + 7'd5;  
                       M10://所投钱币+10 
                         price_all <= price_all+ 7'd10;  
                       M20://所投钱币+20 
                         price_all <= price_all + 7'd20;  
                      default:  price_all <= price_all; 
                   endcase 
                else price_all <= price_all; 
               //付款状态判断
               if(time_payment > 0) 
               begin
                    if(price_all < price)
                       payment_flag <= 3'b010; //最左侧两个数码管显示AA
                    else begin
                        buy_judge = 1;
                        time_payment <= 8'h00;
                        payment_flag <= 3'b011; //最左侧两个数码管显示66
                        price_givechange <= (price_all>price)?price_all-price:8'h00;
                        case(price) 
                            8'd2:begin S2_num <= S2_num-8'd1;price_sum <= price_sum+16'd2;S2_sell<=S2_sell+8'd1;end 
                            8'd5:begin S5_num <= S5_num-8'd1;price_sum <= price_sum+16'd5;S5_sell<=S5_sell+8'd1;end 
                            8'd7:begin S7_num <= S7_num-8'd1;price_sum <= price_sum+16'd7;S7_sell<=S7_sell+8'd1;end 
                            8'd10:begin S10_num <= S10_num-8'd1;price_sum <= price_sum+16'd10;S10_sell<=S10_sell+8'd1;end 
                            default:price_sum <= price_sum;
                        endcase
                    end
               end
               else begin
                    if(!buy_judge) begin
                    payment_flag <= 3'b100;//最左侧两个数码管显示FF
                    end
               end
             end 
             end
             replenish:
             begin 
                if(s2_flag)
                    state <= query;
                //选择货道进行补货
                 else if(sw[0])//补充货道1的商品
                 begin
                     replenish_flag <= 3'b001;
                     if(s5_flag)
                     begin
                        replenish_flag <= 3'b010;
                        if(!sw[1])
                            S2_num <= S2_num+sw[17:10];
                        else S5_num <= S5_num+sw[17:10];
                     end
                 end
                 else if(sw[2])//补充货道2的商品
                 begin
                    replenish_flag <= 3'b011;
                     if(s5_flag)
                     begin
                         replenish_flag <= 3'b100;
                         if(!sw[3])
                             S7_num <= S7_num+sw[17:10];
                         else S10_num <= S10_num+sw[17:10];
                     end
                 end
                 else if(sw[18])//查看各商品的售出数量
                    replenish_flag <= 3'b101;   
                 else if(sw[19])//查看总销售金额
                    replenish_flag <= 3'b110; 
                 else replenish_flag <= replenish_flag; 
             end 
             default:begin state <= query;end 
        endcase    
    end
end
//选择买哪个商品
always@(posedge clk or negedge rst)
begin
    if(!rst)
        price <= 4'd0;
    else begin
        if(sw[14])//选择商品确认
            case({sw[5],sw[4]}) 
                 S2:begin price <= 8'd2;end 
                 S5:begin price <= 8'd5;end 
                 S7:begin price <= 8'd7;end 
                 S10:begin price <= 8'd10;end 
                 default:begin price <= 8'd0;end 
            endcase    
        else price <= 8'd0;//仿真用--后续改成price <= 8'd0
    end
end

//各种状态蜂鸣器发出不同的提示音time_cnt
always@(posedge clk or negedge rst)
begin
	if(!rst)
	begin
		time_cnt <= 17'd0;
		beep <= 0;
		beep_cnt <= 8'd0;
	end
	else begin
	    if(payment_flag == 3'd1)//商品剩余数量为 0
	    begin
           if(clk_2Hz)
              beep_cnt <= beep_cnt+8'd1;
           if(time_cnt == 17'd95548)
           begin
              beep <= ~beep;
              time_cnt <= 17'd0;
           end  
           else time_cnt <= time_cnt+17'd1; 
        end  
        else if(payment_flag == 3'd2)//付款金额小于商品金额
           if(time_cnt == 17'd75838)
           begin
              beep <= ~beep;
              time_cnt <= 17'd0;
           end  
           else time_cnt <= time_cnt+17'd1;
        else if(payment_flag == 3'd3)//付款成功
           if(time_cnt == 17'd47778)
           begin
              beep <= ~beep;
              time_cnt <= 17'd0;
           end  
           else time_cnt <= time_cnt+17'd1;
        else if(payment_flag == 3'd4)//超出付款时间
        begin
           if(clk_2Hz)
              beep_cnt <= beep_cnt+8'd1;
           if(time_cnt == 17'd85136)
           begin
              beep <= ~beep;
              time_cnt <= 17'd0;
           end  
           else time_cnt <= time_cnt+17'd1; 
        end
        else  begin
            beep_cnt <= 8'd0;
            beep <= 0;
            time_cnt <= 17'd0;
        end
	end
end

//数码管要显示的信息
always@(posedge clk or negedge rst)
begin
    if(!rst)
        dispay_num <= 32'd0;
    else begin
        if(state == query)//查看信息阶段数码管显示信息
            dispay_num <= (move_flag)?{display_move,8'h00}:{display_huodao,8'h00};
        else if(state == payment)
            if(payment_flag == 3'd1)//商品剩余数量为 0
               dispay_num <= 32'h22222222;
            else if(payment_flag == 3'd2)//付款金额小于商品金额
               dispay_num <= {8'hAA,price_all,price,time_payment};
            else if(payment_flag == 3'd3)//付款成功
               dispay_num <= {8'h66,price_givechange,price,time_payment};
            else if(payment_flag == 3'd4||payment_flag == 3'd7)//超出付款时间
               dispay_num <= {8'hFF,price_all,price,time_payment};
            else  dispay_num <= dispay_num;
        else if(state == replenish)
            if(replenish_flag == 3'd1)//货道1的信息
               dispay_num <= {8'h00,4'h1,8'hff-S2_num,4'h2,8'hff-S5_num};
            else if(replenish_flag == 3'd2)//补货后货道1的信息
               dispay_num <= {8'h33,4'h1,S2_num,4'h2,S5_num};
            else if(replenish_flag == 3'd3)//货道1的信息
               dispay_num <= {8'h00,4'h3,8'hff-S7_num,4'h4,8'hff-S10_num};
            else if(replenish_flag == 3'd4)//补货后货道2的信息
               dispay_num <= {8'h55,4'h3,S7_num,4'h4,S10_num};
            else if(replenish_flag == 3'd5)//查看各商品的售出数量 
               dispay_num <= {S2_sell,S5_sell,S7_sell,S10_sell};
            else if(replenish_flag == 3'd6)//查看总销售金额 
            begin
               dispay_num[31:16] <= 16'h0000;
               dispay_num[15:12] <= price_sum/1000;
               dispay_num[11:8] <= price_sum/100%10;
               dispay_num[7:4] <= price_sum/10%10;
               dispay_num[3:0] <= price_sum%10;
            end
            else  dispay_num <= dispay_num;
        else dispay_num <= dispay_num;
    end
end
//1s计时模块
always@(posedge clk or negedge rst)
begin
	if(!rst)
	begin
		clk_1Hz <= 0;
		Hz_cnt <= 0;
	end
	else begin
	    if(en_cnt)
           if(Hz_cnt == 30'd99_999_999)
          // if(Hz_cnt == 30'd9)//仅用于仿真用
            begin
                 clk_1Hz <= 1;
                 Hz_cnt <= 0;
            end
            else begin
                 clk_1Hz <= 0;
                 Hz_cnt <= Hz_cnt+20'd1;
            end
		else begin
		  Hz_cnt <= 0;
		  clk_1Hz <= 0;
       end
	end
end

//0.5s计时模块
always@(posedge clk or negedge rst)
begin
	if(!rst)
	begin
		clk_2Hz <= 0;
		Hz_cnt1 <= 0;
	end
	else begin
        //if(Hz_cnt1 == 30'd49_999_999)
        if(Hz_cnt1 == 30'd4)//仅用于仿真用
        begin
             clk_2Hz <= 1;
             Hz_cnt1 <= 0;
        end
        else begin
             clk_2Hz <= 0;
             Hz_cnt1 <= Hz_cnt1+20'd1;
        end
	end
end
endmodule

module control_module
(
    input clk,    //100Mhz
    input rst,    //ϵͳ��λ
    input s1_flag,//ȷ�Ϲ��򰴼����±�־
    input s2_flag,//�ص���ѯ�׶ΰ������±�־
    input s3_flag,//ȷ�ϲ����������±�־
    input s4_flag,//Ͷ��ȷ�ϰ������±�־
    input s5_flag,//����ȷ�ϰ������±�־
    input[19:0] sw,//sw[0]����1��sw[1]:0�������1�еĵ�һ����Ʒ;1�������1�еĵڶ�����Ʒ
                   //sw[2]����2��sw[3]:0�������2�еĵ�һ����Ʒ;1�������2�еĵڶ�����Ʒ
                   //sw[4]sw[5],����ѡ����Ʒ�ļ۸�sw[6]~sw[9],����Ͷ�ҵĽ��
                   //sw[10]~sw[17],��������Ʒ������;sw[18]�鿴����Ʒ���۳�����;sw[19]�鿴�����۽��
   output reg [31:0] dispay_num,
   output reg beep//������
);

reg buy_judge;

parameter S2=2'b00,S5=2'b01,S7=2'b10,S10=2'b11;  
parameter M1=4'b0001,M5=4'b0010,M10=4'b0100,M20=4'b1000; 
parameter query=2'b00,payment=2'b01,replenish=2'b10;

reg [3:0] price; //��Ʒ�ļ۸�
reg [7:0] price_all; //Ͷ�ҵ��ܽ��
reg [7:0] price_givechange; //����Ľ��
reg [7:0] S2_num,S5_num,S7_num,S10_num;//������Ʒ������
reg [7:0] S2_sell,S5_sell,S7_sell,S10_sell;//������Ʒ�۳�������
reg move_flag;//������ʾ��־λ
wire [23:0] display_move;//��ѯ״̬��ʾ�ĵ�ǰ������Ϣ
reg [23:0] display_huodao;//��ʾ��������Ʒ��Ϣ
reg [95:0] display_moveall;////��ѯ״̬��ʾ�����й�����Ϣ
reg [29:0] Hz_cnt,Hz_cnt1; //1s����
reg clk_1Hz,clk_2Hz,en_cnt;
reg [1:0] state;
reg [2:0] payment_flag,replenish_flag;
reg [7:0] time_payment,beep_cnt;
reg [15:0] price_sum;//�����ܶ�
reg [16:0] time_cnt;

assign display_move = display_moveall[95:72];

//������Ʒ����--״̬��
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
        //display_move <= {4'd1,4'd1,S2_num,8'd2};//��ʼ��Ϊ��һ����������һ����Ʒ��ʣ����������Ʒ�۸�
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
                if(move_flag)//��ʾ������Ϣ
                begin
                    en_cnt <= 1;
                    if(clk_1Hz)
                        display_moveall <= {display_moveall[72:0],display_moveall[95:72]};//ѭ�����ƹ�����ʾ��Ʒ��Ϣ
                    else display_moveall <= display_moveall;  
                end
                else en_cnt <= 0;
                //��ʾ������Ϣ
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
                
                if(s1_flag)//���븶��׶�
                begin
                    state <= payment;
                    en_cnt <= 0;
                    price_all <= 8'd0;
                    buy_judge <= 1'b0;
                    time_payment <= 8'h60;//�����趨ʱ��60s
                end
                else if(s3_flag)//���벹���׶�
                    state <= replenish;
                else state <= query;
                payment_flag <= 3'b000;
                replenish_flag <= 3'b000;
             end 
             payment:
             begin 
                en_cnt <= 1;
                //�׶θı�
                if(s2_flag||(((price==8'd2&&S2_num==8'd0)||(price==8'd5&&S5_num==8'd0)||
                  (price==8'd7&&S7_num==8'd0)||(price==8'd10&&S10_num==8'd0))&&!buy_judge))//�����ѯ�׶�
                begin
                    en_cnt <= 0;
                    price_all <= 8'd0;
                    if(s2_flag)
                    begin
                        display_moveall<={4'd1,4'd1,S2_num,8'h02,4'd1,4'd2,S5_num,8'h05,4'd2,4'd3,S7_num,8'h07,4'd2,4'd4,S10_num,8'h10};
                        state <= query;
                    end
                    else begin
                        payment_flag <= 3'b001; //�������ʾ22222222
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
                //�����ʱ
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
                //Ͷ�ҽ�����
                if(s4_flag)
                    case({sw[9:6]}) 
                       M1:  //��ͶǮ��+1 
                         price_all <= price_all + 7'd1;  
                       M5: //��ͶǮ��+5 
                         price_all <= price_all + 7'd5;  
                       M10://��ͶǮ��+10 
                         price_all <= price_all+ 7'd10;  
                       M20://��ͶǮ��+20 
                         price_all <= price_all + 7'd20;  
                      default:  price_all <= price_all; 
                   endcase 
                else price_all <= price_all; 
               //����״̬�ж�
               if(time_payment > 0) 
               begin
                    if(price_all < price)
                       payment_flag <= 3'b010; //����������������ʾAA
                    else begin
                        buy_judge = 1;
                        time_payment <= 8'h00;
                        payment_flag <= 3'b011; //����������������ʾ66
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
                    payment_flag <= 3'b100;//����������������ʾFF
                    end
               end
             end 
             end
             replenish:
             begin 
                if(s2_flag)
                    state <= query;
                //ѡ��������в���
                 else if(sw[0])//�������1����Ʒ
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
                 else if(sw[2])//�������2����Ʒ
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
                 else if(sw[18])//�鿴����Ʒ���۳�����
                    replenish_flag <= 3'b101;   
                 else if(sw[19])//�鿴�����۽��
                    replenish_flag <= 3'b110; 
                 else replenish_flag <= replenish_flag; 
             end 
             default:begin state <= query;end 
        endcase    
    end
end
//ѡ�����ĸ���Ʒ
always@(posedge clk or negedge rst)
begin
    if(!rst)
        price <= 4'd0;
    else begin
        if(sw[14])//ѡ����Ʒȷ��
            case({sw[5],sw[4]}) 
                 S2:begin price <= 8'd2;end 
                 S5:begin price <= 8'd5;end 
                 S7:begin price <= 8'd7;end 
                 S10:begin price <= 8'd10;end 
                 default:begin price <= 8'd0;end 
            endcase    
        else price <= 8'd0;//������--�����ĳ�price <= 8'd0
    end
end

//����״̬������������ͬ����ʾ��time_cnt
always@(posedge clk or negedge rst)
begin
	if(!rst)
	begin
		time_cnt <= 17'd0;
		beep <= 0;
		beep_cnt <= 8'd0;
	end
	else begin
	    if(payment_flag == 3'd1)//��Ʒʣ������Ϊ 0
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
        else if(payment_flag == 3'd2)//������С����Ʒ���
           if(time_cnt == 17'd75838)
           begin
              beep <= ~beep;
              time_cnt <= 17'd0;
           end  
           else time_cnt <= time_cnt+17'd1;
        else if(payment_flag == 3'd3)//����ɹ�
           if(time_cnt == 17'd47778)
           begin
              beep <= ~beep;
              time_cnt <= 17'd0;
           end  
           else time_cnt <= time_cnt+17'd1;
        else if(payment_flag == 3'd4)//��������ʱ��
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

//�����Ҫ��ʾ����Ϣ
always@(posedge clk or negedge rst)
begin
    if(!rst)
        dispay_num <= 32'd0;
    else begin
        if(state == query)//�鿴��Ϣ�׶��������ʾ��Ϣ
            dispay_num <= (move_flag)?{display_move,8'h00}:{display_huodao,8'h00};
        else if(state == payment)
            if(payment_flag == 3'd1)//��Ʒʣ������Ϊ 0
               dispay_num <= 32'h22222222;
            else if(payment_flag == 3'd2)//������С����Ʒ���
               dispay_num <= {8'hAA,price_all,price,time_payment};
            else if(payment_flag == 3'd3)//����ɹ�
               dispay_num <= {8'h66,price_givechange,price,time_payment};
            else if(payment_flag == 3'd4||payment_flag == 3'd7)//��������ʱ��
               dispay_num <= {8'hFF,price_all,price,time_payment};
            else  dispay_num <= dispay_num;
        else if(state == replenish)
            if(replenish_flag == 3'd1)//����1����Ϣ
               dispay_num <= {8'h00,4'h1,8'hff-S2_num,4'h2,8'hff-S5_num};
            else if(replenish_flag == 3'd2)//���������1����Ϣ
               dispay_num <= {8'h33,4'h1,S2_num,4'h2,S5_num};
            else if(replenish_flag == 3'd3)//����1����Ϣ
               dispay_num <= {8'h00,4'h3,8'hff-S7_num,4'h4,8'hff-S10_num};
            else if(replenish_flag == 3'd4)//���������2����Ϣ
               dispay_num <= {8'h55,4'h3,S7_num,4'h4,S10_num};
            else if(replenish_flag == 3'd5)//�鿴����Ʒ���۳����� 
               dispay_num <= {S2_sell,S5_sell,S7_sell,S10_sell};
            else if(replenish_flag == 3'd6)//�鿴�����۽�� 
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
//1s��ʱģ��
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
          // if(Hz_cnt == 30'd9)//�����ڷ�����
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

//0.5s��ʱģ��
always@(posedge clk or negedge rst)
begin
	if(!rst)
	begin
		clk_2Hz <= 0;
		Hz_cnt1 <= 0;
	end
	else begin
        //if(Hz_cnt1 == 30'd49_999_999)
        if(Hz_cnt1 == 30'd4)//�����ڷ�����
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

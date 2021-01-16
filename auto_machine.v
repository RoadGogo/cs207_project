module auto_machine
(
   input clk,    //100Mhz
   input rst,    //系统复位--s6
   input s1,//确认购买按键
   input s2,//回到查询阶段按键
   input s3,//确认补货按键
   input s4,//投币确认按键
   input s5,//补货确认按键
   input[19:0] sw,//sw[0]货道1，sw[1]:0代表货道1中的第一个商品;1代表货道1中的第二个商品
                  //sw[2]货道2，sw[3]:0代表货道2中的第一个商品;1代表货道2中的第二个商品
                  //sw[4]sw[5],代表选择商品的价格；sw[6]~sw[9],代表投币的金额
                  //sw[10]~sw[17],代表补充商品的数量;sw[18]查看各商品的售出数量;sw[19]查看总销售金额
  output[7:0] sel,seg,
  output  beep//蜂鸣器
);

wire s5_flag,s4_flag,s3_flag,s2_flag,s1_flag;//经过按键防抖处理后的
wire[31:0] dispay_num;//七位数码显示管显示信息

//按键消抖模块
key_filter_module u1
(
	.clk(clk),              // 开发板上输入时钟: 50Mhz
	.rst_n(rst),            // 开发板上输入复位按键
	.key_in({s5,s4,s3,s2,s1}),  // 输入按键信号
	.flag_key({s5_flag,s4_flag,s3_flag,s2_flag,s1_flag})// 输出一个时钟的高电平
);
//控制模块
control_module u2
(
    .clk(clk),    //100Mhz
    .rst(rst),    //系统复位
    .s1_flag(s1_flag),
    .s2_flag(s2_flag),
    .s3_flag(s3_flag),
    .s4_flag(s4_flag),
    .s5_flag(s5_flag),//s1-s5按键
    .sw(sw),//输入
    .dispay_num(dispay_num),//得到当前情况要显示的信息
    .beep(beep)//蜂鸣器控制端口
);
//数码管显示模块
HEX8 u3
(
    .Clk(clk),
    .Rst_n(rst),
    .disp_data(dispay_num),//控制模块对应当前情形下要显示的信息
    .sel(sel),
    .seg(seg)
);
endmodule

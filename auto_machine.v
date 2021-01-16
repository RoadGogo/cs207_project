module auto_machine
(
   input clk,    //100Mhz
   input rst,    //ϵͳ��λ--s6
   input s1,//ȷ�Ϲ��򰴼�
   input s2,//�ص���ѯ�׶ΰ���
   input s3,//ȷ�ϲ�������
   input s4,//Ͷ��ȷ�ϰ���
   input s5,//����ȷ�ϰ���
   input[19:0] sw,//sw[0]����1��sw[1]:0�������1�еĵ�һ����Ʒ;1�������1�еĵڶ�����Ʒ
                  //sw[2]����2��sw[3]:0�������2�еĵ�һ����Ʒ;1�������2�еĵڶ�����Ʒ
                  //sw[4]sw[5],����ѡ����Ʒ�ļ۸�sw[6]~sw[9],����Ͷ�ҵĽ��
                  //sw[10]~sw[17],��������Ʒ������;sw[18]�鿴����Ʒ���۳�����;sw[19]�鿴�����۽��
  output[7:0] sel,seg,
  output  beep//������
);

wire s5_flag,s4_flag,s3_flag,s2_flag,s1_flag;//������������������
wire[31:0] dispay_num;//��λ������ʾ����ʾ��Ϣ

//��������ģ��
key_filter_module u1
(
	.clk(clk),              // ������������ʱ��: 50Mhz
	.rst_n(rst),            // �����������븴λ����
	.key_in({s5,s4,s3,s2,s1}),  // ���밴���ź�
	.flag_key({s5_flag,s4_flag,s3_flag,s2_flag,s1_flag})// ���һ��ʱ�ӵĸߵ�ƽ
);
//����ģ��
control_module u2
(
    .clk(clk),    //100Mhz
    .rst(rst),    //ϵͳ��λ
    .s1_flag(s1_flag),
    .s2_flag(s2_flag),
    .s3_flag(s3_flag),
    .s4_flag(s4_flag),
    .s5_flag(s5_flag),//s1-s5����
    .sw(sw),//����
    .dispay_num(dispay_num),//�õ���ǰ���Ҫ��ʾ����Ϣ
    .beep(beep)//���������ƶ˿�
);
//�������ʾģ��
HEX8 u3
(
    .Clk(clk),
    .Rst_n(rst),
    .disp_data(dispay_num),//����ģ���Ӧ��ǰ������Ҫ��ʾ����Ϣ
    .sel(sel),
    .seg(seg)
);
endmodule

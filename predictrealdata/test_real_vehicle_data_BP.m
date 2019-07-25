%从左到右是1序号，2时间，3实际转向，4cmd转向，5误差输出,6速度，7扭矩

data=xlsread('D:/science/neuralnetwork/sourcecode/predictrealdata/steering_data.xlsx','sheet2');


input = [data(11:6000, [4, 6, 7, 3]); data(7001:11211, [4, 6, 7, 3])]';
output = [data(15:6004, 4) - data(15:6004, 3); data(7005:11215, 4) - data(7005:11215, 3)]';


% 训练的没效果，可能是输入的选取有问题，或是没有归一化等原因
% 最后想要的结果是控制误差，当前误差其实可以用上一时刻的3-4的误差近似？？

net = newff(input,output,[8,6],{'tansig', 'tansig'}, 'traingdx'); % 'traingdx'是权值的训练算法,具体见ppt25页
net.trainParam.epochs = 5000;       % [20,20]是两个20节点的隐含层，3个输入，1个输出层
net.trainParam.goal = 1e-10;
net.trainParam.lr = 0.01 ;              % 学习率
% net.divideFcn = '';                    
net.divideParam.trainRatio = 70/100;
net.divideParam.valRatio   = 15/100;
net.divideParam.testRatio  = 15/100;
net.trainParam.max_fail = 20;


net = train(net, input, output);        % 训练网络，没有归一化？？？
tic;
input_test = data(7001:7990, [4, 6, 7, 3])';
output_true = (data(7005:7994, 4) - data(7005:7994, 3))';
predict_errL = sim(net, input_test);
% predict_errB = sim(net, input_test);      % 网络仿真
toc;
% xB = (7005:7994)/50;
xL = (7005:7994)/50;
%%
figure(1)
% plot(xB,predict_errB,'LineWidth',1,'color','r')
plot(xL,predict_errL,'LineWidth',1,'color','G')
hold on;
% plot(xB,output_true,'LineWidth',2,'color','k')
hold off;
% xlabel('time (s)')
% ylabel('steering wheel angle error (rad)')
% legend('BP predicted','measured')
% 查看——属性编辑器——改字号

e = predict_errB - output_true;          % 都变成横着的一行
MSE = sum(e.^2)/990          % 0.0171   0.0163 
RMSE = MSE^0.5               % 0.131    0.128
MAE = sum(abs(e))/990
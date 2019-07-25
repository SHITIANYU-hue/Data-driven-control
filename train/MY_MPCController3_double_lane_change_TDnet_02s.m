% 测试工作空间
% plot(x_real.data,y_real.data,'r-',x_predict.data,y_predict.data,'k-')

% input1是MPC输出的期望前轮转角，2是实际速度，3是方向盘转矩，4是方向盘角速度，5是期望1-实际4的差值
% output是0.2s后的期望delta-实际delta
% save NNdata290.mat
% load NNdata80.mat

% 由于zero-orderd的原因，delta_real的t时刻记录的数据其实是t-1时刻的，记录错位了0.05s
% 但实际延迟还是0.2s，只是input的记录延迟了，real（t=6）= predict（t=1）



clc; clear;
load double_lane_change_0.2s_0.02_2.mat
% load double_lane_change_0.2s_0.02.mat

% 24s*20=480  延时0.1s，周期0.05s 所以预测未来2步的
% 步数差距越小越好预测，所以可以采用小延时，改动△u来增大误差
input1 = delta_predict.data(1:360,1);
%input2 = v_real.data(1:360,1);
input3 = steer_torque.data(1:360,1);
input4 = omega.data(1:360,1); 
% input4 = delta_real.data(1501:5795,1);
% input5 = delta_predict.data(1:360,1) -  delta_real.data(1:360,1);

% input_train = [input1, input2, input3,input4, input5]';
input_train = [input1, input3, input4]';

input_train = con2seq(input_train);

future_err = (delta_predict.data(5:364,1) - delta_real.data(6:365,1))';
output_train = con2seq(future_err);

n=3;        % 应该是x的输入数据为，x(t-0) ——> x(t-3)
m=0;
net1 = timedelaynet(m:n,[3]);         % 依赖于过去x，y的两个时间单位的值，隐含层10个节点

% narxnet(inputDelays,feedbackDelays,hiddenSizes,trainFcn) takes these arguments,
% inputDelays     Row vector of increasing 0 or positive delays (default = 1:2)
% feedbackDelays  Row vector of increasing 0 or positive delays (default = 1:2)
% hiddenSizes     Row vector of one or more hidden layer sizes (default = 10)
% trainFcn        Training function (default = 'trainlm')

net1.divideFcn = '';
net1.trainParam.min_grad = 1e-15;
net1.trainParam.epochs = 25; 
% net1.trainParam.lr = 0.005;

[Xs,Xi,Ai,Ts] = preparets(net1,input_train,output_train);  % 数据准备
% Prepare input and target time series data for network simulation or training
% [Xs,Xi,Ai,Ts,EWs,shift] = preparets(net,Xnf,Tnf,Tf,EW) takes these arguments,
% p     Xs	Shifted inputs              2x4289 cell  每个cell是3+1
% Pi    Xi	Initial input delay states   2x6   cell 初始化输入
% Ai    Ai	Initial layer delay states      没用上
% t     Ts	Shifted targets         1x4289 目标值

net1 = train(net1,Xs,Ts,Xi);  % 训练，没用上 Ai
% save ('newdata+buchang80_2_TDnet')      % 只用了第二次迭代跑的80s的数据
% view(net1)


% net2 = removedelay(net1,m);       不用removedelay？
% view(net2)
net2 = net1;

% 加入后可以不输入output_test了？
% save ('net_narx290_removedelay')
 gensim(net2, 0.05)

% 换了输入输出又来一遍，测试集？
% input_test1 = delta_predict.data(1:1495,1);
% input_test2 = v_real.data(1:1495,1);
% input_test3 = steer_torque.data(1:1495,1);
input_test1 = delta_predict.data(1:475,1);
% input_test2 = v_real.data(1:477,1);
input_test3 = steer_torque.data(1:475,1);
input_test4 = omega.data(1:475,1);


% input_test4 = delta_real.data(1:1495,1);
% input_test5 = delta_predict.data(1:475,1) -  delta_real.data(1:475,1);

% input_test = [input_test1, input_test2, input_test3, input_test4, input_test5]';
% input_test = [input_test1, input_test2, input_test3]';
input_test = [input_test1, input_test3, input_test4]';

input_test = con2seq(input_test);

% future_err_test = (delta_predict.data(5:1499,1) - delta_real.data(6:1500,1))';
future_err_test = (delta_predict.data(5:479,1) - delta_real.data(6:480,1))';

output_test = con2seq(future_err_test);

[Xs1,Xi1,Ai1,Ts1] = preparets(net2,input_test,{});    % 数据准备

predict_err = sim(net2,Xs1,Xi1);          % 仿真,yp是预测的误差

[Xs1,Xi1,Ai1,Ts1] = preparets(net2,input_test,output_test);    % 数据准备
e = cell2mat(predict_err)-cell2mat(Ts1);      % 为什么要用cell2mat？？输出（估计）误差 - 期望（实际）误差
% x = (5+n:1499)/20;
x = (5+n:479)/20;

figure(1)
plot(x,e,'b')
xlabel('t/s')
ylabel('delta error/rad')
legend('err_err')

figure(2)
plot(x,cell2mat(predict_err),'r',x,cell2mat(Ts1),'k')
xlabel('t/s')
ylabel('delta error/rad')
legend('predict_err','real_err')
% x1 = (1:317)/10;
% x2 = (1:801)/10;
%plot(x1,v_predict.data,'r-',x2,v_real.data,'k-');




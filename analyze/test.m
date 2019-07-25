clc;clear;

load newdata290.mat
input11 = delta_predict.data(1:5795,1);
input12 = v_real.data(1:5795,1);
input13 = steer_torque.data(1:5795,1);
input_train1 = [input11, input12, input13]';

future_err1 = (delta_predict.data(5:5799,1) - delta_real.data(6:5800,1))';
clearvars -EXCEPT input_train1 future_err1

%%%%%%%%%%%%%%%%%%%%%%%%
load newdata+buchang80.mat
input21 = delta_predict2.data(1:1595,1);    %注意delta_predict2
input22 = v_real.data(1:1595,1);
input23 = steer_torque.data(1:1595,1);
input_train2 = [input21, input22, input23]';

future_err2 = (delta_predict2.data(5:1599,1) - delta_real.data(6:1600,1))';%注意delta_predict2
clearvars -EXCEPT input_train1 future_err1 input_train2 future_err2 input21 input22 input23 delta_predict2 delta_real

%%%%%%%%%%%%%%%%%%%%%%%%
% 合并输入数据
input_train_end = [input_train1, input_train2];
input_train_end = con2seq(input_train_end);

future_err_end = [future_err1, future_err2];
output_train_end = con2seq(future_err_end);

%%%%%%%%%%%%%%%%%%%%%%%%
n=2;        % 应该是x的输入数据为，x(t-0) ——> x(t-3)
m=0;
net = timedelaynet(m:n,[12]); 

net.divideFcn = '';
net.trainParam.min_grad = 1e-10;
net.trainParam.epochs = 300; 
% net1.trainParam.lr = 0.005;

[Xs,Xi,Ai,Ts] = preparets(net,input_train_end,output_train_end);  % 数据准备

net = train(net,Xs,Ts,Xi);  % 训练，没用上 Ai
% save ('newdata290_TDnet')
gensim(net, 0.05)
view(net)

% 换了输入输出又来一遍，测试集？
% input_test1 = delta_predict.data(1:1495,1);
% input_test2 = v_real.data(1:1495,1);
% input_test3 = steer_torque.data(1:1495,1);
% input_test4 = delta_real.data(1:1495,1);
% input_test5 = delta_predict.data(1:1495,1) -  delta_real.data(1:1495,1);

% input_test = [input_test1, input_test2, input_test3, input_test4, input_test5]';
input_test = [input21, input22, input23]';
input_test = con2seq(input_test);

future_err_test = (delta_predict2.data(5:1599,1) - delta_real.data(6:1600,1))';
% future_err_test = (delta_predict.data(5:5799,1) - delta_real.data(6:5800,1))';

output_test = con2seq(future_err_test);

[Xs1,Xi1,Ai1,Ts1] = preparets(net,input_test,{});    % 数据准备

predict_err = sim(net,Xs1,Xi1);          % 仿真,yp是预测的误差

[Xs1,Xi1,Ai1,Ts1] = preparets(net,input_test,output_test);    % 数据准备
e = cell2mat(predict_err)-cell2mat(Ts1);      % 为什么要用cell2mat？？输出（估计）误差 - 期望（实际）误差

x = (5+n:1599)/20;
% x = (5+n:5799)/20;

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

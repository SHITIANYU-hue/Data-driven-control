%从左到右是1序号，2时间，3实际转4cmd转向，5误差输出,6速度向，，7扭矩

clc; clear;
%% 改成自己的路径
data = xlsread('/Users/we/Desktop/my_predict/steering_data.xlsx','sheet2');

%% 当前的real1和cmd1的差值 对应figure（5）中红色

x1 = (11:11225)/50;         % 每个数据的间隔为0.02s
real = data(11:11225, 3)';
cmd1 = data(11:11225, 4)';
e1 = cmd1 - real;

% figure(1)
% plot(x1, real, 'g', x1, cmd1, 'r') 
% figure(2)
% plot(x1, e1,'r')

%% 0.2s前的cmd2和现在的real2的差值 对应figure（5）中蓝色
x2 = (11:11225)/50;
real2 = data(11:11225, 3)';
cmd2 = data(1:11215, 4)';
e2 = cmd2 - real2;

% figure(3)
% plot(x2, real2, 'g', x2, cmd2, 'r')
% figure(4)
% plot(x2, e2,'b')

%%
figure(5)
plot(x1, e1,'r',x2, e2,'b')     % figure(2)和figure(4)的误差对比

square1 = sum(e1.^2)/11215      % 总误差
square2 = sum(e2.^2)/11215      % 去掉0.2s延时的误差
difference = square1 - square2
ratio = difference/square1     % 延时导致的误差在总误差占比

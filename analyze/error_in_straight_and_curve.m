%从左到右是1序号，2时间，3实际转向，4cmd转向，5误差输出,6速度，7扭矩

clc; clear;
data = xlsread('/Users/zch/Desktop/时天宇NN相关/my_predict/steering_data.xlsx','sheet2');
real = data(1:11225, 3)';
cmd1 = data(1:11225, 4)';

straight = 0;
curve = 0;
num1 = 0;
num2 = 0;
for i = 1:11225
    a = data(i,4);
    if abs(a)<0.1   % 直道
        straight = straight + data(i,5)^2;    % error的平方和    
        num1 = num1 +1;
    else            % 弯道
        curve = curve + data(i,5)^2;  
        num2 = num2 +1;
    end
end

MSE_straight = straight/num1;
MSE_curve = curve/num2;
RMSE_straight = MSE_straight^0.5
RMSE_curve = MSE_curve^0.5

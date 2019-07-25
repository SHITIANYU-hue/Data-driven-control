function createaxes(X1, YMatrix1, X2, Y1, X3, Y2)
%CREATEAXES(X1, YMatrix1, X2, Y1, X3, Y2)
%  X1:  x 数据的向量
%  YMATRIX1:  y 数据的矩阵
%  X2:  x 数据的向量
%  Y1:  y 数据的向量
%  X3:  x 数据的向量
%  Y2:  y 数据的向量

%  由 MATLAB 于 12-Jan-2019 19:29:51 自动生成

% 创建 axes
axes1 = axes;
hold(axes1,'on');

% 使用 plot 的矩阵输入创建多行
plot1 = plot(X1,YMatrix1,'LineWidth',1);
set(plot1(2),'DisplayName','Measured','LineWidth',2,'Color',[0 0 0]);
set(plot1(1),'DisplayName','LSTM','Color',[0 1 0]);
set(plot1(3),'DisplayName','TDNN','Color',[1 0 0]);

% 创建 plot
plot(X2,Y1,'DisplayName','BP','LineWidth',1,'Color',[1 1 0]);

% 创建 plot
plot(X3,Y2,'DisplayName','NARX','LineWidth',1,'Color',[0 0 1]);

% 创建 ylabel
ylabel({'steering wheel angle error/(rad)'},'FontSize',12);

% 创建 xlabel
xlabel({'t/(s)'},'FontSize',12);

box(axes1,'on');

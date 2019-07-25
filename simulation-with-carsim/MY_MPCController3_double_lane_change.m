function [sys,x0,str,ts] = MY_MPCController3(t,x,u,flag)
% 先讲输入与输出变量的含义：t是采样时间，x是状态变量，u是输入（是做成simulink模块的输入）,
% flag是仿真过程中的状态标志（以它来判断当前是初始化还是运行等）；sys输出根据flag的不同而不同
% （下面将结合flag来讲sys的含义），x0是状态变量的初始值，str是保留参数（mathworks公司还没想好
% 该怎么用它，一般在初始化中将它置空就可以了,str=[])，ts是一个1×2的向量，ts(1)是采样周期，ts(2)是偏移量。
%  http://blog.sina.com.cn/s/blog_628dd2bc0102uy7s.html

%   该函数是写的第3个S函数控制器(MATLAB版本：R2011a)
%   限定于车辆运动学模型，控制量为速度和前轮偏角，使用的QP为新版本的QP解法
%   [sys,x0,str,ts] = MY_MPCController3(t,x,u,flag)
% is an S-function implementing the MPC controller intended for use
% with Simulink. The argument md, which is the only user supplied
% argument, contains the data structures needed by the controller. The
% input to the S-function block is a vector signal consisting of the
% measured outputs and the reference values for the controlled
% outputs. The output of the S-function block is a vector signal
% consisting of the control variables and the estimated state vector,
% potentially including estimated disturbance states.

switch flag,
 case 0%初始化
  [sys,x0,str,ts] = mdlInitializeSizes; % Initialization
  
 case 2%更新离散状态量
  sys = mdlUpdates(t,x,u); % Update discrete states
  
 case 3%计算输出
  sys = mdlOutputs(t,x,u); % Calculate outputs
 


 case {1,4,9} % Unused flags
  sys = [];
  
    otherwise%未知的flag值
  error(['unhandled flag = ',num2str(flag)]); % Error handling
end
% End of dsfunc.

%==============================================================
% Initialization
%==============================================================

function [sys,x0,str,ts] = mdlInitializeSizes

% Call simsizes for a sizes structure, fill it in, and convert it 
% to a sizes array.

sizes = simsizes;
sizes.NumContStates  = 0;%连续状态量个数       所以模板中的case 1都不用管了
sizes.NumDiscStates  = 8;%离散状态量个数
sizes.NumOutputs     = 2;%输出量的个数
sizes.NumInputs      = 8;%输入量的个数
sizes.DirFeedthrough = 1; % Matrix D is non-empty.
sizes.NumSampleTimes = 1;%采样时间的个数
sys = simsizes(sizes); % 在初始化上面的结构以符合s函数的规范之后，应该再次调用simsize，将结构转换为一个可以被Simulink处理的向量。

x0 =[0;0;0;0;0;0;0;0];        % x0是状态变量的初始值,[0;0;0]即三个状态变量，注意是分号，列向量
global U;
U=[0;0];
% Initialize the discrete states.
str = [];             % Set str to an empty matrix.保留参数，不用管
ts  = [0.05 0];       % sample time: [period, offset]采样时间0.1s（现在是离散系统）（若设为0表示连续系统）
%End of mdlInitializeSizes
		      
%==============================================================
% Update the discrete states
%==============================================================
function sys = mdlUpdates(t,x,u)
  
sys = x;                % %sys即为x(k+1) 
%End of mdlUpdate.

%==============================================================
% Calculate outputs
%==============================================================
function sys = mdlOutputs(t,x,u)
    global a b u_piao;
    global U;
    global kesi;
   % tic
    Nx = 3;%状态量的个数
    Nu = 2;%控制量的个数
    Np =60;%预测步长                   %改大看看
    Nc= 30;%控制步长
    Row=10;%松弛因子
  %  fprintf('Update start, t=%6.3f\n',t)
    t_d =u(3)*3.1415926/180;%CarSim输出的为角度，角度转换为弧度  u是输入，u（3）表示第三个输入量φ
    
    % 实际偏航角是 u(3) --> t_d

%    %直线路径
  %   r(1)=5*t;
  %   r(2)=5;
  %   r(3)=5*t;
  %  vd1=5;
  %   vd2=0;
  %% =====================================================================
    %半径为25m的圆形轨迹,速度为5m/s
    %r(1)=25*sin(0.2*t);
    %r(2)=25-25*cos(0.2*t);
    
    % 删掉期望偏航角看看
    r(1)=u(4);      % 导入的地图x，初值是15.6
    r(2)=u(5);      % 导入的地图y
    r(3)=u(6)*3.1415926/180;      % 导入的期望航向角，角度变弧度
        
    vd1=u(8);                   % 外界实车数据的期望速度
    % vd1=3;                    % 换个数试试,逐渐加速，然后就不加了
    % vd2=0.104;               % 这是啥？ delta r
    vd2=0;                 % 换个数试试 ，其实转向时废的？？根本没控制
 %% =====================================================================  
%     %半径为25m的圆形轨迹,速度为3m/s
%     r(1)=25*sin(0.12*t);
%     r(2)=25+10-25*cos(0.12*t);
%     r(3)=0.12*t;
%     vd1=3;
%     vd2=0.104;
	%半径为25m的圆形轨迹,速度为10m/s
%      r(1)=25*sin(0.4*t);
%      r(2)=25+10-25*cos(0.4*t);
%      r(3)=0.4*t;
%      vd1=10;
%      vd2=0.104;
    kesi=zeros(5,1);                        % 这里改成4了
    kesi(1)=u(1)-r(1);%u(1)(2)是输入12，即车的实际位置
    kesi(2)=u(2)-r(2);%r(1)(2)是输入45，即目标点
    
    kesi(3)=(t_d-r(3)); %u(3)==X(3)   u（123）是三个状态量，实时位置？，r是轨迹点
    % t_d是实际偏航角，弧度，r(3)是期望偏航角，弧度
    
    kesi(4)=U(1);                   % 这是啥？？？在59行赋过值[0;0]？？ 是控制量
    kesi(5)=U(2);
    %fprintf('Update start, u(1)=%4.2f\n',U(1))
    %fprintf('Update start, u(2)=%4.2f\n',U(2))      

    T=0.05;
    T_all=40;%临时设定，总的仿真时间，主要功能是防止计算期望轨迹越界
    % Mobile Robot Parameters
    L = 2.6;        % 轴距
    % Mobile Robot variable
    
    
%矩阵初始化   
    u_piao=zeros(Nx,Nu);            % 3,2
    Q=eye(Nx*Np,Nx*Np);             % 状态量个数3 * 预测步长60  
    R=8*eye(Nu*Nc);                 % 单位矩阵，控制量个数2 * 控制步长Nc30
    % 之前5，改成8
    % 这个应该是78页的R矩阵，改大R会使控制量u的惩罚增大，减小蛇形走位？
    
    a=[1    0   -vd1*sin(t_d)*T;    % 对应书77页
       0    1   vd1*cos(t_d)*T;
       0    0   1;];
    b=[cos(t_d)*T   0;
       sin(t_d)*T   0;
       tan(vd2)*T/L      vd1*T/(cos(vd2)^2);];
   %式（4.6）
   
    A_cell=cell(2,2);
    B_cell=cell(2,1);
    A_cell{1,1}=a;
    A_cell{1,2}=b;
    A_cell{2,1}=zeros(Nu,Nx);
    A_cell{2,2}=eye(Nu);            % 单位矩阵
    B_cell{1,1}=b;
    B_cell{2,1}=eye(Nu);
    A=cell2mat(A_cell);
    B=cell2mat(B_cell);
    C=[1 0 0 0 0;
       0 1 0 0 0;
       0 0 1 0 0;];
    %式（4.10）
    
    PHI_cell=cell(Np,1);            % 预测步长NP=60
    THETA_cell=cell(Np,Nc);
    for j=1:1:Np
        PHI_cell{j,1}=C*A^j;
        for k=1:1:Nc                % 控制步长Nc=30
            if k<=j
                THETA_cell{j,k}=C*A^(j-k)*B;
            else 
                THETA_cell{j,k}=zeros(Nx,Nu);
            end
        end
    end
    PHI=cell2mat(PHI_cell);%size(PHI)=[Nx*Np Nx+Nu]
    THETA=cell2mat(THETA_cell);%size(THETA)=[Nx*Np Nu*(Nc+1)]
    %式（4.12）
    
    H_cell=cell(2,2);
    H_cell{1,1}=THETA'*Q*THETA+R;
    H_cell{1,2}=zeros(Nu*Nc,1);
    H_cell{2,1}=zeros(1,Nu*Nc);
    H_cell{2,2}=Row;
    H=cell2mat(H_cell);
    error=PHI*kesi;     % 对应书上80页et
                        % [180,1] = [180,5]*[5,1] 五个值分别为三个状态量123，两个控制量45，
                        % kesi（123）是状态量误差，随时间t变化，控制量没有error，所以kesi（45）=0
    f_cell=cell(1,2);
    f_cell{1,1}=2*error'*Q*THETA;
    f_cell{1,2}=0;
%     f=(cell2mat(f_cell))';
    f=cell2mat(f_cell);             % 对应书上Gt
    %以上对应（4.19）
 %% 以下为约束生成区域
 %不等式约束
    A_t=zeros(Nc,Nc);%见falcone论文 P181   % 控制步长Nc=30
    for p=1:1:Nc     % 左下全是1的三角阵
        for q=1:1:Nc
            if q<=p 
                A_t(p,q)=1;
            else 
                A_t(p,q)=0;
            end
        end 
    end 
    A_I=kron(A_t,eye(Nu));% 即书80页的式（4.17），对应于falcone论文约束处理的矩阵A,求克罗内克积kron()
    Ut=kron(ones(Nc,1),U);%此处感觉论文里的克罗内科积有问题,暂时交换顺序
    
%     umin=[-0.2;-0.54;];%维数与控制变量的个数相同
%     umax=[0.2;0.332];
if u(7)>20
    umin=[-1;-0.4]; 
    umax=[1;0.4];
    delta_umin=[-0.05;-0.02];
    delta_umax=[0.05;0.02];
elseif u(7)>10
    umin=[-1;-0.55]; % 把约束放宽，5m/s是速度控制量的限制（即和期望的差值），0.5rad是前轮转角限制
    umax=[1;0.55];
    delta_umin=[-0.05;-0.008];%%%%%%%%%%这里啥时候符号错了？？？？？
    delta_umax=[0.05;0.008];
else
    umin=[-1;-0.55];
    umax=[1;0.55];
    delta_umin=[-0.05;-0.03];
    delta_umax=[0.05;0.03];
end

    Umin=kron(ones(Nc,1),umin);
    Umax=kron(ones(Nc,1),umax);
    A_cons_cell={A_I zeros(Nu*Nc,1);-A_I zeros(Nu*Nc,1)};   % 结合二次规划定义，A_I <= Umax-Ut, -A_I <= -Umin+Ut
            %后面就不太懂了，quadprog二次规划问题，书80页标准二次型什么的
    b_cons_cell={Umax-Ut;-Umin+Ut};
    A_cons=cell2mat(A_cons_cell);%（求解方程）状态量不等式约束增益矩阵，转换为绝对值的取值范围
    b_cons=cell2mat(b_cons_cell);%（求解方程）状态量不等式约束的取值
   % 状态量约束
    M=10; 
    delta_Umin=kron(ones(Nc,1),delta_umin);
    delta_Umax=kron(ones(Nc,1),delta_umax);
    lb=[delta_Umin;0];%（求解方程）状态量下界，包含控制时域内控制增量和松弛因子
    ub=[delta_Umax;M];%（求解方程）状态量上界，包含控制时域内控制增量和松弛因子
    
    %% 开始求解过程
    % options = optimset('Algorithm','active-set');
    options = optimset('Algorithm','interior-point-convex'); 
    [X,fval,exitflag]=quadprog(H,f,A_cons,b_cons,[],[],lb,ub,[],options);
    %% 计算输出
    u_piao(1)=X(1);         % X是求解出来的控制量△Ut，u_piao=zeros(Nx,Nu);是个[3,2]矩阵？？维数不对？？
    u_piao(2)=X(2);
    U(1)=kesi(4)+u_piao(1);%kesi用于存储上一个时刻的控制量，u_piao是新求出来的控制量
    U(2)=kesi(5)+u_piao(2);
    u_real(1)=U(1)+vd1;     % 控制量U v + 期望速度
    u_real(2)=U(2)+vd2;     % 控制量U delta + 前轮转角0
    sys= u_real;        %sys此时为输出y
    % toc
% End of mdlOutputs.
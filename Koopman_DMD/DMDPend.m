function [name] = DMDPend(x0,xf,duration)
%% Script Prep
close all
%Input System Function
f = @(x,u)SimpPend(x,u);
%Input (simple) Control Matrix
B = [0;1];
%Initial Conditions
% thetai = 1.5;
% thetadi = 0.5;
% x0 = [thetai;thetadi];
%Terminal Conditions
% thetaf = pi;
% thetadf = 0;
% xf = [thetaf;thetadf];
%Predicted time, still needs to be fixed for DMDc
predict = 5; 
%Time Parameters
dt = 0.001;
% duration = 20;
tspan = 0.0:dt:duration;
%Misc Labeling
ver = 'v1p1';
var1 = num2str(x0(1));
var2 = num2str(x0(2));
var3 = num2str(duration);
%% File Management
ModelName = 'Pendulum_Simple_';
ModelName1 = [ModelName, var1, '_', var2,'_',var3,'_',ver];
path2data = ['../Data/',ModelName1]; mkdir(path2data)
path2figs = ['../Data/',ModelName1,'/']; mkdir(path2figs)
%% Other Parameters
%ODE
ode_options = odeset('RelTol',1e-10, 'AbsTol',1e-11);
%LQR
Q = [ 10 0; 0 10];
R = 1;
%DMDc Modes
r = 2;
p = 2;

%% Unforced System
[t,y0] = ode45(@(t,x)f(x,0),tspan,x0,ode_options);
%% LQR Controller
A = [0 1; -1 0];

gain = lqr(A,B,Q,R);
[~,y1] = ode45(@(t,x)f(x,(-gain*(x-xf))),tspan,x0);
uvals = zeros(1,length(y1));
for k=1:length(y1)
    uvals(1,k) = - gain*(y1(k,:)'-xf);
end

%% DMD Prediction setup
%Set learning time 
lspan = ((duration-predict)/dt); 

for i = 1: lspan
    y0l(i,1) = y0(i,1);
    y0l(i,2) = y0(i,2);
end

%% DMD 
[Mode,ceval,deval,magmode,Xdmd] = DMD(y0',r,dt); 
y0k = real(Xdmd);

%% DMDc 
[Mode2,ceval2,deval2,magmode2,Xdmd2,Atild,Btild,Xp] = DMDcii(y1',uvals,r,p,dt);
y1k = real(Xdmd2);

%% Plot Results
% Prep for error plot
for i = 1:length(y0k)
    y0check(i,:) = abs(y0((i+1),:)-y0k(:,i)');
    y1check(i,:) = abs(y1((i+1),:)-Xp(:,i)');
end

datit = sprintf('Simple pendulum DMDc check for %d seconds',duration);
figtit = [datit, ModelName1];
figure('NumberTitle', 'off', 'Name', figtit);
%title('Inverted pendulum DMD check for %d seconds',duration)
subplot(2,1,1)
plot(y1check(:,1))
% plot(y1(:,1))
hold on 
plot(Xp(1,:))
% plot(y1(:,1))
hold on
plot(y1(:,1))
% hold on
% plot(Xp(1,:),'*')
hold off
title('Control Error - Theta')
legend ('Error','DMD','Normal')
ylabel('\theta');
xlabel('t(ms)');

subplot(2,1,2)
plot(y1check(:,2))
hold on 
% plot(y1k(2,2:length(y1k)'),'x')
plot(Xp(2,:))
hold on
plot(y1(:,2))
% hold on
% plot(Xp(2,:),'*')
hold off
title('Control Error - Theta_{dot}')
legend ('Error','DMD','Normal')
ylabel('\theta''');
xlabel('t(ms)');
 
 %% SAVE RESULTS

 DataStore.y0 = y0;
 DataStore.y1 = y1;
 DataStore.u1 = uvals;
 DataStore.tspan1 = dt;
 DataStore.Atilda = Atild;
 DataStore.Btilda = Btild;
 DataStore.XDMD = Xdmd;
 DataStore.XDMDC = Xdmd2;
 DataStore.Xp = Xp;
% 
save([path2data,[ModelName1,'Data.mat']])
% Save Snapshots

 
    hmp = sprintf('DMDc_Pendulum_Error%d.png',1);
    saveas(figure(1),[path2figs, hmp])

name = ModelName1;
end


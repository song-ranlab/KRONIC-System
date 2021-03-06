function [Phi ,omega ,lambda ,b,Xdmd,approxA,Xprime2] = DMDcTest(StateData, InputData,B, dt)
%DMDC
%% Collect and construct the snapshot 
X = StateData (:,1:end -1);
Xp = StateData (:,2:end);
Ups = InputData (:,1:end -1);
Omega = [X;Ups];
%% COmpute the SVD of the input space
[U,Sig ,V] = svd(Omega ,'econ');
% if p == 0
    thresh = 1e-10;
    p = length(find(diag(Sig)>thresh));
% else
% end
Util = U(:,1:p);
Sigtil = Sig(1:p ,1:p);
Vtil = V(:,1:p);

%% Compute the SVD of the output space X'
[U,Sig ,V] = svd(Xp,'econ');

% if r == 0
    thresh = 1e-10;
    r = length(find (diag(Sig)>thresh));
% else
% end
% B = [0;1];
Uhat = U(:,1:r);
Sighat = Sig(1:r,1:r);
Vbar = V(:,1:r);

%Compute A & B
n = size(X,1);
q = size(Ups ,1);
U_1 = Util (1:n,:);
U_2 = Util (n+q:n+q,:);
approxA = Uhat'*(Xp)*Vtil*inv(Sigtil)*U_1'*Uhat
%approxA2 = Xp*V*inv(Sig)*U'
approxB = Uhat'*(Xp)*Vtil*inv(Sigtil)*U_2';
% approxA = (Xp - approxB*Ups)*V*inv(Sig)*U';
%% Preform the eigenval decomp of Atilda
[W,D] = eig(approxA);

%Compte the dynamic modes of the operator A
Phi = Xp * Vtil * inv(Sigtil) * U_1'*Uhat * W;

%Finish to output
lambda = diag(D); % discrete-time eigenvalues
omega = log(lambda)/dt; % continuous-time eigenvalues
%% Compute DMD mode amplitudes b
x1 = X(:, 1);
b = Phi\x1;

mm1 = size(X, 2); % mm1 = m - 1
time_dynamics = zeros(r, mm1);
t = (0:mm1 -1)*dt; % time vector
for iter = 1:mm1 ,
    time_dynamics (:,iter) = (b.*exp(omega*t(iter)));
end;
Xdmd = Phi * time_dynamics ;

%% Exporting Xprime X' = AX+BU
Xprime = approxA*Xp +  approxB*Ups;
% Xprime2 = nan(r,mm1);
% Xprime2(:,1) = approxA*StateData(:,1) ;
%  for i = 2: length(time_dynamics)
%      Xprime2(:,i) = approxA*Xprime2(:,i-1) + approxB*Ups(:,i-1);
%  end
 
% A_DMDc = (Xp - B*Ups)*V*inv(Sig)*U';
      
end


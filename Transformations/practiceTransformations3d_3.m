clearvars

%% create starting points (X)
X0 = [0 0 0; 1 0 0; 0 1 0; 1 1 0; 0 0 1; 1 0 1; 0 1 1; 1 1 1]';
% X0 = [0 0 0; 1 0 0; 1 1 0; 0 1 0]';
X0(4,:) = 1;

% scale
% S = diag([150 -172 305 1]);
S = diag([200 200 200 1]);
% S = eye(4);

% rotate around x
R1 = eye(4);
theta = pi/3;
R1(2:3,2:3) = [cos(theta) -sin(theta); sin(theta) cos(theta)];

% rotate around y
R2 = eye(4);
theta = 7*pi/2;
R2([1 3],[1 3]) = [cos(theta) sin(theta); -sin(theta) cos(theta)];

% rotate around z
R3 = eye(4);
theta = 4*pi/3;
R3(1:2,1:2) = [cos(theta) -sin(theta); sin(theta) cos(theta)];

% rotate
R = R3 * R2 * R1;

% shear
H = eye(4);
% H(1:2,1:2) = [1 1; 0.5 1];

% translate
T = eye(4);
T(1:3,end) = [40; 130; -1250];

X = T * H * R * S * X0;

%% create goal
Y = nan(4,size(X,2));
Y(1,2) = norm(diff(X(1:3,[1 2]), [], 2));
Y(2,3) = norm(diff(X(1:3,[1 4]), [], 2));
Y(1,4) = norm(diff(X(1:3,[4 3]), [], 2));
Y(2,4) = norm(diff(X(1:3,[2 3]), [], 2));
if size(X,2) == 8
    Y(:,5:8) = Y(:,1:4);
    Y(3,5:8) = norm(diff(X(1:3,[1 5]), [], 2));
end
Y(isnan(Y)) = 0;
Y(4,:) = 1;


%% transform start -> goal
M = Y * pinv(X);


%%
% X0 = [.5 -1 5]';
X0 = [.5 -1 -.5]';
X0(4,:) = 1;
X1 = T * H * R * S * X0;
Y1 = M * X1;


%%
clearPlot(1)
plotM(X, 'blue')
plotM(X1, 'blue')
set(gca, 'View', [-90 90])
plotM(Y, 'red')
plotM(Y1, 'red')

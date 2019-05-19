% P2 = PROJECTION(N, V0, P0, P1) computes the intersection of a line given
% by points P0, P1 with the plane given by point V0 and normal vector N.
% 
% Functionally, will project from P1 onto the plane. When a calibration is
% performed, N, V0, and P0 will be set. Then, on any trial, Optotrak data
% provides P1.
%
% Vectors are column vectors. P1 can be multiple points.
% 
% Adapted from Nassim Khaled
% 

function P2 = projection(n, V0, P0, P1)

u = bsxfun(@minus, P1, P0); % u = P1 - P0
w = P0 - V0;

% can't use bsxfun because output of @dot might not have the same size as u
D = arrayfun(@(i) dot(n, u(:,i)), 1:size(u,2)); % D = dot(n, u)

N = -dot(n,w);

s = N ./ D;
P2 = bsxfun(@plus, P0, bsxfun(@times, s, u)); % P2 = P0 + s .* u


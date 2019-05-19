% D = GETDISTANCEMATRIX(X) calculates the pairwise Euclidian distance from
% each marker to every other marker. Essentially the same as PDIST but much
% faster. Input must be Mx3 or NxMx3 for M markers and N samples. If N > 1,
% it will take the median over samples. Returns a symmetric MxM matrix of
% distances D.
% 
% E. Gaffin-Cahn    2/2019

function D = GetDistanceMatrix(x)

assert(size(x, ndims(x)) == 3, 'Data should be nSamples x nMarkers x 3')
if ndims(x) == 3
    y = squeeze(median(x, 1));
else
    y = x;
end
len = size(x, ndims(x)-1);
d = zeros(len);
for i = 1:3
    d = d + (repmat(y(:,i), [1,len]) - repmat(y(:,i)', [len,1])) .^ 2;
%     d = d + (y(:,i) - y(:,i)') .^ 2;
end
D = sqrt(d);



function D = getDistanceMatrix(x)

assert(size(x, ndims(x)-1) == 6 && size(x, ndims(x)) == 3, 'Data should be Nx6x3')
if ndims(x) == 3
    y = squeeze(median(x, 1));
else
    y = x;
end
d = zeros(6);
for i = 1:3
    d = d + (y(:,i) - y(:,i)') .^ 2;
end
D = sqrt(d);
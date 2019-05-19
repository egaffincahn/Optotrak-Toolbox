function CalcStandardDistances(calibration)

% load up the calibration structure
W = which('calibration.mat');
if nargin < 2 || isempty(calibration)
    assert(~isempty(W), 'Make sure calibration.mat is on your path.')
    calibration = load(W);
end
assert(isstruct(calibration), '"calibration" should be a structure.')

% load up the wing data when it's perfectly still, reshape it
fp = readtable('wingdata_still.csv');
x = nan(height(fp), 6, 3);
for i = 1:size(x,1) % scroll through samples
    for j = 1:size(x,2) % scroll through markers
        for k = 1:size(x,3) % scroll through xyz
            col = (j-1)*3+k;
            x(i,j,k) = table2array(fp(i,col));
        end
    end
end

% get the standard distances and save
calibration.S = GetDistanceMatrix(x);
save(W, '-struct', 'calibration')



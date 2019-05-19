% Read in wingdata. This is data from wing in place on the table, not
% moving. Output WingData, a matrix with the raw data reorganized. It is
% NxM for N number of samples and M = number of markers * xyz (3). FCpoint
% is a guess of where a fingertip might be based on the wing data. I
% eyeballed these but they are good enough for debugging. x is the same as
% WingData but shaped differently - N x number of markers x xyz (3).

function [WingData, FCpoint, x, t] = csv2array

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
hz = 100;
xl = size(x,1)/hz;
t = linspace(1/hz,xl,xl*hz);

FCpoint = round(squeeze(mean(median(x, 1), 2)))' + [11, -22, -36];
WingData = table2array(fp);

% nSamples = size(x, 1);
% nMarkers = size(x, 2);
% WingData = nan(nSamples, 3*nMarkers);
% for i = 1:nSamples
%     for n = 1:nMarkers
%         WingData(i,(n-1)*3+1:n*3) = squeeze(x(1,n,:))';
%     end
% end
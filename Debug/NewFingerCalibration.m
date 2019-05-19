% Function call structure:
% 
% OptoFingerCalib
%     CalcBetas
% OptoCollect
%     CalcFingertip
%         FindReliableMarkers
%             GetDistanceMatrix
% 
% Tests a new method of fingertip calculation. Takes raw wing samples from
% a .csv and reshapes them in CSV2ARRAY. Then calculates standard distances
% between the wing markers using GETDISTANCEMATRIX. With CALCBETAS,
% calculate the beta weights for converting between wing data and fingertip
% position. Then, use the same wing data and add noise. Use the noisy wing
% data to calculate the fingertip position with CALCFINGERTIP, which will
% determine which markers are most reliable.
% 
% What tests should we perform to make sure it works well?
% - if the current thing doesn't work well, take all good markers and
% average the estimated fingertip
% 

clearvars

rng(1)

addpath(genpath(cd))
calibration = load('calibration.mat');
% 
[WingData, FCpoint, x] = csv2array;
S = GetDistanceMatrix(x);
% 
% nMarkers = 6;
[Bcoeffs, BcoeffsSD] = CalcBetas(FCpoint, WingData);
load speedyload


% add noise to markers
% .25 -> approx 0.1% of samples jump > 1mm
% .30 -> approx 1.0%
% .35 -> approx 4.0%
noiseSD      = .30;
noise        = @(sd) randn(1,3) * sd;
translation  = [20, -50, 60];
data.Markers = mat2cell(squeeze(x(1,:,:)), ones(1,6), 3);
data.Markers = cellfun(@(xyz) xyz + translation + noise(noiseSD), data.Markers, 'UniformOutput', false);

% muck with markers here
data.Markers{2} = data.Markers{2} + rand(1,3)*5;
data.Markers{3} = data.Markers{3} + rand(1,3)*3;


[coords, missing]    = CalcFingertip(data, Bcoeffs, D);

calibration.D       = D;
calibration.Bcoeffs = Bcoeffs;
save('Debug/calibration.mat', '-struct', 'calibration')


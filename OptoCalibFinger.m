% [CALIBRATION, OPT] = OPTOCALIBFINGER(OPT, CALIBRATION) is for calibrating
% the wing device on the finger to the fingertip. Optional argument OPT is
% the Optotrak parameter structure, and if provided, the function will
% assume the Optotrak has been initialized, otherwise will try to
% initialize. Optional argument CALIBRATION is a structure with the
% OptoCalibEnv transformation matrix and projection parameters. If it is
% not supplied, OPTOCALIBFINGER will look for it on the path.
% 
% First, connect a single marker, place it on the table, and collect its
% position. Then, connect the wing and place the finger on the the tabletop
% marker and collect data. See this <a href="Flowchart.pdf">process</a>.
% 

function [calibration, opt] = OptoCalibFinger(opt, calibration)


%% check that environment calibration exists
W = which('calibration.mat');
msg = 'Make sure to do environment calibration before finger calibration';
if nargin < 2 || isempty(calibration)
    assert(~isempty(W), [msg ' and that calibration.mat is on your path.'])
    calibration = load(W);
end
assert(isstruct(calibration), msg)

%% start up optotrak if it's not already
if nargin < 1 || isempty(opt)
    opt.NumMarkers      = 1;    % Number of markers in the collection.
    opt.FrameFrequency  = 100;  % Frequency to collect data frames at.
    opt.MarkerFrequency = 3500; % Marker frequency for marker maximum on-time.
    opt.Threshold       = 30;   % Dynamic or Static Threshold value to use.
    opt.MinimumGain     = 160;  % Minimum gain code amplification to use.
    opt.StreamData      = 1;    % Stream mode for the data buffers.
    opt.DutyCycle       = 0.30; % Marker Duty Cycle to use.
    opt.Voltage         = 8.0;  % Voltage to use when turning on markers.
    opt.Flags={'OPTOTRAK_BUFFER_RAW_FLAG'; 'OPTOTRAK_GET_NEXT_FRAME_FLAG'};
    opt.CameraFile = 'standard.cam';
    
    input('Loading Optotrak. Press Enter when exactly 1 marker is connected.')
    OptoInit(opt);
    optotrak('OptotrakSetProcessingFlags', {'OPTO_LIB_POLL_REAL_DATA';'OPTO_CONVERT_ON_HOST';'OPTO_RIGID_ON_HOST'});
end
assert(isstruct(opt), 'Input argument OPT should be a structure with the Optotrak collection parameters.')
assert(opt.NumMarkers == 1, 'Only one marker should be connected initially. Check Optotrak collection parameters.')

%% collection

input('Put the marker on the table. Then press Enter to do collection.')
h = waitbar(0, '...');
nSamples = 200;
while true
    sample_count = 0;
    total = 0;
    samples = nan(nSamples, 3);
    while sample_count < nSamples
        h = waitbar(sample_count/nSamples, h, sprintf('total: %d', total));
        total = total + 1;
        [marker_pos, ~, missing] = OptoCollect(opt.NumMarkers);
        if ~missing
            sample_count = sample_count + 1;
            samples(sample_count,:) = marker_pos;
        end
    end

    % make sure data is stable
    if any(std(samples, [], 1) > 1)
        if ~strcmp('g', input('SD of marker estimate too high. Type ''g'' to try again. ', 's'))
            error('Could not get clean measurement of marker position and chose not to try again.')
        end
    else
        break
    end
end
FCpoint = nanmedian(samples, 1);
OptoDenit;

%% prep wing

input('Switch connected markers to wing. Press Enter when ready.')
opt.NumMarkers = 6; % for wing
OptoInit(opt);
optotrak('OptotrakSetProcessingFlags', {'OPTO_LIB_POLL_REAL_DATA';'OPTO_CONVERT_ON_HOST';'OPTO_RIGID_ON_HOST'});

%% calibrate finger

nSamples = 350;
input('Place wing on finger and touch the marker on the table. Press Enter when ready.')
while true
    WingData = nan(nSamples, 3 * opt.NumMarkers);
    sample_count = 0;
    total = 0;
    while sample_count < nSamples
        h = waitbar(sample_count/nSamples, h, sprintf('total: %d', total));
        total = total + 1;
        finger_pos = OptoCollect(opt.NumMarkers);
        if ~any(isnan(finger_pos(:))) % missing will only be true if all data are missing
            sample_count = sample_count+1;
            for n = 1:opt.NumMarkers
                WingData(sample_count,(n-1)*3+1:n*3) = finger_pos(n,1:3);
            end
        end
    end
    
    [Bcoeffs, BcoeffsSD] = CalcBetas(FCpoint, WingData);
    if any(std(WingData, [], 1) > 1) || any(cellfun(@max, BcoeffsSD) > 2)
        if ~strcmp('g', input('SD of finger estimate too high. Type ''g'' to try again. ', 's'))
            error('Could not calibrate Optotrak with finger and chose not to try again.')
        end
    else
        break
    end
    
end
delete(h)

%% save
calibration.Bcoeffs = Bcoeffs; % beta coefficients for finger calibration
calibration.datetime = datetime;
calibration.step = mfilename;
save(W, '-struct', 'calibration')

%% validate
disp('Validating calibration. Press any key to finish.');
w = Screen('OpenWindow', max(Screen('Screens')), [0 0 0]);
buffer = 100; % pixels
maxRadius = 10;

radiusStep = 2;
colors = ones(3,1) * 255*mod(0:maxRadius/radiusStep-1,2);
coord2ptb = @(coord, radius) [coord(1); coord(2); coord(1); coord(2)] + radius * [-1; -1; 1; 1];
while ~KbCheck(-1)
    [xyz, ptb] = OptoCollect(opt.NumMarkers, calibration); % raw (unaligned) optotrak data, converted to fingertip
    concentric = cell2mat(arrayfun(@(radius) coord2ptb(ptb, radius), maxRadius:-radiusStep:radiusStep, 'UniformOutput', false));
    Screen('DrawText', w, sprintf('Fingertip position:   %8.1f, %8.1f, %8.1f', xyz(1), xyz(2), xyz(3)), buffer/4, buffer/4, [255 255 255]);
    Screen('DrawText', w, sprintf('Screen position:      %10.0f, %10.0f', ptb(1), ptb(2)), buffer/4, buffer/2, [255 255 255]);
    Screen('FillOval', w, colors, concentric);
    Screen('Flip', w);
end

%% close out
Screen('Close', w); % only close the one we opened

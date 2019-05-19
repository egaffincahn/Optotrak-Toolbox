% [CALIBRATION, OPT] = OPTOCALIBLOAD(N) is for when
% we want to use a previous calibration. This is useful when debugging so
% that we don't have to re-calibrate every time. Optional number of markers
% N, otherwise defaults to 6.
%


function [calibration, opt] = OptoCalibLoad(N)

calibration = load('calibration.mat');

if ~nargin || isempty(N); N = 6; end

opt.NumMarkers      = N;    % Number of markers in the collection.
opt.FrameFrequency  = 100;  % Frequency to collect data frames at.
opt.MarkerFrequency = 1000; % Marker frequency for marker maximum on-time.
opt.Threshold       = 30;   % Dynamic or Static Threshold value to use.
opt.MinimumGain     = 160;  % Minimum gain code amplification to use.
opt.StreamData      = 1;    % Stream mode for the data buffers.
opt.DutyCycle       = 0.30; % Marker Duty Cycle to use.
opt.Voltage         = 8.0;  % Voltage to use when turning on markers.
opt.Flags={'OPTOTRAK_BUFFER_RAW_FLAG'; 'OPTOTRAK_GET_NEXT_FRAME_FLAG'};
opt.CameraFile = 'standard.cam';

input(sprintf('Make sure %d marker(s) is(are) connected. Press Enter when ready.', opt.NumMarkers))

OptoInit(opt);
optotrak('OptotrakSetProcessingFlags', {'OPTO_LIB_POLL_REAL_DATA';'OPTO_CONVERT_ON_HOST';'OPTO_RIGID_ON_HOST'});


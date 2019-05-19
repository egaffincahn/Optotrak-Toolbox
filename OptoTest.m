% OPTOTEST simply loads the Optotrak, collects data and plots it in real
% time. This is just to make sure that the hardware, API, and Optotrak
% toolbox are working correctly. Does not use any calibration and only
% reads the first marker.

function OptoTest


%%
opt.NumMarkers      = 1;    % Number of markers in the collection.
opt.FrameFrequency  = 200;  % Frequency to collect data frames at.
opt.MarkerFrequency = 3500; % Marker frequency for marker maximum on-time.
opt.Threshold       = 30;   % Dynamic or Static Threshold value to use.
opt.MinimumGain     = 160;  % Minimum gain code amplification to use.
opt.StreamData      = 1;    % Stream mode for the data buffers.
opt.DutyCycle       = 0.50; % Marker Duty Cycle to use.
opt.Voltage         = 8.0;  % Voltage to use when turning on markers.
opt.Flags={'OPTOTRAK_BUFFER_RAW_FLAG'; 'OPTOTRAK_GET_NEXT_FRAME_FLAG'};
opt.CameraFile = 'standardreg.cam';

disp('loading optotrak, only 1 (or first) marker')

OptoInit(opt);
optotrak('OptotrakSetProcessingFlags', {'OPTO_LIB_POLL_REAL_DATA';'OPTO_CONVERT_ON_HOST';'OPTO_RIGID_ON_HOST'});
disp('finished loading')

%%
disp('collecting')
X = [];
while ~KbCheck
    raw = optotrak('DataGetNext3D', opt.NumMarkers);
    fingerPos = cell2mat(raw.Markers'); % row xyz, col marker
    X(end+1,:,:) = fingerPos; %#ok<AGROW>
    plot3(squeeze(X(:,1,:)), squeeze(X(:,2,:)), squeeze(X(:,3,:)))
    inrange = num2str(find(~isnan(fingerPos(1,:))));
    missing = num2str(find(isnan(fingerPos(1,:))));
    title(sprintf('In range: %s ... Missing: %s', inrange, missing))
    set(gca, 'DataAspectRatio', [1 1 1]);
    drawnow;
    WaitSecs(.005);
end

%%
disp('closing down')
OptoDenit;



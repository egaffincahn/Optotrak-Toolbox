%%

clearvars

opt.NumMarkers      = 6;    % Number of markers in the collection.
opt.FrameFrequency  = 200;  % Frequency to collect data frames at.
opt.MarkerFrequency = 3500; % Marker frequency for marker maximum on-time.
opt.Threshold       = 30;   % Dynamic or Static Threshold value to use.
opt.MinimumGain     = 160;  % Minimum gain code amplification to use.
opt.StreamData      = 1;    % Stream mode for the data buffers.
opt.DutyCycle       = 0.40; % Marker Duty Cycle to use.
opt.Voltage         = 6.0;  % Voltage to use when turning on markers.
opt.Flags={'OPTOTRAK_BUFFER_RAW_FLAG'; 'OPTOTRAK_GET_NEXT_FRAME_FLAG'};
opt.CameraFile = 'Registered20190219_1.cam';
% opt.CameraFile = 'standard.cam';

OptoInit(opt);
optotrak('OptotrakSetProcessingFlags', {'OPTO_LIB_POLL_REAL_DATA';'OPTO_CONVERT_ON_HOST';'OPTO_RIGID_ON_HOST'});

%%

xl = 45; % how much time to collect data
disp('waiting 5 s')
WaitSecs(5);
Snd('Play',MakeBeep(3000,.25));

x = nan(0,opt.NumMarkers,3);
t = nan(0);

figure(1), clf
fun = @(x, t, xl) plotTimeCourse(x, t, xl);
counter = 1;
countTo = 100;

tic
while toc < xl
    data = optotrak('DataGetNext3D', opt.NumMarkers);
    x(end+1,:,:) = cell2mat(data.Markers')';
    t(end+1) = GetSecs;
    if rem(counter, countTo) == 0
        fun(x, t, xl);
%         samples2plot = size(x,1)-countTo+1:size(x,1);
%         plot3(x(samples2plot,:,1), x(samples2plot,:,2), x(samples2plot,:,3), '.');
%         set(gca, 'DataAspectRatio', [1 1 1]);
%         drawnow;
    end
    counter = counter + 1;
    WaitSecs(.001);
end

Snd('Play',MakeBeep(3000,.25));


%%
samples2plot = (1:200) - 200;

%% plot the next set of data in native 3d space
samples2plot = samples2plot + 200;
plot3(x(samples2plot,:,1), x(samples2plot,:,2), x(samples2plot,:,3), '.');
set(gca, 'DataAspectRatio', [1 1 1])

%%
% samples2plot = 2531:2570;
% plot3(x(samples2plot,:,1), x(samples2plot,:,2), x(samples2plot,:,3), '.');
% set(gca, 'DataAspectRatio', [1 1 1])

%%
OptoDenit;

%% plot the change in position for 2d only
plotTimeCourse(x, t, xl)

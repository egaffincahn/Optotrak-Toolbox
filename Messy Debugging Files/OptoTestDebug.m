%#ok<*SAGROW>

try

%% load
addpath('C:\Users\landyadmin\Documents\EG\Motor Self-Knowledge\Experiment')
clean
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
% opt.CameraFile = 'standardreg.cam';
opt.CameraFile = 'standard.cam';

OptoInit(opt);
optotrak('OptotrakSetProcessingFlags', {'OPTO_LIB_POLL_REAL_DATA';'OPTO_CONVERT_ON_HOST';'OPTO_RIGID_ON_HOST'});
[w, rect] = Screen('OpenWindow', max(Screen('Screens')), [0 0 0]);
calibration = load('calibration.mat');

ptb = nan(0,2);
xyz_raw = nan(0,opt.NumMarkers,3);
xyz_wing = nan(0,3);
xyz_aligned = nan(0,3);
xyz_projected = nan(0,3);
t = [];
pt2oval = @(c, r) [c(:,1) c(:,2) c(:,1) c(:,2)]' + r * repmat([-1 -1 1 1]', [1,size(c,1)]);

disp('ready')

%% draw but don't save
while ~KbCheck(-1)
    [~, ptb_wingcalc] = OptoCollect(opt, calibration);
    [~, ptb_all] = OptoCollect(opt, rmfield(calibration, 'Bcoeffs')); % show all 6 markers
    Draw2Center(w, 'Press any button to start recording,\nthen any button to stop.',[],[],[0 128 128],[],[],[],[],[],[],[],[],0);
    Screen('FillOval', w, [0 255 255], pt2oval(ptb_wingcalc, 3)); % wing calc
    Screen('FillOval', w, [128 128 0], pt2oval(ptb_all,3)); % all 6
    Screen('Flip', w);
end

%% draw and save
tic
KbReleaseWait(-1);
while ~KbCheck(-1)
    [~, ptb(end+1,:), ~, xyz_raw(end+1,:,:), xyz_wing(end+1,:), xyz_aligned(end+1,:), xyz_projected(end+1,:), t(end+1)] = OptoCollect(opt, calibration); % for plotting after
    [~, ptb_all] = OptoCollect(opt, rmfield(calibration, 'Bcoeffs')); % show all 6 markers
    Screen('FillOval', w, [0 255 255], pt2oval(ptb(end,:),3));
    Screen('FillOval', w, [128 128 0], pt2oval(ptb_all,3));
    Screen('Flip', w);
end
    
catch me
    % do nothing
end

try; toc; end
clean
if exist('me', 'var'); rethrow(me); end

%%
v = 1:length(t);
% v = 600:700;

c = jet(length(v));

figure(1), clf, hold on
for i = 1:length(v), plot([i i], [.5 1.5], '-', 'Color', c(i,:), 'LineWidth', 2), end
axis([1 length(v) .5 1.5]), axis off

figure(2), clf, hold on
for n = 1:opt.NumMarkers
    plot3(xyz_raw(v,n,1), xyz_raw(v,n,2), xyz_raw(v,n,3), '-', 'Color', [.8 .8 .8])
    for i = 1:length(v), plot3(xyz_raw(v(i),n,1), xyz_raw(v(i),n,2), xyz_raw(v(i),n,3), 'o', 'Color', c(i,:), 'MarkerFaceColor', c(i,:), 'MarkerSize', 2), end
    text(xyz_raw(v(1),n,1), xyz_raw(v(1),n,2), xyz_raw(v(1),n,3), num2str(n))
end
xlabel('x'), ylabel('y'), zlabel('z'), title('xyz\_raw')
set(gca, 'DataAspectRatio', [1 1 1])

figure(3), clf, hold on
plot3(xyz_wing(v,1), xyz_wing(v,2), xyz_wing(v,3), '-', 'Color', [.8 .8 .8])
for i = 1:length(v), plot3(xyz_wing(v(i),1), xyz_wing(v(i),2), xyz_wing(v(i),3), 'o', 'Color', c(i,:), 'MarkerFaceColor', c(i,:), 'MarkerSize', 5), end
xlabel('x'), ylabel('y'), zlabel('z'), title('xyz\_wing')
set(gca, 'DataAspectRatio', [1 1 1])

figure(4), clf, hold on
plot3(xyz_aligned(v,1), xyz_aligned(v,2), xyz_aligned(v,3), '-', 'Color', [.8 .8 .8])
for i = 1:length(v), plot3(xyz_aligned(v(i),1), xyz_aligned(v(i),2), xyz_aligned(v(i),3), 'o', 'Color', c(i,:), 'MarkerFaceColor', c(i,:), 'MarkerSize', 5), end
xlabel('x'), ylabel('y'), zlabel('z'), title('xyz\_aligned')
set(gca, 'DataAspectRatio', [1 1 1])

figure(5), clf, hold on
plot3(xyz_projected(v,1), xyz_projected(v,2), xyz_projected(v,3), '-', 'Color', [.8 .8 .8])
for i = 1:length(v), plot3(xyz_projected(v(i),1), xyz_projected(v(i),2), xyz_projected(v(i),3), 'o', 'Color', c(i,:), 'MarkerFaceColor', c(i,:), 'MarkerSize', 5), end
xlabel('x'), ylabel('y'), zlabel('z'), title('xyz\_projected')
axis([-500 500 -500 500])
set(gca, 'DataAspectRatio', [1 1 1])

figure(6), clf, hold on
plot(ptb(v,1), ptb(v,2), '-', 'Color', [.8 .8 .8])
for i = 1:length(v), plot(ptb(v(i),1), ptb(v(i),2), 'o', 'Color', c(i,:), 'MarkerFaceColor', c(i,:), 'MarkerSize', 5), end
xlabel('x'), ylabel('y'), title('ptb')
axis(rect([1 3 2 4]))
set(gca, 'YDir', 'reverse')
set(gca, 'DataAspectRatio', [1 1 1])

%% which sample did it mess up on?

y4 = xyz_raw(:,4,2); % 4th marker, y component 
[~,ind4] = max(abs(diff(y4))); % ind is the last good sample

y5 = xyz_raw(:,5,2);
[~,ind5] = max(abs(diff(y5))); % ind is the last good sample

w = xyz_wing(:,2); % y component
[~,indw] = max(abs(diff(w))); % ind is the last good sample
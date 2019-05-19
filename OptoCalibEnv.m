% [CALIBRATION, OPT] = OPTOCALIBENV(OPT) is for aligning whatever
% coordinate system the Optotrak is currently using and create a mapping
% into Psychtoolbox space. Optional argument OPT is the Optotrak parameter
% structure, and if provided, the function will assume the Optotrak has
% been initialized, otherwise will try to initialize.
% 
% Records 9 points on the table. Then calculates a rotation matrix to align
% Optotrak coordinates to a new coordinate system defined by the table,
% where +x is to the right, +y is forward, and +z is vertical. Then
% collects the position of the eye for projecting from the eye through the
% hand to the table space. Finally, it does a validation with free movement
% to ensure the transformation worked. See this <a
% href="Flowchart.pdf">process</a>.
% 

function [calibration, opt] = OptoCalibEnv(opt)


%% start up optotrak
if nargin < 1 || isempty(opt)
    
    opt.NumMarkers      = 1;    % Number of markers in the collection.
    opt.FrameFrequency  = 100;  % Frequency to collect data frames at.
    opt.MarkerFrequency = 3500; % Marker frequency for marker maximum on-time.
    opt.Threshold       = 30;   % Dynamic or Static Threshold value to use.
    opt.MinimumGain     = 160;  % Minimum gain code amplification to use.
    opt.StreamData      = 1;    % Stream mode for the data buffers.
    opt.DutyCycle       = 0.50; % Marker Duty Cycle to use.
    opt.Voltage         = 8.0;  % Voltage to use when turning on markers.
    opt.Flags={'OPTOTRAK_BUFFER_RAW_FLAG'; 'OPTOTRAK_GET_NEXT_FRAME_FLAG'};
    opt.CameraFile = 'standard.cam';
    
    input('Connect 1 Optotrak marker. Press Enter when ready.');
    
    OptoInit(opt);
    optotrak('OptotrakSetProcessingFlags', {'OPTO_LIB_POLL_REAL_DATA';'OPTO_CONVERT_ON_HOST';'OPTO_RIGID_ON_HOST'});
    disp('Loading Optotrak...')
end

assert(isstruct(opt), 'Input argument OPT should be a structure with the Optotrak collection parameters.')
assert(opt.NumMarkers == 1, 'Only one marker should be connected. Check Optotrak collection parameters.')

%% psychtoolbox points
buffer = 100; % pixels
bkgd = [0 0 0]; % background color
[w, rect] = Screen('OpenWindow', max(Screen('Screens')), bkgd);
[x,y] = ndgrid(linspace(buffer, rect(3)-buffer, 3), linspace(buffer, rect(4)/2-buffer, 3));
centers = [x(:), y(:)];

%% choose calibrtion points
nCalibrations = size(centers,1);
maxRadius = 10;
radiusStep = 2;
Y = centers';
Y = [Y; zeros(1,nCalibrations); ones(1,nCalibrations)];
X = nan(3,nCalibrations);
nSamples = 50;
coord2ptb = @(coord, radius) [coord(1); coord(2); coord(1); coord(2)] + radius * [-1; -1; 1; 1];
colors = ones(3,1) * 255*mod(0:maxRadius/radiusStep-1,2);

%% do calibrations
% show the calibration dots in psychtoolbox and move the marker to each
% one successively, lining them up and accepting with keyboard press
calibration_count = 1;
h = waitbar(0, '...');
while calibration_count <= nCalibrations
    
    samples = nan(nSamples,3);
    sample_count = 0;
    total = 0;
    h = waitbar(0, h, sprintf('total: %d', 0));
    
    concentric = cell2mat(arrayfun(@(radius) coord2ptb(Y(:,calibration_count), radius), maxRadius:-radiusStep:radiusStep, 'UniformOutput', false));
    Screen('DrawText', w, sprintf('%d of %d', calibration_count, nCalibrations), buffer/4, buffer/4, [255 255 255]);
    Screen('FillOval', w, colors, concentric);
    Screen('Flip', w);
    
    KbWait;
    while sample_count < nSamples
        total = total + 1;
        [marker_pos, ~, missing] = OptoCollect(opt.NumMarkers);
        if ~missing
            sample_count = sample_count + 1;
            samples(sample_count,:) = marker_pos;
        end
        h = waitbar(sample_count/nSamples, h, sprintf('total: %d', total));
        [~,~,keyCode] = KbCheck; if keyCode(KbName('q')); error('Quit early'); end
    end
    
    % make sure data is stable
    if any(std(samples, [], 1) > 1)
        if ~strcmp('g', input('SD of marker estimate too high. Type ''g'' to try again. ', 's'))
            OptoFail
            error('Could not get clean measurement of marker position and chose not to try again.')
        end
    else % good data
        X(:,calibration_count) = median(samples,1)';
        calibration_count = calibration_count + 1;
    end
end

%% get eye position
% need to get eye position to calculate a projection from eye down to
% table, after which we can convert from 2D table space to psychtoolbox
% space
h = waitbar(0, h, sprintf('total: %d', total));
Screen('DrawText', w, 'Place marker between eyes', buffer/4, buffer/4, [255 255 255]);
Screen('Flip', w);
KbWait;
samples = nan(nSamples,3);
while true
    sample_count = 0;
    total = 0;
    while sample_count < nSamples
        total = total + 1;
        [marker_pos, ~, missing] = OptoCollect(opt.NumMarkers);
        if ~missing
            sample_count = sample_count + 1;
            samples(sample_count,:) = marker_pos;
        end
        h = waitbar(sample_count/nSamples, h, sprintf('total: %d', total));
        [~,~,keyCode] = KbCheck; if keyCode(KbName('q')); error('Quit early'); end
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
delete(h)
E0 = median(samples,1)';

%% add more samples parallel to collected data (3rd dim)

X(end+1,:) = 1;
V0 = X(1:3,5);
V1 = X(1:3,2);
V2 = X(1:3,4);
u = V0 - V1;
v = V0 - V2;
n = cross(u, v);
n = 50 * n / norm(n);
X = [X, X];
X(1:3,nCalibrations+1:nCalibrations*2) = bsxfun(@plus, X(1:3,nCalibrations+1:nCalibrations*2), n);

%% align to our own coordinate system

X_a = nan(size(X));
X_a(4,:) = 1;

% origin
X_a(1:2,8) = 0;

% non-zero in single dimension
X_a(1,7+[0 nCalibrations]) = -norm(diff(X(1:3,[7 8]), [], 2)); % 8 -> 7 negative x
X_a(1,7+[0 nCalibrations]) = -norm(diff(X(1:3,[7 8]), [], 2)); % 8 -> 7 negative x
X_a(1,9+[0 nCalibrations]) =  norm(diff(X(1:3,[9 8]), [], 2)); % 8 -> 9 positive x
X_a(2,2+[0 nCalibrations]) =  norm(diff(X(1:3,[2 8]), [], 2)); % 8 -> 2 positive y
X_a(2,5+[0 nCalibrations]) =  norm(diff(X(1:3,[5 8]), [], 2)); % 8 -> 5 positive y

% non-zero in both dimensions
X_a(1,1+[0 nCalibrations]) = -norm(diff(X(1:3,[1 2]), [], 2)); % 2 -> 1 negative x
X_a(2,1+[0 nCalibrations]) =  norm(diff(X(1:3,[1 7]), [], 2)); % 7 -> 1 positive y

X_a(1,3+[0 nCalibrations]) =  norm(diff(X(1:3,[3 2]), [], 2)); % 2 -> 3 positive x
X_a(2,3+[0 nCalibrations]) =  norm(diff(X(1:3,[3 9]), [], 2)); % 9 -> 3 positive y

X_a(1,4+[0 nCalibrations]) = -norm(diff(X(1:3,[4 5]), [], 2)); % 5 -> 4 negative x
X_a(2,4+[0 nCalibrations]) =  norm(diff(X(1:3,[4 7]), [], 2)); % 7 -> 4 positive y

X_a(1,6+[0 nCalibrations]) =  norm(diff(X(1:3,[6 5]), [], 2)); % 5 -> 6 positive x
X_a(2,6+[0 nCalibrations]) =  norm(diff(X(1:3,[6 9]), [], 2)); % 9 -> 6 positive y

% add 3rd dimension
X_a(3,nCalibrations+1:nCalibrations*2) = norm(n);

% fill in zeros
X_a(isnan(X_a)) = 0;

% X_a = R * X;
% transformation matrix R converts from native space to aligned space
R = X_a * pinv(X);

%% get eye position in aligned space

P0 = R * [E0; 1]; % put eye position in new aligned coordinate space
P0 = P0(1:3,:);

%% define plane of table with point and normal vector

V0 = X_a(1:3,8);
V1 = X_a(1:3,9);
V2 = X_a(1:3,2);
u = V1 - V0;
v = V2 - V0;
n = cross(u, v);
n = n / norm(n); % using the tranformed coordinate system, so this should be vertical vector

%% find table(xyz) to screen(ptb) transformation matrix

Y = [Y, Y];
Y(3,nCalibrations+1:nCalibrations*2) = norm(diff(X(1:3, [1 nCalibrations+1]), [], 2));
M = Y * pinv(X_a); % ptb = transformation matrix * (optotrak + error)

%% make calibration structure
calibration.X = X; % xyz positions of calibrations
calibration.R = R; % rotation matrix for alignment: X_a = R * X
calibration.X_a = X_a; % aligned xyz positions
calibration.n = n; % vector normal to X_a (easy, is vertical unit vec)
calibration.V0 = V0; % point on plane X_a (easy, is origin)
calibration.E0 = E0; % eye position in raw xyz
calibration.P0 = P0; % eye position in aligned xyz
calibration.M = M; % transformation matrix (projected, aligned xyz -> ptb)
calibration.Y = Y; % ptb positions of calibrations
calibration.datetime = datetime;
calibration.step = mfilename;

%% save it all
filename = 'calibration.mat';
W = which(filename);
if isempty(W) % if can't find file, save in current direction
    W = filename;
end
save(W, '-struct', 'calibration')

%% validate

while ~KbCheck(-1)
    [~, ptb, ~, ~, ~, aligned] = OptoCollect(opt.NumMarkers, calibration); % raw (unaligned) optotrak data, converted to fingertip
    concentric = cell2mat(arrayfun(@(radius) coord2ptb(ptb, radius), maxRadius:-radiusStep:radiusStep, 'UniformOutput', false));
    Screen('DrawText', w, sprintf('Aligned coordinates:   %8.1f, %8.1f, %8.1f', aligned(1), aligned(2), aligned(3)), buffer/4, buffer/4, [255 255 255]);
    Screen('DrawText', w, sprintf('Screen position:      %10.0f, %10.0f', ptb(1), ptb(2)), buffer/4, buffer/2, [255 255 255]);
    Screen('FillOval', w, colors, concentric);
    Screen('Flip', w);
end

%% close out
Screen('Close', w); % only close the screen we opened


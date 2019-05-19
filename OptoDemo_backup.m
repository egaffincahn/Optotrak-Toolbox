% OPTODEMO runs a demonstration of the Optotrak using the calibrated wing
% device, although a precise calibration of the finger/wing device is not
% crucial. Draws circles on the screen based on the location of the finger.
% The circles grow in size with the vertical position, and the colors
% change over collected samples. It's fun and you can draw pretty pictures
% (with some practice).
% 

function OptoDemo_backup

try
    
    clearvars
    
    % initializations
    KbName('UnifyKeyNames');
    w = Screen('OpenWindow', max(Screen('Screens')));
    go = true;
    colors = 255 * jet(200)';
    circ2ptb = @(c,r) [c(1)-r(1); c(2)-r(end); c(1)+r(1); c(2)+r(end)]; % create circle array for ptb
    dist2rad = @(d) d / 2; % convert mm in xyz space to radius in pixels 
    
    % do all calibrations
%     [calibration, collection_params] = OptoCalibEnv;
%     [calibration, collection_params] = OptoCalibFinger(collection_params, calibration);
    
    % do only finger/wing
%     [calibration, collection_params] = OptoCalibFinger;
    
    % don't need to do any calibration
    [calibration, collection_params] = OptoCalibLoad;
        
    while go
        
        % give instructions and wait for key press
        Screen('FillRect', w, [255 255 255]);
        Screen('Flip', w);
        KbReleaseWait(-1);
        Screen('DrawText', w, 'Place finger on table in front of you and press any key when ready.', 0, 50);
        Screen('Flip', w);
        KbWait(-1);
        
        % get initial position data and convert to ptb space
        missing = true;
        while missing
            [~, ~, missing, ~, ~, xyz, ~] = OptoCollect(collection_params, rmfield(calibration, 'Bcoeffs'));
            init = calcAvg(xyz);
            WaitSecs(.05);
        end
        
        circ_rects = [];
        color_ind = 1;
        color_dir = -1;
        draw_colors = [];
        tic
        
        while true
            
            % if we collect data for more than 30 seconds, reset
            if toc > 60
                circ_rects = [];
                draw_colors = [];
                tic
            end
            
            % collect data to plot
            [~, x_ptb, ~, ~, ~, xyz, ~] = OptoCollect(collection_params, rmfield(calibration,'Bcoeffs'));
            xyz_avg = calcAvg(xyz);
            x_ptb_avg = calcAvg(x_ptb);
            vdist = max([xyz_avg(3) - init(3), 0]); % get distance above table
            circ_rects = [circ_rects, circ2ptb(x_ptb_avg, dist2rad(vdist))]; %#ok<*AGROW>
            
            % set colors
            if color_ind == 1 || color_ind == size(colors,2)
                color_dir = -1 * color_dir;
            end
            color_ind = color_ind + color_dir;
            draw_colors = [draw_colors, colors(:,color_ind)];
            
            % draw it all
            Screen('FillOval', w, draw_colors, circ_rects);
            Screen('DrawText', w, 'Press space to reset, q to quit', 20, 20);
            Screen('Flip', w);
            
            % check to quit or reset
            [~,~,keyCode] = KbCheck;
            if find(keyCode) == KbName('q')
                go = false;
                break
            elseif find(keyCode) == KbName('space')
                break
            elseif find(keyCode) == KbName('c')
                [calibration, collection_params] = OptoCalibFinger(collection_params, calibration);
                break
            end
        end
        
    end
    
catch me
    % do nothing
end

try OptoDenit; catch; end
try sca; catch; end
if exist('me', 'var'); rethrow(me); end

function y = calcAvg(X) % markers are row vectors

missing = any(isnan(X), 2);
missing_ind = find(missing);
missing_new = missing;
for i = 1:length(missing_ind)
    if missing_ind(i) < 4
        missing_new(missing_ind(i) + 3) = 1;
    else
        missing_new(missing_ind(i) - 3) = 1;
    end
end
y = nanmean(X(~missing_new,:), 1);
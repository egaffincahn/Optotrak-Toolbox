% XYZ = OPTOCOLLECT(NMARKERS) collects one sample of data and returns the
% coordinates as a NMARKERSx3 matrix.
% 
% XYZ = OPTOCOLLECT(NMARKERS, CALIBRATION) uses a calibration structure
% containing the parameters for converting a 6-marker wing to a fingertip
% point, and projecting the 3D fingertip into Psychtoolbox space. If it
% can't find the appropriate transformation matrices, it will skip each
% appropriate step quietly. Unlike OptoCalibFinger, it will not search for
% a calibration structure in the path to speed up this function.
% 
% XYZ = OPTOCOLLECT(NMARKERS, CALIBRATION, DATA) performs the calibration
% transformations on DATA with size NMARKERSx3 instead of doing the new
% collection. NMARKERS is optional and can be inferred from DATA. Ensure
% that the CALIBRATION structure does not contain fields that will trigger
% each transformation.
% 
% [XYZ, PTB, MISSING, RAW, FINGER, ALIGNED, PROJECTED] = OPTOCOLLECT(...)
% returns the Optotrak coordinates at each step in the calibration
% calculation, as seen <a href="Flowchart.pdf">here</a>. The first
% output argument XYZ is the final calculated value, wherever in the
% process that is. Also returns true in MISSING if all the data are NaNs.
% 
% [..., COLLECTION_TIME] = OPTOCOLLECT(...) returns the time using tic/toc,
% but will return NaN if tic had not been called previously.
%
% 

function [xyz, ptb, missing, xyz_raw, xyz_wing, xyz_aligned, xyz_projected, collection_time] = OptoCollect(nMarkers, calibration, data)

if nargin < 3
    data = optotrak('DataGetNext3D', nMarkers);
end

try
    collection_time = toc;
catch
    collection_time = NaN;
    tic
end

if isstruct(data) && iscell(data.Markers)
    xyz_raw = cell2mat(data.Markers')'; % each marker is a row vector
else
    xyz_raw = data;
    assert(size(xyz_raw,2) == 3, 'xyz data must be row vectors')
    if isempty(nMarkers)
        nMarkers = size(data,1);
    end
    assert(size(data,1)==nMarkers, 'number of markers is not the same as rows of data')
end

xyz = xyz_raw';
xyz_wing = nan(1,3);
xyz_aligned = nan(nMarkers,3);
xyz_projected = nan(nMarkers,3);
ptb = nan(nMarkers,2);

missing = all(isnan(xyz_raw(:)));
if nargin == 1; calibration = []; end

% calculate fingertip position using multi-marker device
if isfield(calibration, 'Bcoeffs') && ~isempty(calibration.Bcoeffs) && size(xyz_raw, 1) == 6
    [xyz_wing_temp, missing] = CalcFingertip(xyz', calibration.Bcoeffs); % calculates finger pos from wing
    if ~missing; xyz_wing = xyz_wing_temp; end 
    xyz = xyz_wing';
end

% align to new coordinate system
if isfield(calibration, 'R') && ~isempty(calibration.R)
    xyz = calibration.R * [xyz; ones(1,size(xyz,2))]; % aligns it to convenient coordinate system
    xyz_aligned = xyz(1:3,:)';
end

% project from eye onto table
check_fields = {'n', 'V0', 'P0'};
if all(isfield(calibration, check_fields)) && ~any(cellfun(@(f) isempty(calibration.(f)), check_fields))
    xyz = projection(calibration.n, calibration.V0, calibration.P0, xyz(1:3,:)); % project finger onto table
    xyz_projected = xyz';
end

% convert from table to psychtoolbox space
if isfield(calibration, 'M') && ~isempty(calibration.M)
    ptb = calibration.M * [xyz; ones(1,size(xyz,2))];
    ptb = ptb(1:2,:)';
end

xyz = xyz';



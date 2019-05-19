% [coords, missing] = CALCFINGERTIP(data, Bcoeffs[, S]) estimates the
% position of the fingertip using new wing data, beta regression weights,
% and an option matrix S of standard distances between the markers for
% figuring out which are most reliable for this data. Returns the
% coordinates of the fingertip and a flag if the data are missing or
% unreliable.
% 
% E. Gaffin-Cahn    2/2019

function [coords, missing] = CalcFingertip(xyz, Bcoeffs, standardDistances)

if nargin == 3 && ~isempty(standardDistances)
    [C, B] = FindReliableMarkers(xyz, Bcoeffs, standardDistances);
    combinations = 1:3;
    if isempty(C)
        missing = true;
        coords = nan(3,1);
        return
    end
else
    C = xyz;
    B = Bcoeffs;
    combinations = nchoosek(1:6,3);
end

coords = nan(size(combinations,1),3);
for i = 1:size(combinations)
    p = C(combinations(i,:),:);
    coords(i,:) = predict(p(3,:), p(2,:), p(1,:), B{i});
end
coords = nanmedian(coords,1);
missing = all(isnan(coords(:)));


function coords = predict(p1, p2, p3, B)

v1to2  = p1-p2;
v1to3  = p3-p2;
vCross = cross(v1to2, v1to3);

coords = p2 + v1to2*B(1) + vCross*B(2) + v1to3*B(3);


% [C, B] = FINDRELIABLEMARKERS(data, Bcoeffs, standardDistances) takes the
% current Optotrak data and the known distances between each marker on the
% wing. It finds the 3 most reliable markers and returns only the data from
% those and the appropriate beta weights for finding the fingertip. If
% the marker positions are not reliable enough, it returns empties.
% 
% E. Gaffin-Cahn    2/2019

function [C, B] = FindReliableMarkers(xyz, Bcoeffs, standardDistances)

ind = FindBest(xyz, standardDistances);
if isempty(ind)
    C = [];
    B = [];
    return
end

combinations = nchoosek(1:length(standardDistances), 3);

C = xyz(sort(ind(1:3)),:);
B = Bcoeffs(all(repmat(sort(ind(1:3)), [size(combinations,1),1]) == combinations, 2));

% ordered_indices = FINDBEST(xyz, S) chooses the most consistent markers.
% If there are not enough (3) consistent markers, it takes the least
% consistent one, throws it out, and re-evaluates consistency. It does this
% process iteratively until either there are enough reliable markers or
% not, in which case the data will be flagged as missing.

function ordered_indices = FindBest(xyz, S)

N = size(xyz,1);
keep = all(~isnan(xyz'));
if sum(keep) < 3
    ordered_indices = [];
    return
end

D = GetDistanceMatrix(xyz);

ssd = nansum((D - S) .^ 2);
ssd(all(isnan(D))) = NaN;

[sorted_ssd, ordered_indices] = sort(ssd);

if sorted_ssd(3) > 0.5 % absolute threshold that we won't accept
    % Goal here: keep is the history of markers we've thrown out. Need to
    % determine which marker is the worst that we haven't thrown out yet.
    markers_remaining = find(keep);
    ordered_remaining = ismember(ordered_indices, markers_remaining);
    worst_marker_index = find(ordered_remaining, 1, 'last');
    worst_marker = ordered_indices(worst_marker_index);
    keep = keep & 1:N ~= worst_marker;
    xyz(~keep,:) = NaN;
    S(~keep,:) = NaN;
    S(:,~keep) = NaN;
    ordered_indices = FindBest(xyz, S);
end


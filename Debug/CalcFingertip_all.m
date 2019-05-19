% [coords, missing] = CALCFINGERTIP_ALL(data, Bcoeffs, D) estimates the
% position of the fingertip using new wing data, beta regression weights,
% and a matrix D of standard distances between the markers for figuring out
% which are most reliable for this data. Returns the coordinates of the
% fingertip and a flag if the data are missing or unreliable.
% 
% E. Gaffin-Cahn    3/2019

function [coords_all, missing] = CalcFingertip_all(xyz, Bcoeffs, varargin)

combinations = nchoosek(1:6,3);

coords_all = nan(size(combinations,1),3);

for i = 1:size(combinations)
    
    C = xyz(combinations(i,:),:);
    B = Bcoeffs{i};
    
    p1 = C(3,:);
    p2 = C(2,:);
    p3 = C(1,:);
    
    v1to2  = p1-p2;
    v1to3  = p3-p2;
    vCross = cross(v1to2, v1to3);
    
    coords = p2 + v1to2*B(1) + vCross*B(2) + v1to3*B(3);
    coords_all(i,:) = coords;
end

missing = all(isnan(coords_all(:)));

function plotM(X, color, alpha)


if size(X, 2) == 1
    plot3(X(1), X(2), X(3), 'o', 'Color', color, 'MarkerFaceColor', color)
    return
end


if size(X,2) == 4
    sz = size(X,2);
    faces = [1 2 3 4];
else
    sz = size(X,2)/2;
    faces = [1 2 4 3; 5 6 8 7; 1 2 6 5; 3 4 8 7; 1 3 7 5; 2 4 8 6];
end

for i = 1:sz
    text(X(1,i), X(2,i), X(3,i), num2str(i))
end
if nargin < 2 || isempty('color')
    color = 'b';
end
if nargin < 3 || isempty('alpha')
    alpha = .25;
end

for i = 1:size(faces,1)
    h = fill3(X(1,faces(i,:)), X(2,faces(i,:)), X(3,faces(i,:)), color);
    set(h, 'FaceAlpha', alpha)
end
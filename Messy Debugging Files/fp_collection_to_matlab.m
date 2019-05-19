fp = readtable('collection_2019_02_21_161522_002_3d.csv', 'HeaderLines', 3);
fp = fp(:,2:end);
x = nan(height(fp), 6, 3);
for i = 1:size(x,1) % scroll through samples
    for j = 1:size(x,2) % scroll through markers
        for k = 1:size(x,3) % scroll through xyz
            col = (j-1)*3+k;
            x(i,j,k) = table2array(fp(i,col));
        end
    end
end
hz = 100;
xl = size(x,1)/hz;
t = linspace(1/hz,xl,xl*hz);
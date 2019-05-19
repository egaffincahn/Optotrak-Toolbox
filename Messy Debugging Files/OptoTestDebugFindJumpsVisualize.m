%%
data.NumMarkers = 6;
calibration = load('calibration');
% load wingdata
xf = nan(size(x,1),3);
for i = 1:size(x)
    y = cell(data.NumMarkers,1);
    for j = 1:data.NumMarkers
        y{j,1} = squeeze(x(i,j,:));
    end
    data.Markers = y;
    [xyz_wing_temp, missing] = DualBetaTransform(data, calibration.Bcoeffs); % calculates finger pos from wing
    if ~missing
        xf(i,:) = xyz_wing_temp;
    end
end

%%
figure(1), clf, plotTimeCourse(x, t, xl);
samples2plot = (1:200) - 200;

%% plot the next set of data in native 3d space
figure(2), clf
samples2plot = samples2plot + 200;
plot3(xf(samples2plot,1), xf(samples2plot,2), xf(samples2plot,3), '.-');
set(gca, 'DataAspectRatio', [1 1 1])


figure(3), clf

subplot(2,2,1)
plot(t(samples2plot)-t(1), xf(samples2plot,1), '.--')


subplot(2,2,2)
plot(t(samples2plot)-t(1), xf(samples2plot,2), '.--')


subplot(2,2,3)
plot(t(samples2plot)-t(1), xf(samples2plot,3), '.--')


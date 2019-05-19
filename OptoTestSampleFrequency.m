
%%
nMarkers = 3;
OptoCalibLoad(nMarkers);

%%
[fnumber, t] = deal(nan(1,500));
tic
for i = 1:length(t)
%     data = optotrak('DataGetNext3D', nMarkers);
    data = optotrak('DataGetLatestCentroid', nMarkers);
    fnumber(i) = data.FrameNumber;
    t(i) = toc;
end
ff = 1./diff(t);
subplot(2,1,1), histogram(ff, 100)
subplot(2,1,2), scatter(ff, diff(fnumber))

%%
[fnumber, t] = deal(nan(1,500));
tic
for i = 1:length(t)
    optotrak('RequestLatest3D')
    while ~optotrak('DataIsReady')
        %
    end
    data=optotrak('DataReceiveLatest3D',nMarkers);
    fnumber(i) = data.FrameNumber;
    t(i) = toc;
end
ff = 1./diff(t);
subplot(2,1,1), histogram(ff, 100)
subplot(2,1,2), scatter(ff, diff(fnumber))

%%
OptoDenit;
function OptoInit(coll)
%Load the system of transputers.
optotrak('TransputerLoadSystem','system');

%Wait one second to let the system finish loading.
pause(1);

%Initialize the transputer system.
optotrak('TransputerInitializeSystem',{'OPTO_LOG_ERRORS_FLAG'});

%Load the standard camera parameters.
optotrak('OptotrakLoadCameraParameters',coll.CameraFile);

%Set up a collection for the OPTOTRAK.
optotrak('OptotrakSetupCollection',coll);

%Activate the markers.
optotrak('OptotrakActivateMarkers');
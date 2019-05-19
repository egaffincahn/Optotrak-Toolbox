function [raspberrysnd,timeoutsnd,hitbeepsnd,gobeepsnd,bothbeepsnd,thhhpsnd,tinksnd]=MakeSounds

raspberrysnd=[sin(2*pi*0.004*[0:8000])*10]; % sound to play for errors
timeoutsnd=[sin(2*pi*0.03*[0:500]) sin(2*pi*0.028*[0:500]) ...
    sin(2*pi*0.026*[0:500]) sin(2*pi*0.024*[0:500]) sin(2*pi*0.022*[0:500]) ...
    sin(2*pi*0.02*[0:500]) sin(2*pi*0.018*[0:500]) sin(2*pi*0.016*[0:500]) ...
    sin(2*pi*0.014*[0:500]) sin(2*pi*0.012*[0:500]) sin(2*pi*0.01*[0:500]) ...
    sin(2*pi*0.008*[0:500]) sin(2*pi*0.006*[0:500]) sin(2*pi*0.004*[0:500]) ]; % sound to play for timeout
hitbeepsnd=[sin(2*pi*0.07*[0:2000]) sin(2*pi*0.12*[0:4000])];
gobeepsnd=[sin(2*pi*0.1*[0:1000])];

%bothbeep=[sin(2*pi*0.057*[0:2000]) sin(2*pi*0.090*[0:2000]) sin(2*pi*0.004*[0:8000])*10];
bothbeepsnd=[hitbeepsnd timeoutsnd];
%thhhpsnd=[randn(2500,1)*.08; randn(200,1)+.5];
thhhpsnd=[randn(1,500)*.08, randn(1,120)+.5];
tinksnd=raspberrysnd(round(linspace(1,length(raspberrysnd),500)));

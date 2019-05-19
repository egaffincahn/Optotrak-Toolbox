function clearPlot(fig)

if nargin, figure(fig), end

clf, hold on, grid on
% xlim([-500 1500])
% ylim([-500 1500])
% zlim([-1500 500])
set(gca, 'DataAspectRatio', [1 1 1])
set(gca, 'View', [-120, 30])
xlabel('x'), ylabel('y'), zlabel('z')
% plot(0, 0, 'k+')



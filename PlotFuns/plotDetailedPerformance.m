function figHandle = plotDetailedPerformance(RealTrlDSet, SimTrlDSet, ...
            OptTrlDSet, blkType)
% Plot performance of each individual, along with performance of models
% fits, and the theoretically achievable performance

% INPUT
% RealTrlDSet: Dataset in the standard format, that stores data at the level of
% trials, for the real data, and that contains model fitting results
% SimTrlDSet: Simulated TrlDSet dataset based on RealTrlDSet. The 
% participants should match up in terms of order to RealTrlDSet
% OptTrlDSet: A dataset simulated using theoertically maximally optimal
% behaviour. I.e. no internal sources of noise and perfectly aligned
% parameters
% blkType: str. Plot results for 'instructed' or for 'inferred'?

% HISTORY
% 2021, JCT

figHandle = figure;
hold on

b1 = bar(computePerPtpntAcc(SimTrlDSet, blkType), 'FaceColor', ...
    [0.8 0.8 0.8], 'EdgeColor', 'none');
b2 = bar(computePerPtpntAcc(RealTrlDSet, blkType), 'FaceColor', 'none');

yline(mean(computePerPtpntAcc(OptTrlDSet, blkType)), '-', ...
    'Theoretical max.')
yline(0.5, '--')

oldYlim = ylim();
ylim([0.45, oldYlim(2)])
xlim([0.5, length(RealTrlDSet.P)+1.5])

xticks(1:5:20)
xlabel('Participant')
yticks(0.5:0.1:oldYlim(2))
ylabel('Accuracy')
set(gca, 'TickDir', 'out')

legend([b2, b1], 'Data', 'Model fit', 'Location', 'northwest')
legend('boxoff')

end


function figHandle = plotInstInfPerform(RealTrlDSet)
% Plot performance of each individual in the instructed compared to the 
% inferred condtion 
%
% INPUT
% RealTrlDSet: Dataset in the standard format, that stores data at the level of
% trials, for the real data, and that contains model fitting results

% HISTORY
% 2025, JCT

figHandle = figure;
hold on

instrAcc = computePerPtpntAcc(RealTrlDSet, 'instructed');
inferAcc = computePerPtpntAcc(RealTrlDSet, 'inferred');

testVals = instrAcc - inferAcc;
[~, pValue, ~, stats] = ttest(testVals);
cohenD = mean(testVals) / stats.sd; % One-sample variant: mean divived by
% estimated population SD.
snippet = ['($ t(' num2str(stats.df) ')= ' num2str(stats.tstat) '$, $p= ' num2str(pValue) '$, ' ...
        'two-tailed, $d=' num2str(cohenD) '$)'];
disp('Paired T-test on difference between instrAcc and inferAcc')
disp(snippet)

scatter(instrAcc, inferAcc, 18, 'k')
xline(mean(instrAcc), 'k')
yline(mean(inferAcc), 'k')
xlabel('Instructed')
ylabel('Inferred')

lower = 0.65;
upper = 1;
assert(all(instrAcc > lower))
assert(all(inferAcc > lower))
assert(all(instrAcc < upper))
assert(all(inferAcc < upper))
xticks([0.7, 1])
yticks([0.7, 1])
xlim([lower, upper])
ylim([lower, upper])

set(gca, 'TickDir', 'out')
ax = gca;
ax.TickLength = [0.05, 0.05];

end


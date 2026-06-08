function plotAveragePerformance(RealTrlDSet)
% Plot averge performance accross the group for various models in the 
% inferred condition

% INPUT
% RealTrlDset: Dataset storing trial-level data, and including model 
%   fitting results.

figure;
hold on;

computeSem = @(vals) std(vals) ./ sqrt(sum(~isnan(vals)));

appliedModels = mT_findAppliedModels(RealTrlDSet);
SimDSets = cell(length(appliedModels), 1);
avAcc = nan(length(appliedModels), 1);
semAcc = nan(length(appliedModels), 1);

for iM = 1 : length(appliedModels)
    SimDSets{iM} = simulateRespAndAccFromStim(RealTrlDSet, ...
        'fittedParams', appliedModels{iM}, RealTrlDSet);
    
    accVals = computePerPtpntAcc(SimDSets{iM}, 'inferred');
    assert(~any(isnan(accVals)))
    avAcc(iM) = mean(accVals);
    semAcc(iM) = computeSem(accVals);
end

modelList = findModelNames(appliedModels);
xPositions = 1:length(modelList);
bar(xPositions, avAcc, 'FaceColor', [0.8 0.8 0.8], 'EdgeColor', 'none')
errorbar(xPositions, avAcc, semAcc, semAcc, ...
    'LineStyle','none', 'Color', [0.8 0.8 0.8])

% Real data
accVals = computePerPtpntAcc(RealTrlDSet, 'inferred');
assert(~any(isnan(accVals)))
realAv = mean(accVals);
realSem = computeSem(accVals);

yline(realAv+realSem, 'Color', 'black')
yline(realAv-realSem, 'Color', 'black')

xticks(xPositions)
xticklabels(modelList)
xtickangle(90)

oldYlim = ylim();
ylim([0.45, oldYlim(2)])

yticks(0.5:0.1:oldYlim(2))
ylabel('Accuracy')
set(gca, 'TickDir', 'out')



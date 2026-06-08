function Figs = makeAllRegPlots(plotSaveDir, DSets, Options)
% Makes several regression analysis plots

% INPUT
% plotSaveDir: string. Directory where plots should be saved
% DSets: struct. Keys are names of specific datasets and the values provide
%   those datasets in the standard format. Keys are...
%       RealTrlDSet: Data in the standard format, that stores data at the
%           level of trials, for the real data, and that contains model
%           fitting results
%       SimTrlDSet: (optional) A simulated dataset (representing data at 
%           the level of trials), simulated based on fitted parameter 
%           values from the dataset in RealTrlDSet. Participants should 
%           match up in terms of order in RealTrlDSet. If provided then
%           variants of the regression analysis will be performed on this
%           simualted data and plotted.
%       SimRegDSet: (optional) A simulated dataset (representing data at 
%           the level of trials) which has then had runRegressionAnalysis 
%           applied to produce a representation of the regression results.
%           It is important that all the defaults of runRegressionAnalysis 
%           were used, because this dataset will be compared to the real
%           data processed in this way. Simulate based on fitted 
%           parameter values from the dataset in RealTrlDSet. Participants 
%           should match up in terms of order in RealTrlDSet. The same
%           number of plots will be made whether or not this input is 
%           provided, but if it is provided, the correspoinding regression
%           analysis will not need to be reconducted by this function.
% Options: struct. Has the following keys:
%   SkipIce: bool. If true skip some plots of the effect of ice.
%   ModelForCompVars: str. Model name. Which model to use for computing the 
%       values of the computational variables (for those plots where use 
%       fitted params to compute the computational variables instead of the 
%       true values).
%   SigHeights: vector of scalar. Optional. Values to use for setting the 
%       height of the bars indicating significance. Must be at least as 
%       long as the number of groups in the dataset (i.e. the number of 
%       groups found with the function "findGroupInfo").
%   CoreModelOnly: bool. Optional. If true (and have model fit data) only 
%       plot the main model comparison figure. Defualt is false.

% OUTPUT
% Figs: struct. Contains figure handles. Keys and values are...
%   Regression: The figure for the main regression analysis, including
%       model fits if requested.

% HISTORY
% 10.10.2023 Updated for Coimbra data

if ~isfield(Options, 'SigHeights')
    Options.SigHeights = [-1, -1.5];
end

if ~isfield(Options, 'CoreModelOnly')
    Options.CoreModelOnly = false;
end

DSetNames = fieldnames(DSets);
assert(all(ismember(DSetNames, {'RealTrlDSet', 'SimTrlDSet', ...
    'SimRegDSet'})))
Figs = struct();

% We already have simulated regression results, now just need to perform
% the regression on the real data
runBinSpecificReg = @(ThisDSet, thisBinAfter, thisBeforeBinSize) ...
    runRegressionAnalysis(ThisDSet, [], [], thisBinAfter, [], ...
        thisBeforeBinSize);

for bin = {'before', 'after'}
    if strcmp(bin{1}, 'after')
        figField = 'Regression';
        beforeBinSize = 1;
        binAfter = true;
        if ismember('SimRegDSet', DSetNames)
            ThisSimRegDSet = DSet.SimRegDSet;

        elseif ismember('SimTrlDSet', DSetNames)
            ThisSimRegDSet = runBinSpecificReg(DSets.SimTrlDSet, ...
                binAfter, beforeBinSize);
        else
            ThisSimRegDSet = 'none';
        end

    elseif strcmp(bin{1}, 'before')
        figField = 'Regession_binBefore';
        beforeBinSize = 3;
        binAfter = false;
        if ismember('SimTrlDSet', DSetNames) && ~Options.CoreModelOnly
            ThisSimRegDSet = runBinSpecificReg(DSets.SimTrlDSet, ...
                binAfter, beforeBinSize);
        else
            ThisSimRegDSet = 'none';
        end
    else
        error('Bug')
    end

    RealRegDSet = runBinSpecificReg(DSets.RealTrlDSet, binAfter, ...
        beforeBinSize);
    [~, expectGroups, ~] = findGroupInfo(RealRegDSet);
    sigHeight = Options.SigHeights(1:length(expectGroups));
    Figs.(figField) = plotRegressionSepByGroup(RealRegDSet, 'default', ...
        'scatter', expectGroups, [], plotSaveDir, sigHeight);

    if ~strcmp(ThisSimRegDSet, 'none')
        plotRegressionSepByGroup(ThisSimRegDSet, 'default', ...
            'errorShading', expectGroups, Figs.(figField))
    end
    mT_exportNicePdf(15.9, 15.9/2, plotSaveDir, figField)
end


if length(expectGroups) == 1
    plotRegressionResults(RealRegDSet, 'default', 'strings');
    mT_exportNicePdf(15.9*(5/4), 15.9/2, plotSaveDir, 'regression_strings')
end


% Regression without z-scoring
RealRegDSet = runRegressionAnalysis(DSets.RealTrlDSet, [], [], [], false);
[~, expectGroups, ~] = findGroupInfo(RealRegDSet);
figHandle = plotRegressionSepByGroup(RealRegDSet, 'default', 'scatter', ...
    expectGroups, [], plotSaveDir, sigHeight);

if ismember('SimTrlDSet', DSetNames) && ~Options.CoreModelOnly
    SimRegDSet_noZScore = runRegressionAnalysis(DSets.SimTrlDSet, [], ...
        [], [], false);

    plotRegressionSepByGroup(SimRegDSet_noZScore, 'default', ...
        'errorShading', expectGroups, figHandle)
end
mT_exportNicePdf(15.9*(5/4), 15.9/2, plotSaveDir, 'regression_noZScore')


% If plot type is 'model' then we have model fitting
% results and we can plot the regression using computational variables
% computed using the fitted parameters instead of using the true
% parameters.
if ismember('SimRegDSet', DSetNames)
    RealRegDSet = runRegressionAnalysis(DSets.RealTrlDSet, [], ...
        Options.ModelForCompVars);
    plotRegressionSepByGroup(RealRegDSet, 'default', 'scatter', ...
        expectGroups);
    mT_exportNicePdf(15.9*(5/4), 15.9/2, plotSaveDir, ...
        'regressionWithFitParams')
end


% Run the SCP regression
RealRegDSet = runRegressionAnalysis(DSets.RealTrlDSet, 'SCP', [], false);
plotRegressionSepByGroup(RealRegDSet, 'SCP', 'scatter', ...
        expectGroups);
mT_exportNicePdf(15.9*(5/4), 15.9/2, plotSaveDir, 'regressionSCP')


% Plot regression results separately for ice water vs. control
if ~Options.SkipIce
    RealRegDSet = runRegressionAnalysis(DSets.RealTrlDSet, 'iceMod', [], true);
    iceFig = plotRegressionResults(RealRegDSet.BothSeries, 'iceMod', ...
                                    'scatter');
    iceFig = plotRegressionResults(RealRegDSet.DiffSeries, 'iceDiff', ...
        'hidden', iceFig, [], plotSaveDir);
    Figs.IceFig = iceFig;

    mT_exportNicePdf(15.9/1.55, 15.9/3, plotSaveDir, ...
        'regressionWithIce_paper')
end

function figHandle = plotRegressionSepByGroup(RegDSet, variety, ...
    plotType, expectedGroups, varargin)
% Plot the effect of the cues running up to a choice on the rule used to
% make the choice, seperately for different groups of participants.

% RegDSet: Data set in the standard format that is storing regression
%   results. Produced by runRegressionAnalysis.m
% variety: str. Variety of the regression performed. 'default' if the 
%   standard regression was performed without consdiering the effects of 
%   the ice water, 'iceMod' if the regression did take into account ice, 
%   and 'SCP' if ran the subsequent change probability regression.
% plotType: str. Passed onto mT_plotVariableRelations in the correct 
%   format. 
% expectedGroups: May be empty if only one group of participants exists.
%   Otherwise a cell array giving the expected groups and their ordering,
%   to be used for checks that repeated calls are plotting groups in
%   matching colours.
% varargin{1}: Figure handle to plot onto. If the old figure
%   has the same subplot structure, then all the data in the old
%   subplots will be retianed.
% varargin{2}: string filepath. If provided, cluster-based statistics are
%   performed and signiifcant points are indicated on the plot. The 
%   provided filepath is used for saving temporary files. May only be used
%   for series where plotType is 'scatter', to avoid 
%   ambiguitiy (multiple series may use the same colour but different 
%   plot types, but significant points are only indicated through colour).
% varargin{3}: vector of scalar as long as the number of groups. Gives the
%   height at which to draw lines indicating significance for each group.

% HISTORY
% 2023, JCT
% Written also for Coimbra data

if (~isempty(varargin)) && (~isempty(varargin{1}))
    figHandle = varargin{1};
else
    figHandle = figure;
end

if (length(varargin) > 1) && (~isempty(varargin{2}))
    sigTmpDir = varargin{2};
else
    sigTmpDir = [];
end

if (length(varargin)>=3) && (~isempty(varargin{3}))
    sigHeight = varargin{3};
else
    sigHeight = [];
end

plotFun = @(TrimDSet, figHandle, colour, thisSigHeight) ...
    plotRegressionResults(TrimDSet, variety, plotType, figHandle, ...
        colour, sigTmpDir, thisSigHeight);
plotSepByGroup(plotFun, RegDSet, expectedGroups, figHandle, sigHeight);

end



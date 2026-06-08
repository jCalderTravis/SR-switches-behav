function figHandle = plotCueEffect(CueDSet, plotType, sepIce, ...
    blkType, varargin)
% Plot the effect of the cues running up to a choice on the rule used to
% make the choice

% INPUT
% CueDSet: Stacked version of the cue-based representation of the data
%   (i.e. the function stackCueDSet has been applied).
% plotType: str.
% sepIce: boolean. Plot data for ice water vs. no ice water separately
%   (true), or plot all data together (false)
% blkType: str. Function only plots the data for one block type. Which one
%   to plot?
% varargin{1}: Figure handle to plot onto. If the old figure
%   has the same subplot structure, then all the data in the old
%   subplots will be retianed.
% varargin{2}: 3-element vector. May only be provided if the other options
%   are selected such that a single series is being plotted. This input 
%   determines the colour the single series that is being plotted.
% varargin{3}: string filepath. If provided, cluster-based statistics are
%   performed and signiifcant points are indicated on the plot. The 
%   provided filepath is used for saving temporary files. May only be used
%   for series where plotType is 'scatter', to avoid 
%   ambiguitiy (multiple series may use the same colour but different 
%   plot types, but significant points are only indicated through colour).
% varargin{4}: scalar. The height in data coordinates at which to plot 
%   lines indicating significant data.
% varargin{5}: bool. If true (default) include the name of the block type
%   in the x-axis label.

% HISTORY
% 2021, JCT

if (~isempty(varargin)) && (~isempty(varargin{1}))
    figHandle = varargin{1};
else
    figHandle = figure;
end

if (length(varargin)>1) && (~isempty(varargin{2}))
    overrideColour = varargin{2};
else
    overrideColour = [];
end

if (length(varargin)>=3) && (~isempty(varargin{3}))
    sigTmpDir = varargin{3};
else
    sigTmpDir = [];
end

if (length(varargin)>=4) && (~isempty(varargin{4}))
    sigHeight = varargin{4};
else
    sigHeight = [];
end

if (length(varargin)>=5) && (~isempty(varargin{5}))
    incBlockName = varargin{5};
else
    incBlockName = true;
end

if ~isfield(CueDSet.P(1).Data, 'CueNumRelativeToResponse')
    error(['Has this Cue-based representation of the dataset been ', ...
        'stacked using the function stackCueDSet?'])
end

XVars(1).ProduceVar = @(Data) Data.CueNumRelativeToResponse;
XVars(1).NumBins = 'prebinned';
XVars(1).FindIncludedTrials = @(Data) strcmp(Data.BlockType, blkType);

YVars(1).ProduceVar = @(Data, inc) mean(Data.CueLocSignedDemeaned(inc));
YVars(1).FindIncludedTrials = @(Data) logical(Data.RtOfRespIsValid);

if ~sepIce
    Series(1).FindIncludedTrials = @(Data) true;

    if ~isempty(overrideColour)
        PlotStyle.Data(1).Colour = overrideColour;
    else
        PlotStyle.Data(1).Colour = mT_pickColour(1);
    end
elseif sepIce
    Series(1).FindIncludedTrials = @(Data) Data.WasIceSess == 1;
    Series(2).FindIncludedTrials = @(Data) Data.WasIceSess == 0;
    assert(isempty(overrideColour))
    PlotStyle.Data(1).Colour = mT_pickColour(3);
    PlotStyle.Data(2).Colour = mT_pickColour(2);
    PlotStyle.Data(1).Name = 'Ice water';
    PlotStyle.Data(2).Name = 'Control';
end

PlotStyle.General = 'paper';
PlotStyle.Xaxis(1).Title = {'Cue number', 'relative to response'};
if incBlockName
    PlotStyle.Xaxis(end+1).Title = ...
        {['{\bf' strrep(blkType, '_', ' ') '}']};
end
PlotStyle.Yaxis(1).Title = {'Evidence residuals', ...
    'favouring context used'};
PlotStyle.Yaxis(1).RefVal = 0;
PlotStyle.Yaxis(1).SigHeight = sigHeight;
for iS = 1 : length(Series)
    PlotStyle.Data(iS).PlotType = plotType;
end

[figHandle, ~] = mT_plotVariableRelations(CueDSet, XVars, YVars, ...
    Series, PlotStyle, figHandle, [], sigTmpDir);

end
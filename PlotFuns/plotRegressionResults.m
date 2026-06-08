function figHandle = plotRegressionResults(RegDSet, variety, plotType, ...
    varargin)
% Plot the effect of the cues running up to a choice on the rule used to
% make the choice

% RegDSet: Data set in the standard format that is storing regression
%   results. Produced by runRegressionAnalysis.m
% variety: str. Variety of the regression performed. 'default' if the 
%   standard regression was performed without consdiering the effects of 
%   the ice water, 'iceMod' if the regression did take into account ice, 
%   and 'SCP' if ran the subsequent change probability regression. Use
%   'iceDiff' if ran the 'iceMod' regression, but then computed the 
%   difference between the "with ice" and "without ice" series. In this 
%   case only significance lines for the difference series are plotted
%   (and not the difference series itself).
% plotType: str. Normally passed onto mT_plotVariableRelations in the
%   correct format. However, if set to 'strings', then plots a thin line 
%   for each participant, and a thick line for the group average.
% varargin{1}: Figure handle to plot onto. If the old figure
%   has the same subplot structure, then all the data in the old
%   subplots will be retianed.
% varargin{2}: 3-element vector. May only be provided if the other options
%   are selected such that a single series is being plotted. Also not
%   compatible with plotType=='strings'. This input determines the colour 
%   the single series that is being plotted.
% varargin{3}: string filepath. If provided, cluster-based statistics are
%   performed and signiifcant points are indicated on the plot. The 
%   provided filepath is used for saving temporary files. 
% varargin{4}: scalar. The height in data coordinates at which to plot 
%   lines indicating significant data.

% HISTORY
% 2021, JCT
% 10.10.2023 Updated for Coimbra data

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

XVars(1).ProduceVar = @(Data) Data.CueNumRelativeToNextResponse;
XVars(1).NumBins = 'prebinned';

YVars(1).ProduceVar = @(Data, inc) retrieveValue(Data, 'LLR', inc);
YVars(1).FindIncludedTrials = ...
    @(Data) true(length(Data.CueNumRelativeToNextResponse), 1);

if any(strcmp(variety, {'default', 'iceMod', 'iceDiff'}))
    YVars(2).ProduceVar = @(Data, inc) retrieveValue(Data, ...
        'LLR_x_CPP', inc);
    YVars(2).FindIncludedTrials = ...
        @(Data) true(length(Data.CueNumRelativeToNextResponse), 1);
    
    YVars(3).ProduceVar = @(Data, inc) retrieveValue(Data, ...
        'LLR_x_Uncert', inc);
    YVars(3).FindIncludedTrials = ...
        @(Data) true(length(Data.CueNumRelativeToNextResponse), 1);

elseif strcmp(variety, 'SCP')
    YVars(2).ProduceVar = @(Data, inc) retrieveValue(Data, ...
        'LLR_x_SCP', inc);
    YVars(2).FindIncludedTrials = ...
        @(Data) true(length(Data.CueNumRelativeToNextResponse), 1);
else
    error('Unknown input')
end

if any(strcmp(variety, {'default', 'SCP'}))
    Series(1).FindIncludedTrials = ...
        @(Data) true(length(Data.CueNumRelativeToNextResponse), 1);
    
    if ~isempty(overrideColour)
        PlotStyle.Data(1).Colour = overrideColour;
    else
        PlotStyle.Data(1).Colour = mT_pickColour(1);
    end
elseif strcmp(variety, 'iceMod')
    Series(1).FindIncludedTrials = @(Data) Data.WasIceSess == 1;
    Series(2).FindIncludedTrials = @(Data) Data.WasIceSess == 0;
    PlotStyle.Data(1).Colour = mT_pickColour(3);
    PlotStyle.Data(2).Colour = mT_pickColour(6);
    assert(isempty(overrideColour))
    PlotStyle.Data(1).Name = 'Ice water';
    PlotStyle.Data(2).Name = 'Warm water';

elseif strcmp(variety, 'iceDiff')
    Series(1).FindIncludedTrials = ...
        @(Data) true(length(Data.CueNumRelativeToNextResponse), 1);
    PlotStyle.Data(1).Colour = mT_pickColour(1);
    assert(isempty(overrideColour))
else
    error('Unknown input')
end

% Find limits of data
minLag = nan;
maxLag = nan;
for iP = 1 : length(RegDSet)
   minLag = nanmin([minLag; ...
       RegDSet.P(iP).Data.CueNumRelativeToNextResponse]);
   maxLag = nanmax([maxLag; ...
       RegDSet.P(iP).Data.CueNumRelativeToNextResponse]);
end
assert(length(minLag) == 1)
assert(length(maxLag) == 1)

PlotStyle.General = 'paper';
PlotStyle.Xaxis(1).Title = {'Cue number ', 'relative to response'};
PlotStyle.Xaxis(1).Lims = [(minLag -1), max(maxLag +1, 0)];
PlotStyle.Yaxis(1).Title = {'Effect of ', 'LLR'};
PlotStyle.Yaxis(1).RefVal = 0;
if any(strcmp(variety, {'default', 'iceMod', 'iceDiff'}))
    PlotStyle.Yaxis(2).Title = {'Effect of ', 'LLR x CPP'};
    PlotStyle.Yaxis(2).RefVal = 0;
    PlotStyle.Yaxis(3).Title = {'Effect of ', 'LLR x uncertainty'};
    PlotStyle.Yaxis(3).RefVal = 0;

    if strcmp(variety, 'iceDiff')
        PlotStyle.Annotate = struct();
        PlotStyle.Annotate(1, 1).Text = 'A';
        PlotStyle.Annotate(2, 1).Text = 'B';
        PlotStyle.Annotate(3, 1).Text = 'C';
    end

elseif strcmp(variety, 'SCP')
    PlotStyle.Yaxis(2).Title = {'Effect of ', 'LLR x SCP'};
    PlotStyle.Yaxis(2).RefVal = 0;
else
    error('Unknown input')
end

for iY = 1 : length(PlotStyle.Yaxis)
    PlotStyle.Yaxis(iY).SigHeight = sigHeight;
end

if strcmp(plotType, 'strings')
    assert(isempty(overrideColour))
    
    % Achieve thin line for each participant, and a thick line for the 
    % group average by calling the plotting function several times.
    for iS = 1 : length(Series)
        PlotStyle.Data(iS).PlotType = 'line';
        PlotStyle.Data(iS).Colour = [0.7, 0.7, 0.7];
    end
    
    for iP = 1 : length(RegDSet.P)
        TmpDSet = RegDSet;
        TmpDSet.P = RegDSet.P(iP);
    
        [figHandle, ~] = mT_plotVariableRelations(TmpDSet, XVars, YVars, ...
            Series, PlotStyle, figHandle, [], sigTmpDir);
    end
    
    % Now plot the average
    for iS = 1 : length(Series)
        PlotStyle.Data(iS).PlotType = 'thickLine';
        PlotStyle.Data(iS).Colour = [0, 0, 0];
    end
    
    [figHandle, ~] = mT_plotVariableRelations(RegDSet, XVars, YVars, ...
        Series, PlotStyle, figHandle, [], sigTmpDir);
else
    for iS = 1 : length(Series)
        PlotStyle.Data(iS).PlotType = plotType;
    end
    
    [figHandle, ~] = mT_plotVariableRelations(RegDSet, XVars, YVars, ...
        Series, PlotStyle, figHandle, [], sigTmpDir);
end



end


function value = retrieveValue(Data, field, inc)

fieldValues = Data.(field);
value = fieldValues(inc);
assert(length(value) == 1)

end


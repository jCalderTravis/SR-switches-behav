function figHandle = plotSepByGroup(plotFun, DSet, expectedGroups, ...
    varargin)
% Plot repeatedly to the same figure, each time plotting the data for a
% different group.

% INPUT
% plotFun: function handle. Will be passed the following arguments...
%   TrimDSet: DSet but trimmed down to only contain the data for
%       participants in a specific group.
%   figHandle: Figure handle for the figure to plot to.
%   colour: 3-length vector. The colour to plot this data in.
%   sigHeight: scalar. The height in data coordinates on the y-axis
%       to plot lines indicating significance.
% DSet: Dataset in standard format.
% expectedGroups: May be empty if only one group of participants exists.
%   Otherwise a cell array giving the expected groups and their ordering,
%   to be used for checks that repeated calls are plotting groups in
%   matching colours.
% varargin{1}: Figure handle to plot onto. If the old figure
%   has the same subplot structure, then all the data in the old
%   subplots will be retianed.
% varargin{2}: vector of scalar as long as the number of groups. Gives the
%   height at which to draw lines indicating significance for each group.

% OUTPUT
% figHandle: Figure handle of the figure used.

% HISTORY
% 2023, JCT
% Written also for Coimbra data

if (~isempty(varargin)) && (~isempty(varargin{1}))
    figHandle = varargin{1};
else
    figHandle = figure;
end

if (length(varargin)>=2) && (~isempty(varargin{2}))
    sigHeight = varargin{2};
else
    sigHeight = [];
end

[groups, uniqueGroups, uniqueGroupNames] = findGroupInfo(DSet);
if isempty(expectedGroups)
    assert(length(uniqueGroups) == 1)
else
    assert(isequal(uniqueGroups, expectedGroups))
end

grpColours = cell(length(uniqueGroups), 1);
for iG = 1 : length(uniqueGroups)
    grpColours{iG} = mT_pickColour(iG);
end

for iG = 1 : length(uniqueGroups)
    match = strcmp(groups, uniqueGroups{iG}); 
    TrimRegDSet = DSet;
    TrimRegDSet.P = DSet.P(match);

    if ~isempty(sigHeight)
        assert(length(uniqueGroups) == length(sigHeight))
        thisSigHeight = sigHeight(iG);
    else
        thisSigHeight = 0;
    end

    plotFun(TrimRegDSet, figHandle, grpColours{iG}, thisSigHeight)
end

if length(uniqueGroups) > 1
    mT_addLegend(figHandle, uniqueGroupNames, grpColours)
end



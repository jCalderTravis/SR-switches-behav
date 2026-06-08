function addRemoveAllSubpaths(direction)
% Add or remove all required folders to the matlab path

% INPUT
% direction: str. 'add' or 'remove'

% HISTORY
% 2021, JCT

paths = {'./BehavModelFuns', ...
        './DataFuns', ...
        './HelperFuns', ...
        './mat-comp-model-tools', ...
        './SR-switches-exp', ...
        './SR-switches-exp/helperFuns', ...
        './TestFuns', ...
        './PlotFuns', ...
        './SimulationFuns', ...
        './AnalysisFuns', ...
        './ProcessingSteps' ...
        };
addRemovePaths(direction, paths)

end

function addRemovePaths(addRemove, paths)
% Modify matlab path

% addRemove: string 'add' or 'remove'
% paths: cell array of strings

if strcmp(addRemove, 'add')
    for iPath = 1 : length(paths)
        addpath(paths{iPath})
    end
elseif strcmp(addRemove, 'remove')
    for iPath = 1 : length(paths)
        rmpath(paths{iPath})
    end
end
end
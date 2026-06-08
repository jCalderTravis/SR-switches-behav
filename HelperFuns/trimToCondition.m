function TrlDSet = trimToCondition(TrlDSet, condition)
% Trim dataset down to only the data that comes from certain conditions

% INPUT
% condition: str.  Trim the dataset down to specific conditions. 
%   'baseline', trims dataset down to only the no ice water sessions
%   'twoLevelTask' trims down to blocks which involved both the 
%       higher-level context inference and the lower-level stimulus to
%       response mapping.
%   'inferenceOnly' trims down to 'inference-only' blocks
%   'fullTaskLab' trims down to 'full_task_lab' blocks

% HISOTRY
% 09.06.2023 Updated for Coimbra data

for iP = 1 : length(TrlDSet.P)
    expected = ismember(TrlDSet.P(iP).Data.WasIceSess, [1, 0]);
    assert(all(expected(:)))
    
    expectBlks = {'inferred', 'instructed', ...
        'full_task_lab', 'full_task_scanner', 'inference-only'};
    expected = ismember(TrlDSet.P(iP).Data.BlockType, expectBlks);
    assert(all(expected(:)))
    
    if strcmp(condition, 'baseline')
        toKeep = ~TrlDSet.P(iP).Data.WasIceSess;
    
    elseif any(strcmp(condition, ...
                        {'twoLevelTask', 'inferenceOnly', 'fullTaskLab'}))
        
        if strcmp(condition, 'twoLevelTask')
            toKeepBlks = {'inferred', 'instructed', 'full_task_lab', ...
                'full_task_scanner'};

        elseif strcmp(condition, 'inferenceOnly')
            toKeepBlks = {'inference-only'};
        
        elseif strcmp(condition, 'fullTaskLab')
            toKeepBlks = {'full_task_lab'};
        else
            error('Bug')
        end
        toKeep = ismember(TrlDSet.P(iP).Data.BlockType, toKeepBlks);
    else
        error('Unknown input')
    end
    
    fields = fieldnames(TrlDSet.P(iP).Data);
    for iF = 1 : length(fields)
        oldData = TrlDSet.P(iP).Data.(fields{iF});
        assert(isequal(size(oldData), size(toKeep)))
        TrlDSet.P(iP).Data.(fields{iF}) = oldData(toKeep);
    end
    
    % Checks...
    newSize = size(TrlDSet.P(iP).Data.(fields{1}));
    for iF = 2 : length(fields)
        assert(isequal(newSize, size(TrlDSet.P(iP).Data.(fields{iF}))))
    end
    
    if strcmp(condition, 'baseline')
        expected = TrlDSet.P(iP).Data.WasIceSess == 0;
    elseif any(strcmp(condition, ...
                    {'twoLevelTask', 'inferenceOnly', 'fullTaskLab'}))
        expected = ismember(TrlDSet.P(iP).Data.BlockType, toKeepBlks);
    else
        error('Bug')
    end
    assert(all(expected(:)))
end
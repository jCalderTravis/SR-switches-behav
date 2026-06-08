function DForm = findDataFormat(DSet)

% INPUT
% DSet: Either a data set, or the data (i.e. DSet or DSet.P(i).Data). If 
%   left empty, just returns information that is not specific to
%   any particular experiment.

% OUTPUT
% DForm: struct. Contains information on the data format.

DForm.AllPermittedBlks = {'inferred', 'instructed', ...
    'full_task_lab', 'full_task_scanner', 'inference-only'};
DForm.AllTwoLevelBlks = {'inferred', 'instructed', ...
    'full_task_lab', 'full_task_scanner'};
DForm.AllInferenceBlks = {'inferred', ...
    'full_task_lab', 'full_task_scanner', 'inference-only'};
DForm.FullTaskInferBlks = {'inferred', ...
    'full_task_lab', 'full_task_scanner'};

if ~isempty(DSet)
    if isfield(DSet, 'P')
        Data = DSet.P(1).Data;
    else
        Data = DSet;
    end
    
    if any(isfield(Data, {'RuleIsHorizToLeftForTrial', ...
            'RuleIsHorizToLeftForCue'}))
        DForm.IsRuleAForTrial = 'RuleIsHorizToLeftForTrial';
        DForm.IsRuleAForCue = 'RuleIsHorizToLeftForCue';
        DForm.UsedRuleA = 'RuleActuallyUsedIsHorizToLeft';
        DForm.NextUsedRuleA = 'UpcomingRuleActuallyUsedIsHorizToLeft';
        DForm.IsStimA = 'StimIsHoriz';
        DForm.NextIsStimA = 'UpcomingStimIsHoriz';
        DForm.IsRespA = 'RespIsLeft';
        DForm.NextIsRespA = 'UpcomingRespIsLeft';
        DForm.HasInfOnly = false;

        DForm.BlockTypes = {'inferred', 'instructed'};
        DForm.BlkTypeAssocCatForCue = {'RuleIsHorizToLeftForCue', ...
            'RuleIsHorizToLeftForCue'};
        DForm.BlkAssocUpcomingRuleOrDistReported = {...
            'UpcomingRuleActuallyUsedIsHorizToLeft', ...
            'UpcomingRuleActuallyUsedIsHorizToLeft'};

    elseif any(isfield(Data, {'RuleIsHouseToLeftForTrial', ...
            'RuleIsHouseToLeftForCue'}))
        DForm.IsRuleAForTrial = 'RuleIsHouseToLeftForTrial';
        DForm.IsRuleAForCue = 'RuleIsHouseToLeftForCue';
        DForm.UsedRuleA = 'RuleActuallyUsedIsHouseToLeft';
        DForm.NextUsedRuleA = 'UpcomingRuleActuallyUsedIsHouseToLeft';
        DForm.IsStimA = 'StimIsHouse';
        DForm.NextIsStimA = 'UpcomingStimIsHouse';
        DForm.IsRespA = 'RespIsLeftOrUp';
        DForm.NextIsRespA = 'UpcomingRespIsLeftOrUp';
        DForm.HasInfOnly = true;

        DForm.BlockTypes = {'full_task_lab', ...
            'full_task_scanner', ...
            'inference-only'};
        DForm.BlkTypeAssocCatForCue = {'RuleIsHouseToLeftForCue', ...
            'RuleIsHouseToLeftForCue', ...
            'DistIsUpperForCue'};
        DForm.BlkAssocUpcomingRuleOrDistReported = {...
            'UpcomingRuleActuallyUsedIsHouseToLeft', ...
            'UpcomingRuleActuallyUsedIsHouseToLeft', ...
            'UpcomingRespIsLeftOrUp'};

    else
        error('Bug')
    end
end
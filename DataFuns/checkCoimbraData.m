function checkCoimbraData(DSet)

DForm = findDataFormat(DSet);

checkDataOrdering(DSet);

% Is this trial data or cue data?
if isfield(DSet.P(1).Data, 'NumCuesInTrial')
    isTrialData = true;
elseif isfield(DSet.P(1).Data, DForm.NextIsRespA)
    isTrialData = false;
else
    error('Bug')
end

for iP = 1 : length(DSet.P)
    ThisData = DSet.P(iP).Data;

    if isTrialData
        assert(isequal(...
            isnan(ThisData.RespIsLeftOrUp), ...
            isnan(ThisData.Acc)))
        isNanAcc = isnan(ThisData.Acc);
        assert(all(ThisData.RtIsValid(isNanAcc) == 0))
    else
        assert(isequal(...
            isnan(ThisData.UpcomingRespIsLeftOrUp), ...
            isnan(ThisData.UpcomingAcc)))
        isNanAcc = isnan(ThisData.UpcomingAcc);
        assert(all(ThisData.UpcomingRtIsValid(isNanAcc) == 0))
    end
    
    for iE = 1 : length(ThisData.BlockNum)
        if any(strcmp(ThisData.BlockType(iE), ...
                {'full_task_lab', 'full_task_scanner'}))
            
            if isTrialData
                assert(isequal(ThisData.NumCuesInTrial(iE), ...
                    length(ThisData.RuleIsHouseToLeftForCue{iE})))
                assert(ThisData.RuleIsHouseToLeftForTrial(iE) == ...
                    ThisData.RuleIsHouseToLeftForCue{iE}(end))
                assert(isnan(ThisData.DistIsUpperForCue{iE}))
                assert(~isnan(ThisData.StimIsHouse(iE)))
            else
                % Must be cue data
                assert(~isnan(ThisData.RuleIsHouseToLeftForCue(iE)))
                assert(isnan(ThisData.DistIsUpperForCue(iE)))
                assert(~isnan(ThisData.UpcomingStimIsHouse(iE)))
            end
            
            assert(isnan(ThisData.DistIsUpperForTrial(iE)))
            
            assert(~isnan(ThisData.RuleIsHouseToLeftForTrial(iE)))
            
        elseif strcmp(ThisData.BlockType(iE), 'inference-only')
            
            if isTrialData
                assert(isequal(ThisData.NumCuesInTrial(iE), ...
                    length(ThisData.DistIsUpperForCue{iE})))
                assert(ThisData.DistIsUpperForTrial(iE) == ...
                    ThisData.DistIsUpperForCue{iE}(end))
                assert(isnan(ThisData.RuleIsHouseToLeftForCue{iE}))
                assert(isnan(ThisData.StimIsHouse(iE)))
            else
                % Must be cue data
                assert(~isnan(ThisData.DistIsUpperForCue(iE)))
                assert(isnan(ThisData.RuleIsHouseToLeftForCue(iE)))
                assert(isnan(ThisData.UpcomingStimIsHouse(iE)))
            end
            
            assert(~isnan(ThisData.DistIsUpperForTrial(iE)))
            assert(isnan(ThisData.RuleIsHouseToLeftForTrial(iE)))
        else
            error('Unrecognised block type')
        end
    end
    
    % Check cues are not nan
    if isTrialData
        for iT = 1 : length(ThisData.TrialNum)
            if any(isnan(ThisData.CueLoc{iT}))
                error('Nan cue location')
            end
        end
    else
        assert(~any(isnan(ThisData.CueLoc)))
    end
end




    
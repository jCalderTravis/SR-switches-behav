function CueDSet = convertDSet(TrlDSet)
% We use different representations of the data depending on what we are
% focussing on. TrlDSet stores data at the level of trials, while CueDSet
% stores data at the level of cues. This function converts from the a
% trial-based represetnation to a cue-based represpentation.

% HISTORY
% 2021, JCT
% 22.02.2023 Read through, including called functions
% 10.05.2023 Updated for Coimbra data

DForm = findDataFormat(TrlDSet);

% Add some extra info
TrlDSet = computeTrialDerivs(TrlDSet);

for iP = 1 : length(TrlDSet.P)
    TrlData = TrlDSet.P(iP).Data;
    
    % How many cues were there in total, so we can initialise
    totalCues = sum(cellfun(@length, TrlDSet.P(iP).Data.CueLoc));
    CueData = [];
    CueData.TrialNum = nan(totalCues, 1);
    CueData.(DForm.IsRuleAForTrial) = nan(totalCues, 1);
    CueData.(DForm.IsRuleAForCue) = nan(totalCues, 1);
    CueData.CueLoc = nan(totalCues, 1);
    CueData.BlockNum = nan(totalCues, 1);
    CueData.SessionNum = nan(totalCues, 1);
    CueData.BlockType = cell(totalCues, 1);
    CueData.(DForm.NextIsStimA) = nan(totalCues, 1); % Refers to the stimulus
    % presented after all the cues
    CueData.(DForm.NextIsRespA) = nan(totalCues, 1); % This and next couple refer
    % to the response after all the cues
    CueData.UpcomingRtIsValid = nan(totalCues, 1);
    CueData.UpcomingAcc = nan(totalCues, 1);
    CueData.(DForm.NextUsedRuleA) = nan(totalCues, 1);
    CueData.WasIceSess = nan(totalCues, 1);
    if DForm.HasInfOnly
        CueData.DistIsUpperForTrial = nan(totalCues, 1);
        CueData.DistIsUpperForCue = nan(totalCues, 1);
    end
    
    % Loop through each trial, and within that loop through each cue. For every
    % cue extract various bits of information associated with that cue (no
    % pun intended).
    totCueCount = 1;
    for iT = 1 : length(TrlData.TrialNum)
        trialCues = TrlData.CueLoc{iT};
        cueByCueActiveRule = TrlData.(DForm.IsRuleAForCue){iT};
        if DForm.HasInfOnly
            cueByCueActiveDist = TrlData.DistIsUpperForCue{iT};
        end
        blockType = TrlData.BlockType{iT};
        
        if strcmp(blockType, 'inference-only')
            assert(cueByCueActiveDist(end) ...
                == TrlData.DistIsUpperForTrial(iT))
        else
            assert(cueByCueActiveRule(end) ...
                == TrlData.(DForm.IsRuleAForTrial)(iT))
        end
        
        for iC = 1 : length(trialCues)
            CueData.TrialNum(totCueCount) = TrlData.TrialNum(iT);
            CueData.BlockNum(totCueCount) = TrlData.BlockNum(iT);
            CueData.SessionNum(totCueCount) = TrlData.SessionNum(iT);
            CueData.BlockType{totCueCount} = blockType;
            
            if strcmp(blockType, 'inference-only')
                assert(isnan(TrlData.(DForm.IsStimA)(iT)));
                assert(isnan(TrlData.(DForm.IsRuleAForTrial)(iT)));
                assert(isnan(TrlData.(DForm.UsedRuleA)(iT)));
             
                assert(isnan(cueByCueActiveRule))
                CueData.(DForm.IsRuleAForCue)(totCueCount) = nan;
                
                if DForm.HasInfOnly
                    CueData.DistIsUpperForCue(totCueCount) ...
                        = cueByCueActiveDist(iC);
                end
            else
                assert(any(strcmp(blockType, ...
                    {'full_task_lab', 'full_task_scanner', ...
                    'inferred', 'instructed'})))
                
                CueData.(DForm.IsRuleAForCue)(totCueCount) ...
                    = cueByCueActiveRule(iC);
                
                if DForm.HasInfOnly
                    assert(isnan(TrlData.DistIsUpperForTrial(iT)))
                    assert(isnan(cueByCueActiveDist))
                    CueData.DistIsUpperForCue(totCueCount) = nan;
                end
            end
            
            if DForm.HasInfOnly
                CueData.DistIsUpperForTrial(totCueCount) ...
                    = TrlData.DistIsUpperForTrial(iT);
            end
            CueData.(DForm.IsRuleAForTrial)(totCueCount) ...
                = TrlData.(DForm.IsRuleAForTrial)(iT);
            CueData.(DForm.NextIsStimA)(totCueCount) = ...
                TrlData.(DForm.IsStimA)(iT);
            CueData.(DForm.NextIsRespA)(totCueCount) = ...
                TrlData.(DForm.IsRespA)(iT);
            CueData.UpcomingRtIsValid(totCueCount) = ...
                TrlData.RtIsValid(iT);
            CueData.UpcomingAcc(totCueCount) = TrlData.Acc(iT);
            CueData.CueLoc(totCueCount) = trialCues(iC);
            CueData.(DForm.NextUsedRuleA)(totCueCount) ...
                = TrlData.(DForm.UsedRuleA)(iT);
            CueData.WasIceSess(totCueCount) = TrlData.WasIceSess(iT);
            
            totCueCount = totCueCount +1;
        end
    end
    
    assert((totCueCount-1) == totalCues)
    assert(length(CueData.CueLoc) == totalCues)
    assert(~any(isnan(CueData.CueLoc)))
    
    % Put into standard format
    CueDSet.P(iP).Data = CueData;
    CueDSet.P(iP).Spec = TrlDSet.P(iP).Spec;
end

CueDSet.Spec = TrlDSet.Spec;


function TrlDSet = computeTrialDerivs(TrlDSet)
% Takes the structure which stores information at the level of the trials,
% TrlDSet, and computes various additional quantitiles, and adds these as
% extra fields. 

% HISTORY
% 2021, JCT
% 22.02.2023 Read through, including called functions
% 10.05.2023 Updated for Coimbra data

DForm = findDataFormat(TrlDSet);

%% Compute the rule actually used by the participant

for iP = 1 : length(TrlDSet.P)
    ThisData = TrlDSet.P(iP).Data;
    usedRuleA = nan(length(ThisData.TrialNum), 1);
    assert(all(ismember(ThisData.BlockType, DForm.AllPermittedBlks)))
    evalRows = ~strcmp('inference-only', ThisData.BlockType);
    assert(isequal(size(evalRows), size(ThisData.TrialNum)))
    
    nanAcc = isnan(ThisData.Acc);
    assert(isequal(unique(ThisData.Acc(~nanAcc)), [0, 1]'))
    
    for iT = 1 : length(ThisData.TrialNum)
        if ~evalRows(iT)
            continue 
        end

        assert(ismember(ThisData.(DForm.IsRuleAForTrial)(iT), [0, 1]))
        
        % The rule used by participants matches the true rule if they
        % were correct. If they are incorrect, then they must have used
        % the opposite rule to the true rule
        if isnan(ThisData.Acc(iT))
            usedRuleA(iT) = nan;
            
        elseif ThisData.Acc(iT) == 1
            usedRuleA(iT) ...
                = ThisData.(DForm.IsRuleAForTrial)(iT);
            
        elseif ThisData.Acc(iT) == 0
            
            if ThisData.(DForm.IsRuleAForTrial)(iT) == 1
                swapped = 0;
            elseif ThisData.(DForm.IsRuleAForTrial)(iT) == 0
                swapped = 1;
            else
                error('Unexpected case');
            end
            usedRuleA(iT) = swapped;
        else
            error('Unexpected case')
        end
    end
    
    assert(isequal(size(nanAcc), size(usedRuleA)))
    assert(~any(isnan(usedRuleA((~nanAcc) & evalRows))))
    assert(all(isnan(usedRuleA(nanAcc | (~evalRows)))))
    assert(length(usedRuleA) == length(ThisData.TrialNum))
    
    TrlDSet.P(iP).Data.(DForm.UsedRuleA) = usedRuleA;
end



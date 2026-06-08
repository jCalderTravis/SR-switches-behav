function StackedCueDSet = stackCueDSet(CueDSet)
% Stack a CueData set in a manner that it can be used for making 
% evidence residuals plots. Specifically, each entry in the resulting
% dataset is not a unique cue, but there is an entry for every cue-repsonse
% pair (for cues close enough to the upcoming response) giving the 
% distance between them.

% HISTORY
% 23.05.2023 Updated for Coimbra data

% What is the maximum number of lags prior to each response that we will
% cosnider?
window = 20;
DForm = findDataFormat(CueDSet);

for iP = 1 : length(CueDSet.P)
    TheseCues = CueDSet.P(iP).Data;
    checkDataOrdering(TheseCues);
    
    TheseStacked.CueNumRelativeToResponse = [];
    TheseStacked.CueLocSignedDemeaned = [];
    TheseStacked.RtOfRespIsValid = [];
    TheseStacked.AccOfResp = [];
    TheseStacked.TrialNumOfResp = [];
    TheseStacked.BlockNum = [];
    TheseStacked.SessionNum = [];
    TheseStacked.BlockType = {};
    TheseStacked.WasIceSess = [];
    
    currentTrial = 1;
    allTrialNums = [TheseCues.TrialNum; 0]; % Append a one, so that the end 
    % of the final trial is also recognised, using the approach below
    assert(allTrialNums(1) == currentTrial)
    assert(size(allTrialNums, 2) == 1)
    
    for iC = 1 : length(allTrialNums)
        if allTrialNums(iC) ~= currentTrial
            firstIdx = iC - window;
            firstIdx = max(firstIdx, 1);
            finalIdx = iC - 1;
            
            relToResp = [(firstIdx - iC) : (finalIdx - iC)]';
            theseTrialNums = repmat(TheseCues.TrialNum(finalIdx), ...
                length(relToResp), 1);
            blockNum = TheseCues.BlockNum(firstIdx : finalIdx);
            sessNum = TheseCues.SessionNum(firstIdx : finalIdx);
            blockType = TheseCues.BlockType(firstIdx : finalIdx);
            validRt = repmat(TheseCues.UpcomingRtIsValid(finalIdx), ...
                length(relToResp), 1);
            wasIceSess = TheseCues.WasIceSess(firstIdx : finalIdx);
            upcomingAcc = repmat(TheseCues.UpcomingAcc(finalIdx), ...
                length(relToResp), 1);
            
            % Find the name of the field that, for this block type, tells
            % us the rule used or the distribution reported by the
            % participants
            match = strcmp(DForm.BlockTypes, blockType(end));
            assert(sum(match) == 1)
            upcomingRuleOrDistReported = ...
                DForm.BlkAssocUpcomingRuleOrDistReported{match};
            
            % Sign the cues so that they give evidence in the direction
            % of the choice under consideration
            cueLocSignedDemeaned = ...
                TheseCues.CueLocDemeaned(firstIdx : finalIdx);
            assert(~any(isnan(cueLocSignedDemeaned)))
            upcomingRuleUsed = ...
                TheseCues.(upcomingRuleOrDistReported)(finalIdx);
            if upcomingRuleUsed == 0
                cueLocSignedDemeaned = -cueLocSignedDemeaned;
            elseif upcomingRuleUsed == 1
                % Nothing to do
            elseif isnan(upcomingRuleUsed)
                cueLocSignedDemeaned = nan(size(cueLocSignedDemeaned));
                assert(~validRt(end))
            else
                error('Bug')
            end
            
            % Are all these cues in the same block and session?
            thisBlkSess = [blockNum(end), sessNum(end)];
            allBlkSess = [blockNum, sessNum];
            assert(size(allBlkSess, 2) == 2)
            inBlk = ismember(allBlkSess, thisBlkSess, 'rows');
            assert(isequal(size(inBlk), size(cueLocSignedDemeaned)))
        
            TheseStacked.CueNumRelativeToResponse = ...
                [TheseStacked.CueNumRelativeToResponse; relToResp(inBlk)];
            TheseStacked.CueLocSignedDemeaned = ...
                [TheseStacked.CueLocSignedDemeaned; ...
                    cueLocSignedDemeaned(inBlk)]; 
            TheseStacked.RtOfRespIsValid = ...
                [TheseStacked.RtOfRespIsValid; validRt(inBlk)];
            TheseStacked.AccOfResp = ...
                [TheseStacked.AccOfResp; upcomingAcc(inBlk)];
            TheseStacked.TrialNumOfResp = ...
                [TheseStacked.TrialNumOfResp; theseTrialNums(inBlk)];
            TheseStacked.BlockNum = ...
                [TheseStacked.BlockNum; blockNum(inBlk)];
            TheseStacked.SessionNum = ...
                [TheseStacked.SessionNum; sessNum(inBlk)];
            TheseStacked.BlockType = ...
                [TheseStacked.BlockType; blockType(inBlk)];
            TheseStacked.WasIceSess = ...
                [TheseStacked.WasIceSess; wasIceSess(inBlk)];
            
            currentTrial = allTrialNums(iC);
        end
    end
    assert(currentTrial == allTrialNums(end))
    assert(isequal(...
        unique([TheseCues.SessionNum, TheseCues.BlockNum, ...
            TheseCues.TrialNum], 'rows'), ...
        unique([TheseStacked.SessionNum, TheseStacked.BlockNum, ...
            TheseStacked.TrialNumOfResp], 'rows')))
    
    stackedFields = fieldnames(TheseStacked);
    for iSF = 1 : length(stackedFields)
       assert(isequal(...
           length(TheseStacked.(stackedFields{1})), ...
           length(TheseStacked.(stackedFields{iSF}))))
    end
    
    assert(~any(isnan(TheseStacked.CueLocSignedDemeaned) ...
        & logical(TheseStacked.RtOfRespIsValid)))
    assert(all(TheseStacked.RtOfRespIsValid(...
        isnan(TheseStacked.AccOfResp)) == 0))
    StackedCueDSet.P(iP).Data = TheseStacked;

    StackedCueDSet.P(iP).Spec = CueDSet.P(iP).Spec;
end

StackedCueDSet.Spec = CueDSet.Spec;


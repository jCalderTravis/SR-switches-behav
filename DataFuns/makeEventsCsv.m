function makeEventsCsv(TrlDSet_AbsTime, CueDSet_AbsTime, ...
    TrlDSet_Fitted, pIndex, saveName)
% Save a CSV file containing data on all key events and computational
% variables at these events

% INPUT
% TrlDSet_AbsTime: Standard dataset storing information at the level of
%   individual trials, but where all times are recorded in absolute terms,
%   not relative the onset of each trial.
% CueDSet_AbsTime: Standard dataset storing information at the level of
%   individual cues. Needs to contain info on cue timings. All times must
%   be recorded in absolute terms, not relative the onset of each trial.
%   Must match TrlDSet_AbsTime in terms of participants and their ordering.
% TrlData_Fitted: Standard dataset storing information at the level of
%   individual trials, for which a model has been fitted. The fitted
%   parameters for the 1st model will be used to compute computational
%   variables, assuming TrlData_Fitted and TrlDSet_AbsTime contain identical
%   participants and participant ordering.
% pIndex: Only makes a CSV for 1 participant. Which participant? Provide the
%   number that represents the position in TrlDSet_AbsTime.P, not the
%   participant's ID number.
% saveName: Full filename for where to save the CSV file. 

% HISTORY
% 2021, JCT
% 27.02.2023 Read through, including called functions

assert(length(TrlDSet_AbsTime.P) == length(CueDSet_AbsTime.P))
assert(length(TrlDSet_AbsTime.P) == length(TrlDSet_Fitted.P))

TrlDSet_AbsTime = computeTrialDerivs(TrlDSet_AbsTime);

relevantModel = 1;
models = mT_findAppliedModels(TrlDSet_Fitted);
assert(strcmp(models{relevantModel}, 'miscal-h-b-normative'))
checkPreregParamLims(TrlDSet_Fitted, relevantModel)
fittedParams = mT_findFittedParams(TrlDSet_Fitted, relevantModel);

% We will assume the data are in order
ThisData = TrlDSet_AbsTime.P(pIndex).Data;
checkDataOrdering(ThisData)

% We assume TrlData_Fitted and TrlDSet_AbsTime contain identical
% participants and participant ordering
assert(isequal(TrlDSet_AbsTime.P(pIndex).Data.StimIsHoriz, ...
    TrlDSet_Fitted.P(pIndex).Data.StimIsHoriz))

ptpntID = TrlDSet_AbsTime.P(pIndex).Spec.PtpntID;
ThisCueData = CueDSet_AbsTime.P(pIndex).Data;
checkDataOrdering(ThisCueData)

ThisKeyVars = computeKeyModelVariables(fittedParams{pIndex}, ThisData);
ThisCueData = mergeInKeyVars(ThisCueData, ThisKeyVars);

% Merge ThisKeyVars into the trial-based data as well
assert(isequal(ThisData.CueLoc, ThisKeyVars.CueLoc))
assert(length(ThisData.CueLoc) == length(ThisKeyVars.TrialEndLPR))
ThisData.TrialEndLPR = ThisKeyVars.TrialEndLPR;
assert(length(ThisData.CueLoc) == length(ThisKeyVars.CueLLR))
ThisData.CueLLR = ThisKeyVars.CueLLR;
ThisData.AfterCueLPR = ThisKeyVars.AfterCueLPR;

% Loop through all trials storing the info that we want
DataForCsv = struct();
fields = {'Event', 'PtpntID', 'SessionNum', 'BlockNum', 'BlockType', ...
    'TrialNum', 'WasIceSess', ...
    'AbsoluteTime', 'RelToFirstTrialTime', 'RelToBlkSyncTrigTime', ...
    'StimIsHoriz', 'RespIsLeft', 'RtIsValid', ...
    'RuleIsHorizToLeftForCue', ...
    'RuleIsHorizToLeftForTrial', 'RuleActuallyUsedIsHorizToLeft', ...
    'TwoPrevCueLoc', 'PrevCueLoc', 'CueLoc', ... 
    'PreCueLPR', 'AfterCueLPR', ...
    'TwoPrevCueLLR', 'PrevCueLLR', 'CueLLR', ...
    'AfterCueCPP', 'PreCueUncert', ...
    'TwoPrevPreCueLPriorR', 'PrevPreCueLPriorR', ...
    'PreCueLPriorR', 'AfterCueLPriorR', ...
    'Acc', ...
    'NonCueLPR', 'NonCuePrePrevCueLPR'};
for iF = 1 : length(fields)
    DataForCsv.(fields{iF}) = {};
end
thisRow = 1;


detectedBlocks = 0;
for iT = 1 : length(ThisData.TrialNum)
    if ThisData.TrialNum(iT) == 1
        baseTime = ThisData.FixFlipTime(iT);
        detectedBlocks = detectedBlocks +1;
    end
    
    % FixationOnset
    [DataForCsv, thisRow] = addFixOnset(DataForCsv, ThisData, baseTime, ...
        ptpntID, iT, fields, thisRow);
    
    % CueOnsets
    numTrialCues = length(ThisData.CueLoc{iT});
    matchingCues = (ThisCueData.TrialNum == ThisData.TrialNum(iT)) ...
        & (ThisCueData.BlockNum == ThisData.BlockNum(iT)) ...
        & (ThisCueData.SessionNum == ThisData.SessionNum(iT));
    assert(sum(matchingCues) == numTrialCues)
    
    matchPos_inAll = find(matchingCues);
    for iC_inTrial = 1 : length(matchPos_inAll)
        thisMatchPos_inAll = matchPos_inAll(iC_inTrial);
        
        [DataForCsv, thisRow] = addCue(DataForCsv, thisMatchPos_inAll, ...
            baseTime, ptpntID, ThisData, iT, fields, thisRow, ...
            ThisKeyVars, ThisCueData, iC_inTrial);
    end
    
    % StimulusOnset
    [DataForCsv, thisRow] = addStimulus(DataForCsv, ThisData, ...
        baseTime, ptpntID, iT, fields, thisRow);
    
    % Response
    [DataForCsv, thisRow] = addResponse(DataForCsv, ThisData, iT, ...
        baseTime, ptpntID, fields, thisRow);
end

combos = [ThisData.SessionNum, ThisData.BlockNum];
combos = unique(combos, 'rows');
numBlocks = size(combos, 1);
assert(numBlocks == detectedBlocks)

allFields = fieldnames(DataForCsv);
for iF = 1 : length(allFields)
    DataForCsv.(allFields{iF}) = DataForCsv.(allFields{iF})';
end

checkTimings(DataForCsv)
saveStructAsCsv(DataForCsv, saveName)

end


function checkTimings(DataForCsv)

% Is data for RelToBlkSyncTrigTime entirely missing? (As in the pilot data)
relTimeAsStr = cellfun(@num2str, DataForCsv.RelToBlkSyncTrigTime, ...
    'UniformOutput', false);
if all(strcmp(unique(relTimeAsStr), ''))
    blkSyncMissing = true;
else
    blkSyncMissing = false;
end

timeFields = {'AbsoluteTime', 'RelToFirstTrialTime', ...
    'RelToBlkSyncTrigTime'};
if blkSyncMissing
    timeFields(strcmp(timeFields, 'RelToBlkSyncTrigTime')) = [];
end
    

for iF = 1 : length(timeFields)
    isNanArray = cellfun(@isnan, DataForCsv.(timeFields{iF}));
    assert(~any(isNanArray(:)))
    
    isPos = cellfun(@(el) el>=0, DataForCsv.(timeFields{iF}));
    if ~all(isPos(:))
        error('Would expect all these time measurements to be positive.')
    end
end

wasChecked = false(length(DataForCsv.PtpntID), 1);
blockIdentifiers = [cell2mat(DataForCsv.PtpntID), ...
    cell2mat(DataForCsv.SessionNum), ...
    cell2mat(DataForCsv.BlockNum)];
assert(size(blockIdentifiers, 2) == 3)
uniqueBlockIdentifiers = unique(blockIdentifiers, 'rows');

for iB = 1 : size(uniqueBlockIdentifiers, 1)
    inBlock = ismember(blockIdentifiers, ...
        uniqueBlockIdentifiers(iB, :), 'rows');
    
    timeDiffs = diff(cell2mat(DataForCsv.AbsoluteTime(inBlock)));
    assert(isequal(timeDiffs, ...
        diff(cell2mat(DataForCsv.RelToFirstTrialTime(inBlock)))))
    if ~blkSyncMissing
        assert(isequal(timeDiffs, ...
            diff(cell2mat(DataForCsv.RelToBlkSyncTrigTime(inBlock)))))
    end
    
    assert(~any(wasChecked(inBlock)))
    wasChecked(inBlock) = true;
end
assert(all(wasChecked))

end


function DataForCsv = setUpNewRow(DataForCsv, eventName, eventTime, ...
    baseTime, ptpntID, ThisData, iTrial, fields, thisRow)
% Add a new row, and fill in some basic info for this new row

assert(length(intersect(fields, fieldnames(DataForCsv))) ...
    == length(fields))
assert(length(intersect(fields, fieldnames(DataForCsv))) ...
    == length(fieldnames(DataForCsv)))

% Add a blank row of data to the data for CSV conversion
for iF = 1 : length(fields)
    DataForCsv.(fields{iF}){end+1} = '';
end

% Check new row
allFields = fieldnames(DataForCsv);
checkFields(allFields, DataForCsv, thisRow, true)

DataForCsv.Event{end} = eventName;
DataForCsv.PtpntID{end} = ptpntID;
DataForCsv.SessionNum{end} = ThisData.SessionNum(iTrial);
DataForCsv.BlockNum{end} = ThisData.BlockNum(iTrial);
DataForCsv.BlockType{end} = ThisData.BlockType{iTrial};
DataForCsv.TrialNum{end} = ThisData.TrialNum(iTrial);
DataForCsv.AbsoluteTime{end} = eventTime;
DataForCsv.RelToFirstTrialTime{end} = eventTime - baseTime;
if isfield(ThisData, 'BlkSyncTrigTime')
    DataForCsv.RelToBlkSyncTrigTime{end} = ...
        eventTime - ThisData.BlkSyncTrigTime(iTrial);
end

% Check that all fields have the same number of entries
allFields = fieldnames(DataForCsv);
checkFields(allFields, DataForCsv, thisRow, false)

end


function [DataForCsv, thisRow] = finaliseRow(DataForCsv, thisRow, ...
    ExtraRowData)
% Add any extra data to the row and increment the row counter ready for the
% next row.

existFields = fieldnames(DataForCsv);
extraFields = fieldnames(ExtraRowData);

assert(length(intersect(extraFields, existFields)) ...
    == length(extraFields))
checkFields(extraFields, DataForCsv, thisRow, true)

for iE = 1 : length(extraFields)
    DataForCsv.(extraFields{iE}){end} = ExtraRowData.(extraFields{iE});
end

allFields = fieldnames(DataForCsv);
checkFields(allFields, DataForCsv, thisRow, false)

thisRow = thisRow +1;
end


function checkFields(fieldsToCheck, DataForCsv, thisRow, checkEmpty)

for iF = 1 : length(fieldsToCheck)
    if checkEmpty
        assert(isequal(DataForCsv.(fieldsToCheck{iF}){end}, ''))
    end
    assert(length(DataForCsv.(fieldsToCheck{iF})) == thisRow)
end

end


function [DataForCsv, thisRow] = addFixOnset(DataForCsv, ThisData, ...
    baseTime, ptpntID, iT, fields, thisRow)

DataForCsv = setUpNewRow(DataForCsv, 'FixationOnset', ...
    ThisData.FixFlipTime(iT), baseTime, ...
    ptpntID, ThisData, iT, fields, thisRow);

[DataForCsv, thisRow] = finaliseRow(DataForCsv, thisRow, struct());

end


function [DataForCsv, thisRow] = addCue(DataForCsv, thisMatchPos_inAll, ...
    baseTime, ptpntID, ThisData, iT, fields, thisRow, ThisKeyVars, ...
    ThisCueData, iC_inTrial)

DataForCsv = setUpNewRow(DataForCsv, 'CueOnset', ...
    ThisCueData.CueFlipTime(thisMatchPos_inAll), baseTime, ...
    ptpntID, ThisData, iT, fields, thisRow);

ExtraData.RuleIsHorizToLeftForCue = ...
    ThisCueData.RuleIsHorizToLeftForCue(thisMatchPos_inAll);
ExtraData.CueLoc = ThisCueData.CueLoc(thisMatchPos_inAll);

nextIdx_inAll = findNearCueIndex(ThisCueData, thisMatchPos_inAll, 1);
prevIdx_inAll = findNearCueIndex(ThisCueData, thisMatchPos_inAll, -1);
twoPrevIdx_inAll = findNearCueIndex(ThisCueData, thisMatchPos_inAll, -2);

if ~isnan(prevIdx_inAll)
    ExtraData.PrevCueLoc = ThisCueData.CueLoc(prevIdx_inAll);
end
if ~isnan(twoPrevIdx_inAll)
    ExtraData.TwoPrevCueLoc = ThisCueData.CueLoc(twoPrevIdx_inAll);
end

if strcmp(ThisData.BlockType(iT), 'inferred')
    
    ExtraData.AfterCueCPP = ...
        ThisKeyVars.AfterCueCPP{iT}(iC_inTrial);
    ExtraData.PreCueUncert = ...
        ThisKeyVars.PreCueUncert{iT}(iC_inTrial);

    ExtraData.CueLLR = ThisCueData.CueLLR(thisMatchPos_inAll);
    ExtraData.AfterCueLPR = ThisCueData.AfterCueLPR(thisMatchPos_inAll);
    ExtraData.PreCueLPriorR = ...
        ThisCueData.PreCueLPriorR(thisMatchPos_inAll);

    if ~isnan(nextIdx_inAll)
        ExtraData.AfterCueLPriorR = ...
            ThisCueData.PreCueLPriorR(nextIdx_inAll);
    end

    if ~isnan(prevIdx_inAll)
        ExtraData.PrevCueLLR = ThisCueData.CueLLR(prevIdx_inAll);
        ExtraData.PreCueLPR = ThisCueData.AfterCueLPR(prevIdx_inAll);
        ExtraData.PrevPreCueLPriorR = ...
            ThisCueData.PreCueLPriorR(prevIdx_inAll);
    end

    if ~isnan(twoPrevIdx_inAll)
        ExtraData.TwoPrevCueLLR = ThisCueData.CueLLR(twoPrevIdx_inAll);
        ExtraData.TwoPrevPreCueLPriorR = ...
            ThisCueData.PreCueLPriorR(twoPrevIdx_inAll);
    end
end

% Checks for alignment
cueLocFromTrlData = ThisData.CueLoc{iT}(iC_inTrial);
cueLocFromCueData = ThisCueData.CueLoc(thisMatchPos_inAll);
cueLocFromKeyVars = ThisKeyVars.CueLoc{iT}(iC_inTrial);
assert(cueLocFromTrlData == cueLocFromKeyVars)
assert(cueLocFromTrlData == cueLocFromCueData)

[DataForCsv, thisRow] = finaliseRow(DataForCsv, thisRow, ExtraData);

end


function [DataForCsv, thisRow] = addStimulus(DataForCsv, ThisData, ...
    baseTime, ptpntID, iT, fields, thisRow)

DataForCsv = setUpNewRow(DataForCsv, 'StimulusOnset', ...
    ThisData.StimFlipTime_1(iT), baseTime, ...
    ptpntID, ThisData, iT, fields, thisRow);

ExtraData.RespIsLeft = ThisData.RespIsLeft(iT);
ExtraData.StimIsHoriz = ThisData.StimIsHoriz(iT);
ExtraData.RuleIsHorizToLeftForTrial = ...
    ThisData.RuleIsHorizToLeftForTrial(iT);
ExtraData.RuleActuallyUsedIsHorizToLeft = ...
    ThisData.RuleActuallyUsedIsHorizToLeft(iT);
ExtraData.RtIsValid = ThisData.RtIsValid(iT);
ExtraData.WasIceSess = ThisData.WasIceSess(iT);
ExtraData.Acc = ThisData.Acc(iT);
ExtraData.PrevCueLoc = ThisData.CueLoc{iT}(end);

if strcmp(ThisData.BlockType(iT), 'inferred')
    ExtraData.PrevCueLLR = ThisData.CueLLR{iT}(end);
    ExtraData.TwoPrevCueLLR = ThisData.CueLLR{iT}(end-1);
    assert(~isnan(ExtraData.TwoPrevCueLLR))
    ExtraData.NonCueLPR = ThisData.TrialEndLPR(iT);

    assert(ThisData.AfterCueLPR{iT}(end) == ThisData.TrialEndLPR(iT))
    ExtraData.NonCuePrePrevCueLPR = ThisData.AfterCueLPR{iT}(end-1);
    assert(~isnan(ExtraData.NonCuePrePrevCueLPR))
end

[DataForCsv, thisRow] = finaliseRow(DataForCsv, thisRow, ExtraData);

end


function [DataForCsv, thisRow] = addResponse(DataForCsv, ThisData, iT, ...
    baseTime, ptpntID, fields, thisRow)

DataForCsv = setUpNewRow(DataForCsv, 'Response', ...
    ThisData.RtAbs(iT), baseTime, ...
    ptpntID, ThisData, iT, fields, thisRow);

ExtraData.RespIsLeft = ThisData.RespIsLeft(iT);
ExtraData.StimIsHoriz = ThisData.StimIsHoriz(iT);
ExtraData.RuleIsHorizToLeftForTrial = ...
    ThisData.RuleIsHorizToLeftForTrial(iT);
ExtraData.RuleActuallyUsedIsHorizToLeft = ...
    ThisData.RuleActuallyUsedIsHorizToLeft(iT);
ExtraData.RtIsValid = ThisData.RtIsValid(iT);
ExtraData.WasIceSess = ThisData.WasIceSess(iT);
ExtraData.Acc = ThisData.Acc(iT);
ExtraData.PrevCueLoc = ThisData.CueLoc{iT}(end);

if strcmp(ThisData.BlockType(iT), 'inferred')
    ExtraData.PrevCueLLR = ThisData.CueLLR{iT}(end);
    ExtraData.TwoPrevCueLLR = ThisData.CueLLR{iT}(end-1);
    assert(~isnan(ExtraData.TwoPrevCueLLR))
    ExtraData.NonCueLPR = ThisData.TrialEndLPR(iT);

    assert(ThisData.AfterCueLPR{iT}(end) == ThisData.TrialEndLPR(iT))
    ExtraData.NonCuePrePrevCueLPR = ThisData.AfterCueLPR{iT}(end-1);
    assert(~isnan(ExtraData.NonCuePrePrevCueLPR))
end

[DataForCsv, thisRow] = finaliseRow(DataForCsv, thisRow, ExtraData);

end


function newIdx = findNearCueIndex(CueData, currIndex, lags)
% Find the index of previous or subsequent cues in the CueDSet. Returns 
% nan if the requested cue is from a different block.

% INPUT
% CueData: The struct CueDset.P(iP).Data for some iP, where CueDSet is 
%   data in standard format stored at the level of cues.
% currIndex: scalar. The index in CueDSet of the current cue.
% lagsBack: scalar. At which lag to look? -1 means look at the 
%   immediately previous cue, -2 means one further back, and so on.
%   Similarly, 1 means the next cue, 2 means the cue after that.

assert(length(currIndex) == 1)
newIdx = currIndex + lags;

if (newIdx <= 0) || (newIdx > length(CueData.BlockNum))
    newIdx = nan;
    return
end

bkMatch = CueData.BlockNum(currIndex) == CueData.BlockNum(newIdx);
seMatch = CueData.SessionNum(currIndex) == CueData.SessionNum(newIdx);

if ~(bkMatch && seMatch)
    newIdx = nan;
    return
end

end




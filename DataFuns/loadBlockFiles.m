function [AllTrlData, AllCueData, allBlockNums, allSessNums] = ...
    loadBlockFiles(relFiles, IceStructure, relativeTimes, skipForSim, ...
    ptpntID)
% Load the files that contain data on individual blocks

% INPUT
% relFiles: Struct array of relevant files, in the same format as produced
%   by MATLABs dir function
% IceStructure: struct. See comments for loadOnePtpntData
% relativeTimes: boolean. See comments for loadOnePtpntData
% skipForSim: boolean. See comments for loadOnePtpntData

% HISTORY
% 2020-2021, JCT
% 07.02.2023 Read through, including called functions

AllTrlData = cell(length(relFiles), 1);
AllCueData = cell(length(relFiles), 1);
allBlockNums = nan(length(relFiles), 1);
allSessNums = nan(length(relFiles), 1);

for iF = 1 : length(relFiles)
    
    Loaded = load([relFiles(iF).folder '/' relFiles(iF).name]);
    if isfield(Loaded, 'BlockData')
        BlockData = Loaded.BlockData;
    else
        BlockData = struct();
    end
    TrialData = Loaded.TrialData;
    CueData = Loaded.CueData;
    
    % Rename a field to avoid confusion later. Renaming is not required for
    % more recently collected datasets.
    if isfield(CueData, 'RuleIsHorizToLeft')
        assert(~isfield(CueData, 'RuleIsHorizToLeft_CueByCue'))
        assert(~isfield(CueData, 'RuleIsHorizToLeftForCue'))
        
        CueData.RuleIsHorizToLeftForCue = CueData.RuleIsHorizToLeft;
        CueData = rmfield(CueData, 'RuleIsHorizToLeft');
    end
    
    assert(isfield(CueData, 'RuleIsHorizToLeftForCue'))
    assert(~isfield(CueData, 'RuleIsHorizToLeft_CueByCue'))
    assert(~isfield(CueData, 'RuleIsHorizToLeft'))
    
    % Rename a field that appears in older datasets
    if isfield(TrialData, 'RuleIsHorizToLeft')
        assert(~isfield(TrialData, 'RuleIsHorizToLeftForTrial'))
        
        TrialData.RuleIsHorizToLeftForTrial = TrialData.RuleIsHorizToLeft;
        TrialData = rmfield(TrialData, 'RuleIsHorizToLeft');
    end
    
    assert(isfield(TrialData, 'RuleIsHorizToLeftForTrial'))
    assert(~isfield(TrialData, 'RuleIsHorizToLeft'))
    
    % We want RespIsLeft as a logical not as a double
    if skipForSim
        assert(all(isnan(TrialData.RespIsLeft)))
    else
        uniqueVals = unique(TrialData.RespIsLeft);
        assert(...
            isequal(uniqueVals, [0, 1]') || ...
            all(uniqueVals == 0) || ...
            all(uniqueVals == 1) ...
            )
        TrialData.RespIsLeft = logical(TrialData.RespIsLeft);
    end
    
    testLoadedData(TrialData, CueData, skipForSim)
    
    % We may want all times relative to fixation cross flip
    CueDataAbsolute = CueData;
    if relativeTimes && (~skipForSim)
        [TrialData, CueData] = computeRelativeTimes(TrialData, CueData);
    end
    
    % Work out if responses were given at valid times (i.e. after the cue
    % indicating a response could be given)
    if ~skipForSim
        relRtField = findRelevantRtField(TrialData);
        rtRelRespWindow = TrialData.(relRtField) ...
            - TrialData.FixRotateTimeRequested;
        rtIsValid = rtRelRespWindow > 0;
        
        if isfield(TrialData, 'RtIsValid')
            if isequal(rtIsValid, TrialData.RtIsValid)
                % All good
            else
                error('Would expect these to give the same result.')
            end
        else
            TrialData.RtIsValid = rtIsValid;
        end
    elseif skipForSim
        % skipTimes is a flag for when have simulated data with no timing
        % information, so mark all trials as valid
        assert(isequal(size(TrialData.RtIsValid), ...
            size(TrialData.RespIsLeft)))
        assert(all(isnan(TrialData.RtIsValid)))
        TrialData.RtIsValid = true(size(TrialData.RespIsLeft));
    end
    
    % We want some information on the cues in the trial data structure.
    % Collect that information.
    TrialData.CueLoc = cell(length(TrialData.TrialNum), 1);
    TrialData.RuleIsHorizToLeftForCue = cell(...
        length(TrialData.TrialNum), 1);
    
    for iT = 1 : length(TrialData.TrialNum)
        assert(TrialData.TrialNum(iT) == iT)
        relCues = CueData.TrialNum == iT;
        TrialData.CueLoc{iT} = CueData.CueLoc(relCues);
        TrialData.RuleIsHorizToLeftForCue{iT} ...
            = CueData.RuleIsHorizToLeftForCue(relCues);
    end
    
    % Here we have assumed cues are stored in the order they were
    % presented. Check this
    if ~skipForSim
        assert(all(diff(CueDataAbsolute.CueRequestedTime)>0))
    end
    
    % We want info on block num and session num in the cue data structure
    blockNum = unique(TrialData.BlockNum);
    blockType = unique(TrialData.BlockType);
    sessionNum = unique(TrialData.SessionNum);
    if ~all(size(blockNum) == [1, 1]); error('Bug'); end
    if ~all(size(blockType) == [1, 1]); error('Bug'); end
    if ~all(size(sessionNum) == [1, 1]); error('Bug'); end
    CueData.BlockNum = repmat(blockNum, size(CueData.CueID));
    CueData.BlockType = repmat(blockType, size(CueData.CueID));
    CueData.SessionNum = repmat(sessionNum, size(CueData.CueID));
    
    % Add info on whether ice was used
    relEntry = (IceStructure.PtpntID == ptpntID) ...
        & (IceStructure.Session == sessionNum);
    assert(sum(relEntry) == 1)
    iceUsed = IceStructure.IceUsed(relEntry);
    TrialData.WasIceSess = repmat(iceUsed, size(TrialData.BlockNum));
    
    % Add info on block sync trigger timing
    if isfield(BlockData, 'StartTime') && (~relativeTimes)
        blkSyncTrigTime = BlockData.StartTime;
        
        TrialData = addBlkSyncTrigInfo(TrialData, blkSyncTrigTime);
        CueData = addBlkSyncTrigInfo(CueData, blkSyncTrigTime);
    end
    
    AllTrlData{iF} = TrialData;
    AllCueData{iF} = CueData;
    allBlockNums(iF) = blockNum;
    allSessNums(iF) = sessionNum;
end

blockSessCombos = nan(length(allBlockNums), 2);
blockSessCombos(:, 1) = allBlockNums;
blockSessCombos(:, 2) = allSessNums;
uniqueCombos = unique(blockSessCombos, 'rows');
if size(blockSessCombos, 1) ~= size(uniqueCombos, 1)
    error(['Data directories may contain duplicated data for ', ...
        'the same block.'])
end

assert(~any(isnan(allBlockNums(:))))
assert(~any(isnan(allSessNums(:))))

assert(length(AllCueData) == length(relFiles))
assert(length(AllTrlData) == length(relFiles))
assert(length(allBlockNums) == length(relFiles))
assert(length(allSessNums) == length(relFiles))



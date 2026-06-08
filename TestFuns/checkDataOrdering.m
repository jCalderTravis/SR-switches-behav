function checkDataOrdering(DataOrDSet, varargin)
% Check data are ordered, both in terms of session,
% blocks within sessions, and trials within blocks.

% INPUT
% DataOrDSet: Part of the standard data structure. Specifcially, DSet.P(i).Data
%   for one participant. Alternatively can provide DSet, and then
%   DSet.P(i).Data will be tested
% varargin{1}: bool. If true, skip processing of timings, and skip many
%   tests. Useful for when have simualated data which doesn't yet have
%   timing or response information. Default is false.

% HISTORY
% 2021, JCT
% 07.02.2023 Read through, including called functions
% 16.05.2023 Updated for Coimbra data

if (~isempty(varargin)) && (~isempty(varargin{1}))
    skipForSim = varargin{1};
else
    skipForSim = false;
end

if isfield(DataOrDSet, 'P')
    DSet = DataOrDSet;
    for iP = 1 : length(DSet.P)
        checkOnePtpntOrdering(DSet.P(iP).Data, skipForSim)
    end
else
    Data = DataOrDSet;
    checkOnePtpntOrdering(Data, skipForSim)
end

end


function checkOnePtpntOrdering(Data, skipForSim)

fieldsToCheck = {'SessionNum', 'BlockNum', 'TrialNum'};

% BlockNum is allowed to reset once for each session -1, and trial num can
% reset once for each block -1. Track this. A complication here is that 
% sessions that end with a block number that matches the block number
% with which the next session begins, will not generate a reset.
noBlkReset = 0;
prevSessLastBlk = nan;
sessNums = unique(Data.SessionNum);

for iS = 1 : length(sessNums)
    blks = unique(Data.BlockNum(Data.SessionNum == sessNums(iS)));

    if prevSessLastBlk == blks(1)
        noBlkReset = noBlkReset +1;
    end

    prevSessLastBlk = blks(end);
end

numBlocks = size(unique([Data.SessionNum, Data.BlockNum], 'rows'), 1);
resetsPermitted = [0, nan, nan];
resetsPermitted(2) = length(unique(Data.SessionNum)) -1 -noBlkReset;
resetsPermitted(3) = numBlocks -1;
if isfield(Data, 'CueID')
    fieldsToCheck{end+1} = 'CueID';
    % CueID gives cue number within each block
    resetsPermitted(end+1) = numBlocks -1;
end

for iF = 1 : length(fieldsToCheck)
    
    TheseValues = Data.(fieldsToCheck{iF});
    differences = diff(TheseValues);
    
    numResets = sum(differences < 0);
    if numResets ~= resetsPermitted(iF)
        error('Data is not in the order expected')
    end
end

% Check no trials are missing by checking that, apart from resets, and
% entries from the same trial, the gap between trials is always only 1
differences = diff(Data.TrialNum);
differences = differences(differences >0);
assert(all(differences == 1))

% Also check the cues are in order if this looks like it is cue data
expectedCueDataFields = {'CueID', 'CueFlipTime'};
actualFields = fieldnames(Data);

anyMatches = false;
for iE = 1 : length(expectedCueDataFields)
    if any(strcmp(expectedCueDataFields{iE}, actualFields))
        anyMatches = true;
    end
end

if anyMatches
    checked = false(length(Data.TrialNum), 1);
    
    trialIdenifiers = [Data.SessionNum, Data.BlockNum, Data.TrialNum];
    assert(size(trialIdenifiers, 2) == 3)
    
    uniqueTrials = unique(trialIdenifiers, 'rows');
    
    for iT = 1 : size(uniqueTrials, 1)
        theseIdentifiers = uniqueTrials(iT, :);
        assert(isequal(size(theseIdentifiers), [1, 3]))
        
        correspondingData = (Data.SessionNum == theseIdentifiers(1)) ...
            & (Data.BlockNum == theseIdentifiers(2)) ...
            & (Data.TrialNum == theseIdentifiers(3));
        
        theseCueTimes = Data.CueFlipTime(correspondingData);
        assert(~isempty(theseCueTimes))
        
        if ~all(diff(theseCueTimes(:)) > 0)
            if skipForSim
                assert(all(isnan(theseCueTimes(:))))
            else
                error('Cues are not in order')
            end
        end
        
        assert(~any(checked(correspondingData)))
        checked(correspondingData) = true;
    end
    
    assert(all(checked))
end

end


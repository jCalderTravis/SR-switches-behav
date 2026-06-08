function [ConcatTrlData, ConcatCueData, DSetSpec, WaterBlocks] ...
    = loadOnePtpntData(ptpntID, saveDir, IceStructure, skipForSim, ...
                        relativeTimes, isPilotData)
% Loads the matlab data from the experiment script for one participant.
% Loads data from all sessions and combines into two data structures. One
% that makes it easy to work with trial-by-trial data, and one that makes
% it easy to do analysis on the many cues presented each trial.

% INPUT
% ptpntID: Number. Participant ID number.
% saveDir: Directory containing results files, or cell array of several
%   directories to search. The string(s) may contain the * wildcard, but 
%   should each match to a single directory only (at most).
% IceStructure: Matlab strcuture describing the sessions for which ice 
%   water was used. Should have three fields, 'PtpntID', 'Session', 
%   'IceUsed'. Each field contains a column vector, and all three column 
%   vectors are the same size. Together they describe whether ice was used 
%   for each participant and session.
% skipForSim: boolean. If true, skip processing of timings, and skip many 
%   tests. Also mark all trials as having a response at a time such 
%   that the trial is valid. Useful for when have simualated data which 
%   doesn't yet have timing or response information.
% relativeTimes: boolean. If true, convert from absolute timing of events,
%   to timings relative to the fixation flip on each trial
% isPilotData: bool. Set to true if processing pilot data. Some 
%   tests/checks may then be skipped.

% OUTPUT
% WaterBlocks: struct. Contains info on which blocks ice/control water was 
%   used prior to them, for each session.

% HISTORY
% 2020-2022, JCT
% 07.02.2023 Read through, including called functions

if skipForSim
    disp('Skipping processing and tests of timing information.')
end

relFiles = findPtpntFiles(saveDir, ptpntID);

[AllTrlData, AllCueData, allBlockNums, allSessNums] = ...
    loadBlockFiles(relFiles, IceStructure, relativeTimes, skipForSim, ...
        ptpntID);

[DSetSpec, WaterBlocks] = loadExpInfoFiles(relFiles, ptpntID, allSessNums);

if isPilotData || skipForSim
    permitUnknown = true;
else
    permitUnknown = false;
end
checkWaterDataConsistent(IceStructure, WaterBlocks, permitUnknown)

[ConcatTrlData, ConcatCueData] = concatAllBlksData(ptpntID, ...
    AllTrlData, AllCueData, allBlockNums, allSessNums);

% Check data is in order
allConcatData = {ConcatTrlData, ConcatCueData};

for iD = 1 : length(allConcatData)
    checkDataOrdering(allConcatData{iD}, skipForSim)
end

disp(['Total trials found: ' num2str(length(ConcatTrlData.BlockType))])
disp(['Total cues found: ' num2str(length(ConcatCueData.CueID))])

end







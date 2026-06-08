function [TrlDSet, CueDSet, AllWaterBlocks] = loadAllPtpntData(saveDirs, ...
    ptpntID, IceStructure, skipForSim, relativeTimes, varargin)
% Collects all the data from several participants into a single data
% structure

% INPUT
% saveDirs: Cell array. Each element contains the information on where to
%   find the raw data files for one participant. Therefore, if there were 3
%   participants this would be a 3 long cell array. Each element can either
%   be a single directory as a string or, if the files for this participant
%   are in several locations, it can itself be a cell array with each 
%   element being the string of one directory in which to look. The 
%   strings may contain the * wildcard, but should each match to a single
%   directory only (at most).
% ptpntID: Numeric array as long as saveDirs. Each entry should be the
%   participant ID number (this appears in the file name of the data files). 
%   Note that the ordering of the participants in TrlDSet and CueTrlDSet 
%   may not match the ptpnt ID number. This is becuase the participants in 
%   TrlDSet and CueTrlDSet are in the order in which data from the 
%   correspondign participant is loaded. 
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
%   to timings relative to the fixation flip on each trial. Else, leave as 
%   absolute timings where zero has no significant meaning.
% varargin{1}: If set to true, many fields which are not commonly used are
%   removed from the output data structures. Default is false.
% varargin{2}: bool. Default false. Set to true if processing pilot data.
%   Some tests/checks may then be skipped.

% OUTPUT 
% TrlDSet: Structure containing data organised to make trial-wise analysis
%   easy
% CueDSet: Structure containing data organised to make analysis on the cues
%   simple
% AllWaterBlocks: Struct. Contains info on which blocks ice/control water 
%   was used prior to them, for each session and participant.

% HISTORY
% 2021, JCT
% 07.02.2023 Read through, including called functions

% Process input
if (~isempty(varargin)) && (~isempty(varargin{1}))
    trimData = varargin{1};
else
    trimData = false;
end

if (length(varargin)>1) && (~isempty(varargin{2}))
    isPilotData = varargin{2};
else
    isPilotData = false;
end

[saveDirs, ptpntID] = findIDsWithData(saveDirs, ptpntID);

AllSpecs = cell(length(saveDirs), 1);
AllWaterBlocks = [];
TotalWaterEntries = 0;
for iP = 1 : length(saveDirs)

    [TrlData, CueData, AllSpecs{iP}, WaterBlocks] = loadOnePtpntData( ...
                                                ptpntID(iP), ...
                                                saveDirs{iP}, ...
                                                IceStructure, ...
                                                skipForSim, ...
                                                relativeTimes, ...
                                                isPilotData);
    TrlDSet.P(iP).Data = TrlData;
    TrlDSet.P(iP).Spec.PtpntID = ptpntID(iP);
    
    CueDSet.P(iP).Data = CueData;
    CueDSet.P(iP).Spec.PtpntID = ptpntID(iP);
    
    TotalWaterEntries = TotalWaterEntries + length(WaterBlocks.BlockNum);
    AllWaterBlocks = concatinateStructures(AllWaterBlocks, WaterBlocks);
end

assert(length(AllWaterBlocks.PtpntID) == TotalWaterEntries)

% Dataset wide specs. First, check these are always the same
for iE = 1 : length(AllSpecs)
    assert(isequal(AllSpecs{1}, AllSpecs{iE}))
end
TrlDSet.Spec = AllSpecs{1};
CueDSet.Spec = AllSpecs{1};

if skipForSim
    disp('Skipping data tests')
else
    testCombinedData(TrlDSet, CueDSet)
end

% Have we been requested to remove less useful fields?
if trimData
    for iP = 1 : length(TrlDSet.P)
        TmpData = [];
        TmpData.BlockNum = TrlDSet.P(iP).Data.BlockNum;
        TmpData.Acc = TrlDSet.P(iP).Data.Acc;
        TmpData.RuleIsHorizToLeftForTrial ...
            = TrlDSet.P(iP).Data.RuleIsHorizToLeftForTrial;
        TmpData.RespIsLeft = TrlDSet.P(iP).Data.RespIsLeft;
        TmpData.StimIsHoriz = TrlDSet.P(iP).Data.StimIsHoriz;
        TmpData.CueLoc = TrlDSet.P(iP).Data.CueLoc;
        TmpData.BlockType = TrlDSet.P(iP).Data.BlockType;
        TrlDSet.P(iP).Data = TmpData;
    end
end

checkReportedCueStats(CueDSet)


function [saveDirsWithData, withDataIDs] = findIDsWithData(saveDirs, ...
    ptpntID, varargin)
% Trim down the list of participant IDs and assiated save directories to
% only those that have data asssociated with them.

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
% varargin{1}: bool. If true, runs a check by calling the very same
%   function again, on the values that are about to be returned. Default
%   true.

% OUTPUT
% Same as the input but trimmed down as described above.

% HISTORY
% 07.02.2023 Read through, and called functions

if (~isempty(varargin)) && (~isempty(varargin{1}))
    repeatOperation = varargin{1};
else
    repeatOperation = true;
end

assert(length(saveDirs) == length(ptpntID))

hasData = true(length(ptpntID), 1);
for iP = 1 : length(ptpntID)
    
    relFiles = findPtpntFiles(saveDirs{iP}, ptpntID(iP), false);
    if isempty(relFiles)
        warning(['No data found for participant with ID: ' ...
            num2str(ptpntID(iP))])
        hasData(iP) = false;
    end
end

saveDirsWithData = saveDirs(hasData);
withDataIDs = ptpntID(hasData);
assert(length(saveDirsWithData) == length(withDataIDs))

if repeatOperation
    [saveDirsCheck, idCheck] = findIDsWithData(saveDirsWithData, ...
        withDataIDs, false);
    assert(length(saveDirsCheck) == length(idCheck))
    assert(length(saveDirsCheck) == length(saveDirsWithData))
end
    



function relFiles = findPtpntFiles(saveDir, ptpntID, varargin)
% Find details of all the results files in the directories requested

% INPUT
% saveDir: Directory containing results files, or cell array of several
%   directories to search.
% ptpntID: ID of the participant that we are looking for files for
% varargin{1}: bool. If true, is verbose. Default true.

% HISTORY
% 2020-2022, JCT
% 07.02.2023 Read through, and called functions

if ~iscell(saveDir)
    saveDir = {saveDir};
end

if (~isempty(varargin)) && (~isempty(varargin{1}))
    verbose = varargin{1};
else
    verbose = true;
end

relFiles = [];
for iD = 1 : length(saveDir)
    thisSaveDir = saveDir{iD};
    
    theseRelFiles = dir([thisSaveDir '/ptpnt' num2str(ptpntID) ...
        '_test_session*_block*_BlockData*.mat']);
    
    for iR = 1 : length(theseRelFiles)
        if ~isequal(theseRelFiles(1).folder, theseRelFiles(iR).folder)
            error(['Each string in the input should specify only a ', ...
                'single folder.'])
        end
    end
    
    if isempty(theseRelFiles)
        if verbose
            warning(['No relevant files round in the following ', ...
                'directory: ', thisSaveDir])
        end
        continue 
    end
    
    if isempty(relFiles)
        relFiles = theseRelFiles;
    else
        relFiles = [relFiles; theseRelFiles];
    end
end

if verbose
    disp(['Data found for ' num2str(length(relFiles)) ' blocks for participant ' ...
        num2str(ptpntID)])
end




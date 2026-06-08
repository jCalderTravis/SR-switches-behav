function Config = loadConfig(name, part)
% Function to hold various configuration settings. Used together with
% loadModellingConfig.m.

% INPUT
% name: string. Name of configuration to load. Supported config names: 'pilot', 
%   'mainStudy', 'coimbra'.
% part: string. Part of configuration to load, e.g. key direcotires, or
%   e.g. analysis settings. See code for options, some of which include...
%       keyDirs: In this case code also creates required directories if 
%           these don't already exist.
%       ptpntLongIdFun: The returned Config contains a field 
%           FindPtpntLongID. This field contains a function which accepts 
%           a numeric participant ID and returns the long form of the 
%           string ID for that participant.

% OUTPUT
% Config: structure. Fields vary depending on which configuration was
% requested

% HISTORY
% 2021->, JCT
% 07.02.2023 Read through, and called functions

% Check requested config is allowed
permittedConfigs = {'pilot', 'mainStudy', 'coimbra'};
matches = sum(strcmp(name, permittedConfigs));
if matches ~= 1
    error('Requested config is not one of the permitted configs.')
end

set(groot, 'DefaultLineLineWidth', 0.5)

Dirs = loadCoreDirs(name);

if strcmp(name, 'pilot')
    error('Config name "pilot" is no longer in use')
    
elseif strcmp(name, 'mainStudy')
    sessions = 2 : 5;
    
    if strcmp(part, 'keyDirs')
        Config = Dirs;
        
    elseif strcmp(part, 'behavDirs')
        Config.PtpntID = 1:24;
        Config.AllBehavDataDirs = cell(length(Config.PtpntID), 1);
        
        for iP = 1 : length(Config.PtpntID)
            thisPtpntDirs = cell(length(sessions), 1);
            
            for iS = 1 : length(sessions)
                thisPtpntDirs{iS} = fullfile(...
                    Dirs.DataDir, ...
                    ['Data-P' findPtpntStr(Config.PtpntID(iP)) ...
                    '-S0' num2str(sessions(iS)) '-*-*']);
            end
            
            Config.AllBehavDataDirs{iP} = thisPtpntDirs;
        end
        
    elseif strcmp(part, 'iceStructure')
        IceTable = readtable(fullfile(...
            Dirs.DataDir, 'Stress_condition.xls'), 'Range', 'A1:E25');
        
        numRows = height(IceTable);
        numFlattenedRows = numRows * length(sessions);
        Config.IceStructure.PtpntID = nan(numFlattenedRows, 1);
        Config.IceStructure.Session = nan(numFlattenedRows, 1);
        Config.IceStructure.IceUsed = nan(numFlattenedRows, 1);
        
        flatRowCount = 1;
        
        for iR = 1 : numRows
            ThisRow = IceTable(iR, :);
            ThisPtpntID = ThisRow.Pnum;
            
            for iS = 1 : length(sessions)
                thisCol = ['Session_' num2str(sessions(iS))];
                assert(any(strcmp(thisCol, ...
                    ThisRow.Properties.VariableNames)))
                
                assert(isnan(Config.IceStructure.PtpntID(flatRowCount)))
                Config.IceStructure.PtpntID(flatRowCount) = ThisPtpntID;
                Config.IceStructure.Session(flatRowCount) = sessions(iS);
                Config.IceStructure.IceUsed(flatRowCount) ...
                    = ThisRow.(thisCol);
                
                flatRowCount = flatRowCount +1;
            end
        end
        
        assert(~any(isnan(Config.IceStructure.IceUsed(:))))
    
    elseif strcmp(part, 'ptpntLongIdFun')
        Config.FindPtpntLongID = @(ptpntID) ['P' findPtpntStr(ptpntID)];
    else
        error('Bug')
    end
    
elseif strcmp(name, 'coimbra')

    if strcmp(part, 'keyDirs')
        Config = Dirs;
        
    elseif strcmp(part, 'behavDirs')
        Config.CombinedDataFileName = fullfile(Dirs.DataDir, 'DSet.mat');
        
    elseif strcmp(part, 'iceStructure')
        error('Not coded up')
    
    elseif strcmp(part, 'ptpntLongIdFun')
        error('Not coded up');
    else
        error('Bug')
    end
else
    error('Bug')
end


if strcmp(part, 'keyDirs')
    for thisF = fieldnames(Dirs)'
        thisDirName = Dirs.(thisF{1});
        if ~exist(thisDirName, 'dir')
            mkdir(thisDirName)
        end
    end
end

end


function ptpntStr = findPtpntStr(ptpntID)

if ptpntID < 10
    ptpntStr = ['0' num2str(ptpntID)];
else
    ptpntStr = num2str(ptpntID);
end

assert(length(ptpntStr) == 2)
end




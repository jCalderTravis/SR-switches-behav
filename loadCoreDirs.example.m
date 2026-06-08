function CoreDirs = loadCoreDirs(configName)
% Example local directory configuration for loadConfig.m.
%
% Rename this file to loadCoreDirs.m and update the folder paths below for
% your own environment before running the analysis pipeline.
%
% Supported configName values: 'pilot', 'mainStudy', 'coimbra'.

if strcmp(configName, 'pilot')
    CoreDirs.DataDir = 'DIRECTORY_PATH_HERE';
    CoreDirs.StepResultsDir = 'DIRECTORY_PATH_HERE';
    CoreDirs.FinalResultsDir = 'DIRECTORY_PATH_HERE';

elseif strcmp(configName, 'mainStudy')
    CoreDirs.DataDir = 'DIRECTORY_PATH_HERE';
    CoreDirs.StepResultsDir = 'DIRECTORY_PATH_HERE';
    CoreDirs.FinalResultsDir = 'DIRECTORY_PATH_HERE';

elseif strcmp(configName, 'coimbra')
    CoreDirs.DataDir = 'DIRECTORY_PATH_HERE';
    CoreDirs.StepResultsDir = 'DIRECTORY_PATH_HERE';
    CoreDirs.FinalResultsDir = 'DIRECTORY_PATH_HERE';

else
    error('Unrecognised config name')
end

for f = fieldnames(CoreDirs)'
    if strcmp(CoreDirs.(f{1}), 'DIRECTORY_PATH_HERE')
        error('Please update the directory paths in loadCoreDirs.m before running the analysis pipeline.')
    end
end
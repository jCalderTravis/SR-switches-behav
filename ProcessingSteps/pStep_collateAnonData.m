function pStep_collateAnonData(Options)
% Collate the gender, handedness and age information

% INPUT
% Options: Struct. Has the following fields...
%   Config: See runMatlabStep.m
%   Step: See runMatlabStep.m

% HISTORY
% 2025 JCT

Config = loadConfig(Options.Config, 'behavDirs');

if any(strcmp(Options.Config, {'mainStudy'}))
    NamingConfig = loadConfig(Options.Config, 'ptpntLongIdFun');
    findPtpntLongID = NamingConfig.FindPtpntLongID;

    [saveDirs, ptpntID] = findIDsWithData(Config.AllBehavDataDirs, ...
        Config.PtpntID);
    allAnon = [];

    for iP = 1 : length(ptpntID)
        thisPtpntID = ptpntID(iP);
        thisLongID = findPtpntLongID(thisPtpntID);
        Config = loadConfig(Options.Config, 'keyDirs');

        theseFiles = dir(Config.DataDir + "/Data-" + thisLongID + ...
                            "-S01-*-*m/ptpnt" + num2str(thisPtpntID) + ...
                            "_anon_*.mat");
        assert(length(theseFiles) == 1)

        Loaded = load(theseFiles(1).folder + "/" + theseFiles(1).name);

        if isempty(allAnon)
            allAnon = Loaded.Anon;
        else
            allAnon(end+1) = Loaded.Anon;
        end
    end
else
    error('Bug')
end    
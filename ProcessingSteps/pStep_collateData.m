function pStep_collateData(Options)
% Also saves data on when ice/control water was used, for importing
% into the python functions, if relevant

% INPUT
% Options: Struct. Has the following fields...
%   Config: See runMatlabStep.m
%   Step: See runMatlabStep.m

% HISTORY
% 2021-2022 JCT
% 21.02.2023 Read through, including called functions
% 05.2023 Updated for Coimbra data

dirForSave = findDir(Options, 'step');
Config = loadConfig(Options.Config, 'behavDirs');

if any(strcmp(Options.Config, {'pilot', 'mainStudy'}))
    IceConfig = loadConfig(Options.Config, 'iceStructure');
    IceStructure = IceConfig.IceStructure;
    NamingConfig = loadConfig(Options.Config, 'ptpntLongIdFun');
    findPtpntLongID = NamingConfig.FindPtpntLongID;
    
    if strcmp(Options.Config, 'pilot')
        isPilot = true;
    else
        isPilot = false;
    end
    
    relativeTimes = [true, false];
    names = {'DSet', 'DSet_AbsoluteTime'};
    
    for iTime = 1 : length(relativeTimes)
        [TrlDSet, CueDSet, WaterBlocks] = loadAllPtpntData(...
            Config.AllBehavDataDirs, ...
            Config.PtpntID, ...
            IceStructure, ...
            false, ...
            relativeTimes(iTime), ...
            false, ...
            isPilot);
        
        fname = [dirForSave, names{iTime}];
        save(fname, 'TrlDSet', 'CueDSet')
    end
    
    uniquePtpntIDs = unique(WaterBlocks.PtpntID);
    for iPtpnt = 1 : length(uniquePtpntIDs)
        
        thisPtpntID = uniquePtpntIDs(iPtpnt);
        fname = [dirForSave findPtpntLongID(thisPtpntID) 'IceTimings.csv'];
        
        relRows = WaterBlocks.PtpntID == thisPtpntID;
        ThisWaterBlocks = struct();
        ThisWaterBlocks.Sess = WaterBlocks.Sess(relRows);
        ThisWaterBlocks.BlockNum = WaterBlocks.BlockNum(relRows);
        % Note there is further information in WaterBlocks that we could 
        % also convert to csv if we wanted to
        saveStructAsCsv(ThisWaterBlocks, fname)
    end
    
elseif strcmp(Options.Config, 'coimbra')
    Loaded = load(Config.CombinedDataFileName);
    TrlDSet = Loaded.DSet;
    [TrlDSet, CueDSet] = formatCoimbraData(TrlDSet);
    save([dirForSave, 'DSet'], 'TrlDSet', 'CueDSet');
    
else
    error('Bug')
end
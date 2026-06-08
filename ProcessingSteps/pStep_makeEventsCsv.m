function pStep_makeEventsCsv(Options)
% Save a CSV file containing data on all key events and computational
% variables at these events

% INPUT
% Options: Struct. Has the following fields...
%   Config: See runMatlabStep.m
%   Step: See runMatlabStep.m

% LOADS 
% Save files from: pStep_fitModel

% HISTORY
% 2021-2022 JCT
% 27.02.2023 Read through, including called functions

stepSaveDir = findDir(Options, 'step');

TrlDSet_Fitted = loadData(Options.Config, 'fitted_data');

for iP = 1 : length(TrlDSet_Fitted.P)
    critInst = computeAcc(TrlDSet_Fitted.P(iP).Data, 'instructed') > 0.6;
    critInf = computeAcc(TrlDSet_Fitted.P(iP).Data, 'inferred') > 0.55;
    if (~critInst) || (~critInf)
       error('Ptpnt does not meet preregistered inclusion criteria') 
    end
end

% Load the collated trial-level and cue-level data that contains
% absolute timings
LoadOptions.Config = Options.Config;
LoadOptions.Step = 'collateData';
loadFile = fullfile(findDir(LoadOptions, 'step'), 'DSet_AbsoluteTime');
Loaded = load(loadFile);
TrlDSet_AbsTime = Loaded.TrlDSet;
CueDSet_AbsTime = Loaded.CueDSet;

for iP = 1 : length(TrlDSet_AbsTime.P)
    Config = loadConfig(Options.Config, 'ptpntLongIdFun');
    ptpntName = Config.FindPtpntLongID(...
        TrlDSet_AbsTime.P(iP).Spec.PtpntID);
    
    saveFname = fullfile(stepSaveDir, ...
        ['eventsAndCompVars_' ptpntName '.csv']);
    makeEventsCsv(TrlDSet_AbsTime, CueDSet_AbsTime, ...
        TrlDSet_Fitted, iP, saveFname)
end

% Also save the data set containing the fitted parameters that were 
% used to compute the computational variables, so that have record of 
% the values of the parameters used in the computation.
saveFname = fullfile(stepSaveDir, 'eventsAndCompVars_paramsUsed');
save(saveFname, 'TrlDSet_Fitted')


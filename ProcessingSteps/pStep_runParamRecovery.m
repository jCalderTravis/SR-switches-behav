function pStep_runParamRecovery(Options)

% INPUT
% Options: Struct. Has the following fields...
%   Config: See runMatlabStep.m
%   Step: See runMatlabStep.m
%   Params: 'Rand' or 'Fitted'. Deteremines which parameters to use for 
%       simulating new data, either random parameters or those resulting 
%       from fits to the data.
%   SimSize: 'small', 'med' or 'large' to determine the
%       number of trials, cues and blocks for each simulated participant.

% HISTORY
% 2021-2022 JCT

if strcmp(Options.SimSize, 'small')
    ExtraSettings.NumBlocks = 3;
    ExtraSettings.TrialsPerBlock = 8;
    ExtraSettings.CueDrawStrategy = 'uniform3-10';
elseif strcmp(Options.SimSize, 'medSmall')
    ExtraSettings.NumBlocks = 12;
    ExtraSettings.TrialsPerBlock = 28;
    ExtraSettings.CueDrawStrategy = 'uniform3-10';
elseif strcmp(Options.SimSize, 'med')
    ExtraSettings.NumBlocks = 12;
    ExtraSettings.CueDrawStrategy = 'uniform3-10';
elseif strcmp(Options.SimSize, 'large')
    ExtraSettings.NumBlocks = 18;
    ExtraSettings.CueDrawStrategy = 'uniform3-18';
else
    error('Bug')
end

simSaveDir = findDir(Options, 'step');
plotSaveDir = findDir(Options, 'final');
ModelSettings = loadModellingConfig('base', 'hamburg', false);

if strcmp(Options.Params, 'randParams')
    simMode = 'randParams';
    TrlDSet = [];
    modelNum = [];
    
elseif strcmp(Options.Params, 'fittedParams')
    simMode = 'fittedParams';
    
    LoadOptions.Config = Options.Config;
    LoadOptions.Step = 'fitData';
    loadDir = findDir(LoadOptions, 'step');
    loadFile = fullfile(loadDir, 'fittedDSet');
    
    Loaded = load(loadFile);
    TrlDSet = Loaded.TrlDSet;
    modelNum = 1;
    
    % Duplicate participants to help get more of a sense of
    % variability in fit results?
    nReps = 10;
    origPtpnts = length(TrlDSet.P);
    for iRep = 2:nReps
        for iP = 1 : origPtpnts
            TrlDSet.P(end+1) = TrlDSet.P(iP);
        end
    end
end

DSet = runParamRecovery(simSaveDir, plotSaveDir, ModelSettings, ...
    simMode, TrlDSet, modelNum, ExtraSettings);

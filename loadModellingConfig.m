function Settings = loadModellingConfig(modelName, exp, incInstructed)
% Load the Settings structure required for the mat-comp-model-tools
% repository.

% INPUT
% modelName: str. Load the settings for which model?
% exp: str. The experiment being analysed. 'hamburg' or 'coimbra'.
% incInstructed: bool. If true include instructed condition trials in 
%   the model fitting.

% HISOTRY
% 2020 - 2021, JCT
% 23.02.2023 Read through, including called functions, and checking
%   the parameter bounds are sensible
% 09.06.2023 Updated for Coimbra
% 03.07.2023 Updated all parameter bounds taking into account Coimbra too

DForm = findDataFormat([]);
incParams = findIncParams(modelName);

Settings.Algorithm = 'fmincon';
Settings.ModelName = modelName;
Settings.ComputeTrialLL.FunName = 'sR_computeTrialLL';
Settings.ComputeTrialLL.Args = {modelName};
Settings.NumStartPoints = 10;
Settings.PresetStartPoints = false;
Settings.NumStartCand = 250;
Settings.TrialChunkSize = 'off';
Settings.FindIfOutOfBounds = 'none';
Settings.SuppressOutput = true;
Settings.ReseedRng = true;
Settings.DebugMode = false;
Settings.JobsPerContainer = 300;

if incInstructed
    findInc = @(Data) logical(Data.RtIsValid);
else
    findInc = @(Data) ismember(Data.BlockType, DForm.AllInferenceBlks) ...
        & logical(Data.RtIsValid);
end

Settings.FindSampleSize = @(Data) sum(findInc(Data));
Settings.FindIncludedTrials = @(Data) findInc(Data);

% H
StandardParam(1).Name = 'ObserverH';
StandardParam(1).FitLog = false;
StandardParam(1).FitSqrt = false;
StandardParam(1).UnpackedOrder = 1;
StandardParam(1).UnpackedShape = [1, 1];
StandardParam(1).Regulariser = @(param) 0;

StandardParam(1).LowerBound = @() 0;
StandardParam(1).PLB = @() 0.001;
StandardParam(1).UpperBound = @() 1;
StandardParam(1).PUB = @() 0.5;

% Beta
StandardParam(2).Name = 'ObserverBeta';
StandardParam(2).FitLog = false;
StandardParam(2).FitSqrt = false;
StandardParam(2).UnpackedOrder = 1;
StandardParam(2).UnpackedShape = [1, 1];
StandardParam(2).Regulariser = @(param) 0;

if strcmp(exp, 'coimbra')
    StandardParam(2).LowerBound = @() 0.0001;
    StandardParam(2).PLB = @() 0.005;
    StandardParam(2).UpperBound = @() 8000;
    StandardParam(2).PUB = @() 100;
elseif strcmp(exp, 'hamburg')
    StandardParam(2).LowerBound = @() 0.01;
    StandardParam(2).PLB = @() 0.1;
    StandardParam(2).UpperBound = @() 2000;
    StandardParam(2).PUB = @() 300;
else
    error('Unknown option')
end

% DecisionNoiseSigma
StandardParam(3).Name = 'DecisionNoiseSigma';
StandardParam(3).FitLog = false;
StandardParam(3).FitSqrt = false;
StandardParam(3).UnpackedOrder = 1;
StandardParam(3).UnpackedShape = [1, 1];
StandardParam(3).Regulariser = @(param) 0;

if strcmp(exp, 'coimbra')
    StandardParam(3).LowerBound = @() 0;
    StandardParam(3).PLB = @() 0.005;
    StandardParam(3).UpperBound = @() 2000;
    StandardParam(3).PUB = @() 6;
    
    if strcmp(modelName, 'perfect-acc')
        StandardParam(3).PUB = @() 200;
    end
    
elseif strcmp(exp, 'hamburg')
    StandardParam(3).LowerBound = @() 0;
    StandardParam(3).PLB = @() 0.05;
    StandardParam(3).UpperBound = @() 20;
    StandardParam(3).PUB = @() 5;
else
    error('Unknown option')
end

% AccumBound (cue mean diff in main experiment of 0.42, in Coimbra 0.50)
StandardParam(4).Name = 'AccumBound';
StandardParam(4).FitLog = false;
StandardParam(4).FitSqrt = false;
StandardParam(4).UnpackedOrder = 1;
StandardParam(4).UnpackedShape = [1, 1];
StandardParam(4).LowerBound = @() 0;
StandardParam(4).PLB = @() 0.1;
StandardParam(4).UpperBound = @() 2000;
StandardParam(4).PUB = @() 12;
StandardParam(4).Regulariser = @(param) 0;

% AccumLeak
StandardParam(5).Name = 'AccumLeak';
StandardParam(5).FitLog = false;
StandardParam(5).FitSqrt = false;
StandardParam(5).UnpackedOrder = 1;
StandardParam(5).UnpackedShape = [1, 1];
StandardParam(5).LowerBound = @() 0;
StandardParam(5).PLB = @() 0;
StandardParam(5).UpperBound = @() 1;
StandardParam(5).PUB = @() 1;
StandardParam(5).Regulariser = @(param) 0;

% LapseRate
StandardParam(6).Name = 'LapseRate';
StandardParam(6).FitLog = false;
StandardParam(6).FitSqrt = false;
StandardParam(6).UnpackedOrder = 1;
StandardParam(6).UnpackedShape = [1, 1];
StandardParam(6).LowerBound = @() 0;
StandardParam(6).PLB = @() 0;
StandardParam(6).UpperBound = @() 1;
StandardParam(6).PUB = @() 0.4;
StandardParam(6).Regulariser = @(param) 0;


for iPm = 1 : length(StandardParam)
    StandardParam(iPm).InitialVals = @()drawUniformOnInterval(1, ...
        StandardParam(iPm).PLB(), ...
        StandardParam(iPm).PUB(), ...
        StandardParam(iPm).FitLog);
end

paramCount = 0;
paramSetCount = 0;

for iParam = 1 : length(StandardParam)
    CurrentParam = StandardParam(iParam);
    
    matches = strcmp(CurrentParam.Name, incParams);
    if sum(matches) == 1
        [Settings, paramCount, paramSetCount] ...
            = addParameter(Settings, paramCount, paramSetCount, ...
            CurrentParam);
    else
        assert(sum(matches) == 0)
    end
end

Settings.NumParams = paramCount;
assert(paramSetCount == length(incParams))

end


function [Settings, paramCount, paramSetCount] ...
    = addParameter(Settings, paramCount, paramSetCount, ParamToAdd)
% Add a parameter structure to the modelling settings structure 'Settings',
% keeping track of how many parameters are now specified in the model described
% by 'Settings'.

fieldsToAdd = fieldnames(ParamToAdd);

for iField = 1 : length(fieldsToAdd)
    Settings.Params(paramSetCount+1).(fieldsToAdd{iField}) ...
        = ParamToAdd.(fieldsToAdd{iField});
end

exampleInitialVals = ParamToAdd.InitialVals();
Settings.Params(paramSetCount+1).PackedOrder = ...
    paramCount + 1 : (paramCount + length(exampleInitialVals(:)));

paramSetCount = paramSetCount +1;
paramCount = paramCount + length(exampleInitialVals(:));

end

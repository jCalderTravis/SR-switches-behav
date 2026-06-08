function pStep_fitModel(Options)
% Run the model fitting

% INPUT
% Options: Struct. Has the following fields...
%   Config: See runMatlabStep.m
%   Step: See runMatlabStep.m
%   Condition: str (optional). Provide a string in order to tim down the
%       data to specific conditions before running the analysis. Options...
%           'baseline': trims dataset down to only the no ice water 
%               sessions.
%           'twoLevelTask' trims down to blocks that involved both the
%               higher-level context inference and the lower-level stimulus 
%               to response mapping.
%           'inferenceOnly' trims down to blocks that involved the
%               one-level inference only task. Removes participants that 
%               did not do this block type.
%           'fullTaskLab' trims down to block that involved the two level
%               task in the behavioural lab ('full_task_lab' blocks). 
%               Removes participants for whom there is no one-level 
%               inference-only task data. This is helpful for the Coimbra 
%               dataset, where we want to compare full task with 
%               inference only. Hence, we only want to use participants 
%               that have both.
%   ScheduleName: str (optional). If a string is provided then the fitting
%       is not run directly, but rather it is scheduled for running on a
%       cluster (also using parfor loops). Jobs will be saved in a folder 
%       with a name matching the provided string. The filepath will be
%       deterined automatically, so just the name of the folder should be
%       given.
%   Models: str (optional). Determines the models to fit and which trials
%       are used in the fitting. Options are...
%           'standard' (default). The usual models. No lapse rate (but do 
%               have decision noise. Instructed trials are not used for the
%               model fitting.
%           'withLapses'. Like 'standard' but all models now include a 
%               lapse rate parameter. Instructed trials are used for model 
%               fitting.
%           'withLapsesPlus'. Like 'withLapses' but additionally includes 
%               the normative model with miscalibrated h, and no lapses, 
%               for comparison. Instructed trials are used for model 
%               fitting.
%           'withLapsesMin'. Like 'withLapses' but only fits the
%               miscalibrated-h-normative model (with lapses). Instructed
%               trials are used for model fitting.

% LOADS
% Save files from: pStep_collateData

% HISTORY
% 2021-2022 JCT
% 21.02.2023 Read through, including called functions
% 09.06.2023 Checked for Coimbra

conditionField = 'Condition';
scheduleField = 'ScheduleName';
modelsField = 'Models';

assert(all(ismember(fieldnames(Options), ...
    {'Config', 'Step', conditionField, scheduleField, modelsField})))

resultsSaveDir = findDir(Options, 'step');
plotSaveDir = findDir(Options, 'final');
TrlDSet = loadData(Options.Config, 'relative_time_real_data');

if isfield(Options, conditionField)
    if any(strcmp(Options.(conditionField), {'inferenceOnly', 'fullTaskLab'}))
        relPtpnts = findPtpntsWithBlkType(TrlDSet, 'inference-only');
        TrlDSet.P = TrlDSet.P(relPtpnts);
    else
        assert(any(strcmp( ...
            Options.(conditionField), {'baseline', 'twoLevelTask'})))
    end

    TrlDSet = trimToCondition(TrlDSet, Options.(conditionField));
end

disp('Size of trimmed dataset that will be fitted:')
disp(['Num participants: ', num2str(length(TrlDSet.P))])
numTrials = mT_stackData(TrlDSet.P, @(strct) length(strct.Data.BlockType));
disp(['Average num trials: ', num2str(mean(numTrials))])

if isfield(Options, scheduleField)
    runOnClust = true;
else
    runOnClust = false;
end

% Modelling code assumes data are ordered
for iP = 1 : length(TrlDSet.P)
    checkDataOrdering(TrlDSet.P(iP).Data)
end

if strcmp(Options.Config, 'mainStudy')
    exp = 'hamburg';
elseif strcmp(Options.Config, 'coimbra')
    exp = 'coimbra';
else
    error('Unrecognised config.')
end

if isfield(Options, modelsField)
    modelCombo = Options.(modelsField);
else
    modelCombo = 'standard';
end

if strcmp(modelCombo, 'standard')
    incInstructed = false;
    modelsToFit = { ...
        'miscal-h-b-normative', ...
        'miscal-h-normative', ...
        'normative', ...
        'last-sample', ...
        'perfect-acc', ...
        'bound-acc', ...
        'leaky-acc', ...
        };
elseif strcmp(modelCombo, 'withLapses')
    incInstructed = true;
    modelsToFit = {...
        'miscal-h-b-normative-lapse', ...
        'miscal-h-normative-lapse', ...
        'normative-lapse', ...
        'last-sample-lapse', ...
        'perfect-acc-lapse', ...
        'bound-acc-lapse', ...
        'leaky-acc-lapse', ...
    };
elseif strcmp(modelCombo, 'withLapsesPlus')
    incInstructed = true;
    modelsToFit = {...
        'miscal-h-normative', ...
        'miscal-h-b-normative-lapse', ...
        'miscal-h-normative-lapse', ...
        'normative-lapse', ...
        'last-sample-lapse', ...
        'perfect-acc-lapse', ...
        'bound-acc-lapse', ...
        'leaky-acc-lapse', ...
    };
elseif strcmp(modelCombo, 'withLapsesMin')
    incInstructed = true;
    modelsToFit = {...
        'miscal-h-normative-lapse', ...
    };
else
    error('Unknown option for the selection of models')
end

for iM = 1 : length(modelsToFit)
    ModelSettings(iM) = loadModellingConfig(modelsToFit{iM}, exp, ...
        incInstructed);
end

if runOnClust
    scheduleFolder = fullfile(resultsSaveDir, Options.(scheduleField));
    mkdir(scheduleFolder)
    mT_scheduleFits('clusterPar', TrlDSet, ModelSettings, scheduleFolder);
else
    fitAndEvalModel(TrlDSet, ModelSettings, resultsSaveDir, plotSaveDir)
end




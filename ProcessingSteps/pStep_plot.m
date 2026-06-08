function pStep_plot(Options)
% Plot various things depending on settings

% INPUT
% Options: Struct. Has the following fields...
%   Config: See runMatlabStep.m
%   Step: See runMatlabStep.m
%   Plots: str. Options for both config 'mainStudy' and 'coimbra' are:
%           'real' to make plots of the real data on its own
%       Further options for config 'mainStudy' are:
%           'model' to compare real data to response data simulated on the 
%               basis of the actually presented stimuli.
%           'modelFullSim' to compare real data to model simulated data.
%               Both new responses, and entirely new stimuli are simulated.
%           'realBase' is the same as 'real' but only use data from the 
%               baseline condition is used.
%       Further options for config for 'coimbra' are:
%           'twoLevelModel' same as 'model' except only uses data from the
%               two-level task.
%           'infOnlyModel' same as 'model' except only uses data from the
%               inference-only condition.
%           'lapseModels' same as 'model' but looks at models that were
%               also fitted using a lapse rate to data from all conditions
%           'lapse2LvlModels' same as 'lapseModels' but only uses data from
%               the two-level task.
%           'lapseInfOnlyModels' same as 'lapseModels' but only used data
%               from the inference-only condition.
%           'infOnlyCompare' same as 'model' but only fit
%               miscalibrated-h-normative-lapse, and only use 
%               inference-only blocks in the fitting
%           'twoLvlCompare' same as 'model' but only fit
%               miscalibrated-h-normative-lapse, and only use two-level 
%               task data from the beavioural lab, and exclude participants 
%               for whom there is no inference-only data (enabling 
%               comparison with the fits plottied with the 'infOnlyCompare' 
%               option)
%   numSimReps: integer as a sting. Only provide if config is coimbra and 
%       are plotting model fits. Then this option determines how many times 
%       to replicate the real dataset before simulating response and 
%       accuracy values.

% LOADS 
% Save files from: pStep_collateData, pStep_fitModel

assert(all(ismember(fieldnames(Options), {'Config', 'Step', 'Plots', ...
    'numSimReps'})))

allConfigOpts = {'mainStudy', 'coimbra'};
assert(any(strcmp(Options.Config, allConfigOpts)))

allPltOpts = {'real', 'model', 'modelFullSim', 'realBase', ...
    'twoLevelModel', 'infOnlyModel', ...
    'lapseModels', 'lapse2LvlModels', 'lapseInfOnlyModels', ...
    'infOnlyCompare', 'twoLvlCompare'};

if strcmp(Options.Config, 'mainStudy')
    assert(any(strcmp(Options.Plots, allPltOpts(1:4))))

elseif strcmp(Options.Config, 'coimbra')
    assert(any(strcmp(Options.Plots, ...
                        allPltOpts([1, 5, 6, 7, 8, 9, 10, 11]))))
else
    error('Bug')
end

plotSaveDir = findDir(Options, 'final');
if strcmp(Options.Config, 'mainStudy')
    PltOptions.SkipIce = false;
else
    assert(strcmp(Options.Config, 'coimbra'))
    PltOptions = struct();
end
pltType = Options.Plots;

if any(strcmp(Options.Plots, {'real', 'realBase'}))
    DSets.RealTrlDSet = loadData(Options.Config, ...
        'relative_time_real_data');
    
    if strcmp(Options.Plots, {'realBase'})
        error('The trimming function has changed names and input')
        DSets.RealTrlDSet = trimToBaseCondition(DSets.RealTrlDSet);
        PltOptions.SkipIce = true;
        pltType = 'real';
    else
        assert(strcmp(Options.Plots, {'real'}))
    end
    
elseif any(strcmp(Options.Plots, {'model', 'modelFullSim'}))
    assert(strcmp(Options.Config, 'mainStudy'))
    DSets.RealTrlDSet = loadData(Options.Config, 'fitted_data');
    
    LoadOptions.Config = Options.Config;
    LoadOptions.Step = 'simulate';
    LoadOptions.Type = 'theoryMax';
    loadDir = findDir(LoadOptions, 'step');
    Loaded = load(fullfile(loadDir, 'simTheoryMaxDSet'));
    DSets.OptTrlDSet = Loaded.SimMaxTrlDSet;
    
    if strcmp(Options.Plots, 'modelFullSim')
        LoadOptions.Config = Options.Config;
        LoadOptions.Step = 'simulate';
        LoadOptions.Type = 'fullFromFitted';
        loadDir = findDir(LoadOptions, 'step');
        Loaded = load(fullfile(loadDir, 'fullSimFromFittedDSet'));
        DSets.SimTrlDSet = Loaded.SimTrlDSet;
        DSets.SimRegDSet = Loaded.SimRegDSet;
    end

elseif any(strcmp(Options.Plots, {'twoLevelModel', 'infOnlyModel', ...
                                    'lapseModels', 'lapse2LvlModels', ...
                                    'lapseInfOnlyModels', ...
                                    'infOnlyCompare', 'twoLvlCompare'}))
    assert(strcmp(Options.Config, 'coimbra'))
    LoadOpt.Config = Options.Config;
    LoadOpt.Step = 'fitModel';
    
    if strcmp(Options.Plots, 'twoLevelModel')
        LoadOpt.Condition = 'twoLevelTask';
        LoadOpt.ScheduleName = 'twoLevelTaskRun2';
        PltOptions.modelForSim = 'miscal-h-normative';

    elseif strcmp(Options.Plots, 'infOnlyModel')
        LoadOpt.Condition = 'inferenceOnly';
        LoadOpt.ScheduleName = 'inferenceOnlyRun1';
        PltOptions.modelForSim = 'miscal-h-normative';
    
    elseif any(strcmp(Options.Plots, {'lapseModels', 'lapse2LvlModels', ...
            'lapseInfOnlyModels'}))
        
        LoadOpt.Models = 'withLapses';
        PltOptions.modelForSim = 'miscal-h-normative-lapse';

        if strcmp(Options.Plots, 'lapse2LvlModels')
            LoadOpt.ScheduleName = '240911';
            LoadOpt.Condition = 'twoLevelTask';

        elseif strcmp(Options.Plots, 'lapseInfOnlyModels')
            LoadOpt.ScheduleName = 'wLapseInfOnlyRun1';
            LoadOpt.Condition = 'inferenceOnly';

        elseif strcmp(Options.Plots, 'lapseModels')
            LoadOpt.ScheduleName = 'withLapsesRun1';
        else
            error('Bug')
        end
    
    elseif any(strcmp(Options.Plots, {'infOnlyCompare', 'twoLvlCompare'}))

        LoadOpt.Models = 'withLapsesMin';
        PltOptions.modelForSim = 'miscal-h-normative-lapse';

        if strcmp(Options.Plots, 'infOnlyCompare')
            LoadOpt.ScheduleName = 'run_locally';
            LoadOpt.Condition = 'inferenceOnly';
        elseif strcmp(Options.Plots, 'twoLvlCompare')
            LoadOpt.ScheduleName = 'run_locally';
            LoadOpt.Condition = 'fullTaskLab';
        else
            error('Bug')
        end
    else
        error('Bug')
    end

    if strcmp(LoadOpt.ScheduleName, 'run_locally')
        LoadOpt = rmfield(LoadOpt, 'ScheduleName');
        fitFile = fullfile(findDir(LoadOpt, 'step'), 'fittedDSet');
        LoadOpt.ScheduleName = 'run_locally';
        Loaded = load(fitFile);
        TrlDSet = Loaded.TrlDSet;
    else
        scheduleDir = fullfile(findDir(LoadOpt, 'step'), ...
            LoadOpt.ScheduleName);
    
        try
            % This will fail if the model fitting results have never been
            % loaded before
            [AllDSets, ~] = mT_analyseClusterResults(scheduleDir, ...
                1, true, false, true);
        catch
            % This will is slower but works whatever
            [AllDSets, ~] = mT_analyseClusterResults(scheduleDir, ...
                1, true, false, false);
        end
    
        assert(length(AllDSets) == 1)
        TrlDSet = AllDSets{1};
    end

    DSets.RealTrlDSet = TrlDSet;
    pltType = 'model';

    saveDataForExport(DSets.RealTrlDSet, plotSaveDir, PltOptions, ...
                        str2double(Options.numSimReps))
else
    error('Unknown option')
end

if strcmp(Options.Config, 'mainStudy')
    assert(~isfield(Options, 'numSimReps'))
    makeHamburgPlots(plotSaveDir, DSets, pltType, PltOptions)

elseif strcmp(Options.Config, 'coimbra')
    if strcmp(pltType, 'model')
        PltOptions.numSimReps = str2double(Options.numSimReps);
    elseif strcmp(pltType, 'real')
        assert(~isfield(Options, 'numSimReps'))
    else
        error('Bug')
    end
    makeCoimbraPlots(plotSaveDir, DSets, pltType, PltOptions)
end

end


function saveDataForExport(RealTrlDSet, saveDir, PltOptions, numSimReps)
% Save some data for transfer to colleagues

% INPUT
% RealTrlDSet: struct. Dataset at the level of trials for the real data.
% saveDir: str. Directory in which to save the results.
% PltOptions: struct. Contains the options that will be used for plotting.
%   Only used for consistency checks.
% numSimReps: integer as a sting. How many times to replicate the real 
%   dataset before simulating response and accuracy values.

modelForSim = 'miscal-h-normative-lapse';
assert(strcmp(modelForSim, PltOptions.modelForSim))

SimTrlDSet = simulateRespAndAccFromStim(RealTrlDSet, ...
    'fittedParams', modelForSim, RealTrlDSet, numSimReps);

RealTrlDSet = mT_removeFunctionHandles(RealTrlDSet, {});
save(fullfile(saveDir, 'RealTrlDSet_forExport'), 'RealTrlDSet')

SimTrlDSet = mT_removeFunctionHandles(SimTrlDSet, {});
save(fullfile(saveDir, ['SimTrlDSet_' modelForSim '_forExport']), ...
    'SimTrlDSet')

end








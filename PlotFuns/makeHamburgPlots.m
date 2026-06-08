function makeHamburgPlots(plotSaveDir, DSets, type, Options)
% Makes several plots

% INPUT
% plotSaveDir: string. Directory where plots should be saved
% DSets: struct. Keys are names of specific datasets and the values provide
%   those datasets in the standard format. The required keys depend on the
%   input 'type'. Possible keys are...
%       RealTrlDSet: Data in the standard format, that stores data at the
%           level of trials, for the real data, and that contains model
%           fitting results
%       OptTrlDSet: A dataset simulated using theoertically maximally
%           optimal behaviour. I.e. no internal sources of noise and
%           perfectly aligned parameters.
%       SimTrlDSet: A simulated entirely new dataset (i.e. not just new
%           responses but also new simulated stimuli), simulated based on
%           fitted parameter values from the dataset in RealTrlDSet.
%           Participants should match up in terms of order in RealTrlDSet.
%       SimRegDSet: The regression-results dataset produced by running
%           runRegressionAnalysis.m on the dataset given in SimTrlDSet.
% type: str. Which plots to make? Options are...
%   'real' for plots of the real data only. DSets should have RealTrlDSet
%       key.
%   'model' to use the fitted dataset to plot various information about
%       the model fitting and to simulate new responses (on the basis of
%       the real stimuli) for comparion with the real data. DSets should
%       have RealTrlDSet and OptTrlDSet keys.
%   'modelFullSim' to make plots similar to 'model' but based on the
%       entirely newly simulated dataset given by DSets.SimTrlDSet. DSets
%       should have RealTrlDSet, OptTrlDSet, SimTrlDSet and SimRegDSet keys.
% Options: struct. Empty struct to simply use defaults. Optional keys are:
%   ExtraIndividualPlots: bool. Default false. If true, makes some extra
%       plots on a individual participant basis.
%   SkipIce: bool. Default true. If true skip some plots of the effect of
%       ice.

% HISTORY
% 2021, JCT

%% Settings
modelForSim = 'miscal-h-b-normative';

if strcmp(type, 'real')
    expectData = {'RealTrlDSet'};
elseif strcmp(type, 'model')
    expectData = {'RealTrlDSet', 'OptTrlDSet'}';
elseif strcmp(type, 'modelFullSim')
    expectData = {'RealTrlDSet', 'OptTrlDSet', 'SimTrlDSet', ...
        'SimRegDSet'}';
else
    error('Unknown option')
end
if ~isequal(sort(fieldnames(DSets)), sort(expectData))
    error('Provided datasets and specified plots type do not match')
end

allOpts = {'ExtraIndividualPlots', 'SkipIce'};
defaults = {false, true};
assert(all(ismember(fieldnames(Options), allOpts)))

for iOpt = 1 : length(allOpts)
    thisOpt = allOpts{iOpt};
    
    if ~isfield(Options, thisOpt)
        Options.(thisOpt) = defaults{iOpt};
    end
end


%% Data locating/simulation

RealTrlDSet = DSets.RealTrlDSet;

if isfield(DSets, 'OptTrlDSet')
    OptTrlDSet = DSets.OptTrlDSet;
end

if strcmp(type, 'model')
    SimTrlDSet = simulateRespAndAccFromStim(RealTrlDSet, ...
        'fittedParams', modelForSim, RealTrlDSet);
    
elseif strcmp(type, 'modelFullSim')
    SimTrlDSet = DSets.SimTrlDSet;
    SimRegDSet = DSets.SimRegDSet;
end


%% Accuracy results

figHandle = plotInstInfPerform(RealTrlDSet);
mT_exportNicePdf(3.5, 3.5, plotSaveDir, ...
        'accuracy_across_conds_paper')

if strcmp(type, 'model')
    plotAveragePerformance(RealTrlDSet)
    mT_exportNicePdf(5, 5, plotSaveDir, ...
        'accuracy_in_inferred_accross_models_SMALL_SIM_paper')
end

if ~strcmp(type, 'real')
    blkTypes = {'inferred', 'instructed'};
    for iType = 1 : length(blkTypes)
        f = plotDetailedPerformance(RealTrlDSet, SimTrlDSet, OptTrlDSet, ...
            blkTypes{iType});

        if strcmp(blkTypes{iType}, 'inferred') && strcmp(type, ...
                'modelFullSim')
            addStr = '_paper';
        else
            addStr = '';
        end
        
        figure(f)
        mT_exportNicePdf(15.9/3.5, 15.9/3.2, plotSaveDir, ...
            ['accuracy_in_', blkTypes{iType}, addStr])
    end
end


%% Other key plots
if any(strcmp(type, {'model', 'modelFullSim'}))
    plotModelFitStats(RealTrlDSet, plotSaveDir, '')
    plotModelFitStats(RealTrlDSet, plotSaveDir, '_badModels', true, ...
        {'miscal-h-norm', 'normative', 'bound-acc', 'leaky-acc'}, [], ...
        [], [10, 5], false)
end

if strcmp(type, 'modelFullSim')
    plotModelFitStats(RealTrlDSet, plotSaveDir, '_goodModels_paper', ...
        true, {'last-sample', 'perfect-acc'}, 15, true, ...
        [10, 10], false)
end

EvDSets = struct();
EvDSets.RealTrlDSet = DSets.RealTrlDSet;
if any(strcmp(type, {'model', 'modelFullSim'}))
    EvDSets.SimTrlDSet = SimTrlDSet;
end
Figs = makeAllEvResidualPlots(plotSaveDir, EvDSets, Options);

if strcmp(type, 'modelFullSim')
    figure(Figs.Ev_resid_inferred)
    mT_exportNicePdf(4, 5, plotSaveDir, 'effectOfCues_inferred_paper')
end


RegDSets = struct();
RegDSets.RealTrlDSet = DSets.RealTrlDSet;
if any(strcmp(type, {'model', 'modelFullSim'}))
    RegDSets.SimTrlDSet = SimTrlDSet;
    
    if strcmp(type, 'modelFullSim')
        RegDSets.SimRegDSet = SimRegDSet;
    end
end
RegOpts = struct();
RegOpts.SkipIce = Options.SkipIce;
RegOpts.ModelForCompVars = modelForSim;
RegOpts.SigHeights = -0.05;
if strcmp(type, 'modelFullSim')
    RegOpts.CoreModelOnly = true;
end
Figs = makeAllRegPlots(plotSaveDir, RegDSets, RegOpts);

if strcmp(type, 'modelFullSim')
    figure(Figs.Regression)
    mT_exportNicePdf(15.9/1.55, 15.9/3, plotSaveDir, 'regression_paper')
end


%% Examine computational variables
if ~strcmp(type, 'real')
    exploreCompVars(RealTrlDSet, modelForSim)
end


end










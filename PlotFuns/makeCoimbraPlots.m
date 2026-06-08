function makeCoimbraPlots(plotSaveDir, DSets, type, Opts)
% Makes several plots

% INPUT
% plotSaveDir: string. Directory where plots should be saved
% DSets: struct. Keys are names of specific datasets and the values provide
%   those datasets in the standard format. The required keys depend on the
%   input type. Possible keys are...
%       RealTrlDSet: Data in the standard format, that stores data at the
%           level of trials, for the real data, and that contains model
%           fitting results
% type: str. Which plots to make? Options are...
%   'real' for plots of the real data only. DSets should have RealTrlDSet
%       key.
%   'model' to use the fitted dataset to plot various information about
%       the model fitting and to simulate new responses (on the basis of
%       the real stimuli) for comparion with the real data. DSets should
%       have RealTrlDSet key. DSets should have RealTrlDSet key.
% Opts: struct. Specifies details of plotting to perform. If type is 'real'
%   should be empty. If type is 'model', fields should be...
%       'modelForSim': Value of this field is a string, giving the name
%           of the model to simulate data for and to plot the model fits
%           and other quantities for.
%       'numSimReps': The number of times to replicate the real dataset 
%           before simulating new responses and accuracy values.


%% Setup
assert(any(strcmp(type, {'real', 'model'})))
assert(isequal(sort(fieldnames(DSets)), {'RealTrlDSet'}))
if strcmp(type, 'real')
    assert(isempty(fieldnames(Opts)))
elseif strcmp(type, 'model')
    assert(isequal(sort(fieldnames(Opts)'), ...
        sort({'modelForSim', 'numSimReps'})))
else
    error('Bug')
end

RealTrlDSet = DSets.RealTrlDSet;

if strcmp(type, 'model')
    SimTrlDSet = simulateRespAndAccFromStim(RealTrlDSet, ...
        'fittedParams', Opts.modelForSim, RealTrlDSet, Opts.numSimReps);
end


%% Standardised plotting routines

EvDSets = struct();
EvDSets.RealTrlDSet = DSets.RealTrlDSet;
if any(strcmp(type, {'model'}))
    EvDSets.SimTrlDSet = SimTrlDSet;
end
Options = struct();
Options.ExtraIndividualPlots = false;
Options.SkipIce = true;

makeAllEvResidualPlots(plotSaveDir, EvDSets, Options)


Options = struct();
Options.SkipIce = true;

RegDSets = struct();
RegDSets.RealTrlDSet = DSets.RealTrlDSet;
if strcmp(type, {'model'})
    RegDSets.SimTrlDSet = SimTrlDSet;
    Options.ModelForCompVars = Opts.modelForSim;
else
    assert(strcmp(type, 'real'))
end

makeAllRegPlots(plotSaveDir, RegDSets, Options)


%% Plots for this project
if strcmp(type, 'model')
    % Note: May want to update and use the functions plotAveragePerformance 
    % and plotDetailedPerformance
    
    appliedModels = mT_findAppliedModels(RealTrlDSet);
    disp(appliedModels)
    
    [~, restartsFigure] = mT_plotFitEndPoints(RealTrlDSet, false, 1);
    
    % Seperately by group
    [groups, ~, ~] = findGroupInfo(RealTrlDSet);
    expectGroups = {'older_adults', 'young_adults'};
    expectGroupNames = {'older adults', 'young adults'};
    assert(isequal(unique(groups), expectGroups'))
    
    for iG = 1 : length(expectGroups)
        TmpTrlDSet = RealTrlDSet;
        matches = strcmp(expectGroups{iG}, groups);
        assert(length(matches) == length(TmpTrlDSet.P))
        TmpTrlDSet.P = TmpTrlDSet.P(matches);
        plotModelFitStats(TmpTrlDSet, plotSaveDir, ['_', expectGroups{iG}])
    end
    
    % Parameters
    modelIdx = mT_findModelIdx(RealTrlDSet, Opts.modelForSim);
    paramsToPlot = fieldnames(...
        RealTrlDSet.P(1).Models(modelIdx).BestFit.Params);
    figure; subplot(length(paramsToPlot), 1, 1)
    
    pltNum = 1;
    for thisParam = paramsToPlot'
        theseVals = mT_stackData(RealTrlDSet.P, ...
            @(St) St.Models(modelIdx).BestFit.Params.(thisParam{1}));
        
        subplot(length(paramsToPlot), 1, pltNum); hold on
        title(thisParam{1})
        for thisGroup = expectGroups
            matches = strcmp(thisGroup, groups);
            assert(length(matches) == length(theseVals))
            edges = linspace(0, max(theseVals), 10);
            histogram(theseVals(matches), edges, 'Normalization', 'pdf')
        end
        legend(expectGroupNames)
        
        pltNum = pltNum +1;
    end
    
    mT_exportNicePdf(15.9, 15.9, plotSaveDir, ['params_by_age'])
    
    % Compute and simulate accuracy
    DForm = findDataFormat(RealTrlDSet);
    [AccTable.Group, ~, ~] = findGroupInfo(RealTrlDSet);
    AccTable.Acc_Real = computePerPtpntAcc(RealTrlDSet, ...
        DForm.AllInferenceBlks)';
    
    appliedModels = mT_findAppliedModels(RealTrlDSet);
    for iM = 1 : length(appliedModels)

        SimDSet = simulateRespAndAccFromStim(RealTrlDSet, ...
            'fittedParams', appliedModels{iM}, RealTrlDSet);
        accVals = computePerPtpntAcc(SimDSet, DForm.AllInferenceBlks);
        
        AccTable.(['Acc_' strrep(appliedModels{iM}, '-', '_')]) = accVals';
    end
    AccTable = struct2table(AccTable);
    save([plotSaveDir, 'AccTable'], 'AccTable')
end


%% Examine computational variables
if ~strcmp(type, 'real')
    exploreCompVars(RealTrlDSet, Opts.modelForSim)
end


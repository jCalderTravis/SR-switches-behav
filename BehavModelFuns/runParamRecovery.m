function DSet = runParamRecovery(simSaveDir, plotSaveDir, ...
    ModelSettings, basedOn, varargin)
% Simulate with the main model and see if we can recover the simulated
% parameters

% INPUT
% simSaveDir: string. Where to save the simulation results and temporary files. 
% Should have a trailing slash.
% plotSaveDir: string. Where to save the plots of the simulation results?
% ModelSettings: struct. Settings structure required for the 
%   mat-comp-model-tools repository, specifying the modelling settings.
% basedOn: str. "randParams" to simulate datasets using random 
%   parameters, or "fittedParams" to simulate datasets using fitted 
%   parameters. If use 'fittedParams' then need to provide varargin{1} 
%   and varargin{2}.
% varargin{1}: TrlDSet. If basedOn=='fittedParams', then the simulations 
%   are based on model fits in this dataset.
% varargin{2}: number. If basedOn=='fittedParams', then this input
%   determines the fitted model to use to set the parameter values. 
%   Set to match the model number as numbered in TrlDSet.P(iP).Model (for 
%   the TrlDSet given in varargin{1})
% varargin{3}: struct. Allows to customise the properties of the simulated
%   stimulus (e.g. number of trials). Is passed as the settings structure 
%   to runExperiment.m. See the comments on that function for the avalaible
%   options.

% HISTORY
% 2020-2022, JCT

assert(any(strcmp(basedOn, {'randParams', 'fittedParams'})))
error('The input and output of processSimVargs has changed')
[RealTrlDSet, modelForSim, ExtraSettings] = processSimVarargs(...
    basedOn, varargin);

error('The input of simulateDataSetWrapper has changed')
DSet = simulateDataSetWrapper(simSaveDir, basedOn, RealTrlDSet, ...
    modelForSim, ExtraSettings);

DSet = mT_scheduleFits('local', DSet, ModelSettings, '');
save(fullfile(simSaveDir, 'fittedSimulation'), 'DSet')

mT_plotParameterFits(DSet, 1, 'scatter', false, false)
mT_exportNicePdf(15.9, 15.9, plotSaveDir, 'paramRecovery')

[~, restartsFigure] = mT_plotFitEndPoints(DSet, false, 1);
figure(restartsFigure)
mT_exportNicePdf(15.9, 15.9, plotSaveDir, 'restartsRequired')

% Correlations
for iParam = 1 : length(ModelSettings.Params)
    paramName = ModelSettings.Params(iParam).Name;
    simVals = mT_stackData(DSet.P, @(st)st.Sim.Params.(paramName));
    fitVals = mT_stackData(DSet.P, @(st)st.Models(1).BestFit.Params.(paramName));
    corrVal = corr(simVals', fitVals');
    disp([paramName ': ' num2str(corrVal)])
end

end
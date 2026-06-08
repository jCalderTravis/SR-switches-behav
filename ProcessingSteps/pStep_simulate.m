function pStep_simulate(Options)
% Plot various things depending on settings

% INPUT
% Options: Struct. Has the following fields...
%   Config: See runMatlabStep.m
%   Step: See runMatlabStep.m
%   Type: str. Options are...
%       'theoryMax': Simulate a dataset where performance achieves the
%           theoretical maximum.
%       'fullFromFitted': Simulate a entirely new dataset, incuding stimui, 
%           with responses that are based on the model and fitted 
%           parameter values. 
%       'fullFromBaselineFitted': Same as 'fullFromFitted' but uses fits 
%           to only data from the baseline condition.

% LOADS 
% Save files from: pStep_collateData

resultsSaveDir = findDir(Options, 'step');
tmpSaveDir = [fullfile(resultsSaveDir, 'tempFiles') '/'];

if strcmp(Options.Type, 'theoryMax')
    TrlDSet = loadData(Options.Config, 'relative_time_real_data');

    ExtraSettings.TrialsPerBlock = 2000;
    SimMaxTrlDSet = simulateDataSetWrapper(tmpSaveDir, 'theoryMax', ...
        TrlDSet, [], ExtraSettings);

    fname = fullfile(resultsSaveDir, 'simTheoryMaxDSet');
    save(fname, 'SimMaxTrlDSet')
  
elseif any(strcmp(Options.Type, ...
        {'fullFromFitted', 'fullFromBaselineFitted'}))
    
    if strcmp(Options.Type, 'fullFromFitted')
        RealTrlDSet = loadData(Options.Config, 'fitted_data');
        iceMode = 'halfIce';
        
    elseif strcmp(Options.Type, 'fullFromBaselineFitted')
        RealTrlDSet = loadData(Options.Config, 'fitted_baseline_data');
        iceMode = 'noIce';
        
    else
        error('Bug')
    end
    
    ExtraSettings.TrialsPerBlock = 340;
    simModel = 'miscal-h-b-normative';
    SimTrlDSet = simulateDataSetWrapper(tmpSaveDir, 'fittedParams', ...
        RealTrlDSet, simModel, ExtraSettings, iceMode);
    
    % Also run the regression analysis and save the results (can take 
    % quite a bit of time to better to do once, here, than multiple times)
    SimRegDSet = runRegressionAnalysis(SimTrlDSet);
    
    fname = fullfile(resultsSaveDir, 'fullSimFromFittedDSet');
    save(fname, 'SimTrlDSet', 'SimRegDSet')
else
    error('Unknown option')
end
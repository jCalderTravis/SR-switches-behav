function fitAndEvalModel(TrlDSet, ModelSettings, resultsSaveDir, plotSaveDir)
% Run model fitting an make various plots

% INPUT
% TrlDSet: The trial-by-trial dataset in standard format. Produced by
%   loadAllPtpntData.m
% ModelSettings: struct. Settings structure required for the 
%   mat-comp-model-tools repository, specifying the modelling settings.
% resultsSaveDir: string. Where to save the fitting results and temporary files. 
%   Provide a different directory to that use for other fits, or results will
%   be overwritten.
% plotSaveDir: string. Where to save the plots of the simulation results?
%   Again provide a different directory to that use for other fits.

% HISTORY
% 2021, JCT
% 21.02.2023 Read through, including called functions
% 09.06.2023 Checked for Coimbra

TrlDSet = mT_scheduleFits('local', TrlDSet, ModelSettings, '');
save(fullfile(resultsSaveDir, 'fittedDSet'), 'TrlDSet')

mT_plotParameterFits(TrlDSet, 1, 'hist', false, false)
mT_exportNicePdf(15.9, 15.9, plotSaveDir, 'paramDistributions')

[~, restartsFigure] = mT_plotFitEndPoints(TrlDSet, false, 1);
figure(restartsFigure)
mT_exportNicePdf(15.9, 15.9, plotSaveDir, 'restartsRequired')


% Take a closer look at some of the paramters from different runs
for iP = 1 : length(TrlDSet.P)
    if isfield(TrlDSet.P(1).Models(1).Fits(1).Params, 'ObserverH')
        observerH = mT_stackData(TrlDSet.P(iP).Models(1).Fits, ...
            @(st) st.Params.ObserverH);
    end

    if isfield(TrlDSet.P(1).Models(1).Fits(1).Params, 'ObserverBeta')
        observerBeta = mT_stackData(TrlDSet.P(iP).Models(1).Fits, ...
            @(st) st.Params.ObserverBeta);

        figure()
        scatter(observerH, observerBeta)
        xlabel('observerH')
        ylabel('observerBeta')
    end

    if isfield(TrlDSet.P(1).Models(1).Fits(1).Params, 'DecisionNoiseSigma')
        decisionNoise = mT_stackData(TrlDSet.P(iP).Models(1).Fits, ...
            @(st) st.Params.DecisionNoiseSigma);

        figure()
        histogram(decisionNoise)
        title('decisionNoise')
    end
end


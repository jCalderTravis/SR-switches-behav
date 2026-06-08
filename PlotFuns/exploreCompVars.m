function exploreCompVars(RealTrlDSet, modelForSim)
% Examine computational variables and their relations

warning(['Function and subfunctions not carefully checked. Especially not whether it ', ...
    'is valid for both datasets.'])

modelNumForSim = modelNameToNum(RealTrlDSet, modelForSim);
fittedParams = mT_findFittedParams(RealTrlDSet, modelNumForSim);

for iP = 1 : length(RealTrlDSet.P)
    ThisData = RealTrlDSet.P(iP).Data;
    checkDataOrdering(ThisData)
    ThisKeyVars = computeKeyModelVariables(fittedParams{iP}, ThisData);
    
    llr = flattenCell(ThisKeyVars.CueLLR);
    lpr = flattenCell(ThisKeyVars.AfterCueLPR);
    cpp = flattenCell(ThisKeyVars.AfterCueCPP);
    uncert = flattenCell(ThisKeyVars.PreCueUncert);
    
    names = {'LLR', 'LPR', 'CPP', 'CPP*LLR', 'Uncert', 'Uncert*LLR'};
    toPlot = [llr, lpr, cpp, cpp.*llr, uncert, uncert.*llr];
    figure;
    [~, Axs] = plotmatrix(toPlot);
    for iN = 1 : length(names)
        xlabel(Axs(length(names), iN), names{iN});
        ylabel(Axs(iN, 1), names{iN});
    end

    mT_exportNicePdf(15.9, 15.9, plotSaveDir, ...
        ['comp_var_correlation_P', ...
            num2str(RealTrlDSet.P(iP).Spec.PtpntID)])
end

exploreSubsetCompVars(RealTrlDSet, modelForSim)

end


function exploreSubsetCompVars(TrlDSet, modelForParams)
% Some exporation of the features of the computational variables

ParamStruct = computeTrueParams(TrlDSet);
ThisData = TrlDSet.P(1).Data;
exploreForOneParams(ParamStruct, ThisData);

modelNum = modelNameToNum(TrlDSet, modelForParams);
observerH = mT_stackData(TrlDSet.P, ...
    @(st) st.Models(modelNum).BestFit.Params.ObserverH);
observerBeta = mT_stackData(TrlDSet.P, ...
    @(st) st.Models(modelNum).BestFit.Params.ObserverBeta);

disp('ObserverH')
disp('Mean')
disp(mean(observerH))
disp('Min')
disp(min(observerH))
disp('Max')
disp(max(observerH))

disp('ObserverBeta')
disp('Mean')
disp(mean(observerBeta))
disp('Min')
disp(min(observerBeta))
disp('Max')
disp(max(observerBeta))

end


function exploreForOneParams(ParamStruct, ThisData)

ThisKeyVars = computeKeyModelVariables(ParamStruct, ThisData);

DForm = findDataFormat(ThisData);
infTrls = ismember(ThisData.BlockType, DForm.AllInferenceBlks);

cueLoc = flattenCell(ThisKeyVars.CueLoc(infTrls));
llr = flattenCell(ThisKeyVars.CueLLR(infTrls));
lpr = flattenCell(ThisKeyVars.AfterCueLPR(infTrls));
corrVal = corrcoef(llr, lpr);
disp('Correlation')
corrVal(1, 2)
figure; scatter(llr, lpr);
figure; hist3([llr, lpr], 'CdataMode', 'auto')
view(2)
colorbar
xlabel('LLR')
ylabel('LPR')


disp('Mean abs cueLoc')
disp(mean(abs(cueLoc)))

disp('Mean LLR')
disp(mean(abs(llr)))

figure; histogram(cueLoc);
figure; histogram(llr);
figure; histogram(lpr);

figure
subplot(2, 3, 1)
plotNextLPriorR(ThisKeyVars, false, 1)
plotNextLPriorR(ThisKeyVars, true, 4)

end


function plotNextLPriorR(ThisKeyVars, regOutLLR, startSubplot)
% Make various plots of the relation between next log-prior ratio (the 
% log-prior ratio that will be combined with the next LLR) and other
% variables.

% INPUT
% regOutLLR: bool. If true, regress out the effect of LLR on next log-prior
%   ratio.
% scalar: The number of the subplot to start plotting onto.

llr = flattenCell(ThisKeyVars.CueLLR);
lpr = flattenCell(ThisKeyVars.AfterCueLPR);
LPriorR = flattenCell(ThisKeyVars.PreCueLPriorR);
lpr = lpr(1:end-1);
nextLlr = llr(2:end);
llr = llr(1:end-1);
nextLPriorR = LPriorR(2:end);
excCase = isnan(lpr) | isnan(nextLPriorR) | (nextLPriorR == 0);
if regOutLLR
    p = polyfit(llr(~excCase), nextLPriorR(~excCase), 1);
    nextLPriorR = nextLPriorR - polyval(p, llr);
    nextLPriorR(excCase) = nan;
    ytext = {'Next log-prior ratio', 'LLR regressed out'};
    disp('=== WITH REGRESSION ===')
else
    ytext = 'Next log-prior ratio';
    disp('=== WITHOUT REGRESSION ===')
end

subplot(2, 3, startSubplot)
scatter(lpr(~excCase), nextLPriorR(~excCase));
xlabel('LPR')
ylabel(ytext)
thisCorr = corrcoef(lpr(~excCase), nextLPriorR(~excCase));
disp(['LPR -- nextLPriorR' num2str(thisCorr(2, 1))])

subplot(2, 3, startSubplot+1)
scatter(llr(~excCase), nextLPriorR(~excCase));
xlabel('LLR')
ylabel(ytext)
thisCorr = corrcoef(llr(~excCase), nextLPriorR(~excCase));
disp(['LLR -- nextLPriorR' num2str(thisCorr(2, 1))])

subplot(2, 3, startSubplot+2)
scatter(nextLlr(~excCase), nextLPriorR(~excCase));
xlabel('Next LLR')
ylabel(ytext)
thisCorr = corrcoef(nextLlr(~excCase), nextLPriorR(~excCase));
disp(['nextLPR -- nextLPriorR' num2str(thisCorr(2, 1))])

end







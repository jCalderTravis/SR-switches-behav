function ParamStruct = computeTrueParams(TrlDSet)
% Compute the values of ObserverBeta, and ObserverH such that they match
% the true values of the parameters Beta and H.

% INPUT
% TrlDSet. Standard format dataset. Key properties of the stimulus are 
% extracted from TrlDSet and used to compute the optimal parameters.

% HISTORY
% 2021, JCT
% 10.05.2023 Updated for Coimbra data

ParamStruct.ObserverBeta = computeOptimalBeta(TrlDSet.Spec); 
    
for iP = 1 : length(TrlDSet.P)
    ThisData = TrlDSet.P(iP).Data;
    hazardRate = findTrueHazardRateInInferred(ThisData);
    
    if iP == 1
        ParamStruct.ObserverH = hazardRate;
    else
        if ParamStruct.ObserverH ~= hazardRate
            error(['Hazard rate not consistent accross participants. '...
                'Code needs changing.'])
        end
    end
end
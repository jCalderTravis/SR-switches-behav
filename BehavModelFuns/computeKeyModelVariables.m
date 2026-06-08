function KeyVars = computeKeyModelVariables(ParamStruct, Data)
% Compute key model variables such as log-posterior ratio, change point
% probability, and uncertainty, for trials in the inferred condition

% INPUT
% ParamStruct: The standard parameter structure with a field for each set
%   of parameters.
% Data: A part of the standard trial-based dataset structure for one 
%   participant. Specifically, if we are interested in participant i, 
%   then Data = DSet.P(i).Data. Data need to be ordered, both in terms of
%   session, blocks within sessions, and trials within blocks.

% OUTPUT
% KeyVars: A structure with the following fields... 
%   'CueLoc' (the cue location that is already stored in Data, but useful 
%       for checks/debugging), 
%   'TrialEndLPR' (log-posterior ratio at the end of each trial as a column 
%       vector)
%   'AfterCueLPR' (cell array as long as the number of trials, with each 
%       element containing the log-posterior ratio after each cue in that 
%       trial)
%   'CueLLR' (same as 'AfterCueLPR' but for log-likelihood ratio)
%   'AfterCueCPP' (same as 'AfterCueLPR' but for change point probability),
%   'PreCueUncert' (same as 'AfterCueLPR' but for uncertainty before each 
%       cue)
%   'PreCueLPriorR' (log-prior ratio before the presentation of the cue.
%       I.e. the LLR of the current cue will be added to this.)

% HISTORY
% 2021, JCT
% 23.02.2023 Read through, including called functions
% 09.06.2023 Updated for Coimbra data

DForm = findDataFormat([]);

LPR_prev = 0;
KeyVars.TrialEndLPR = nan(length(Data.BlockNum), 1);
KeyVars.CueLoc = cell(length(Data.BlockNum), 1);
KeyVars.CueLLR = cell(length(Data.BlockNum), 1);
KeyVars.AfterCueLPR = cell(length(Data.BlockNum), 1);
KeyVars.AfterCueCPP = cell(length(Data.BlockNum), 1);
KeyVars.PreCueUncert = cell(length(Data.BlockNum), 1);
KeyVars.PreCueLPriorR = cell(length(Data.BlockNum), 1);
currBlock = 0;
currSess = 0;

for iT = 1 : length(Data.BlockNum)

    KeyVars.CueLoc{iT} = nan(length(Data.CueLoc{iT}), 1);
    KeyVars.CueLLR{iT} = nan(length(Data.CueLoc{iT}), 1);
    KeyVars.AfterCueLPR{iT} = nan(length(Data.CueLoc{iT}), 1);
    KeyVars.AfterCueCPP{iT} = nan(length(Data.CueLoc{iT}), 1);
    KeyVars.PreCueUncert{iT} = nan(length(Data.CueLoc{iT}), 1);
    KeyVars.PreCueLPriorR{iT} = nan(length(Data.CueLoc{iT}), 1);

    if any(strcmp(Data.BlockType(iT), DForm.AllInferenceBlks))
        
        % Do we need to reset due to new block?
        isNewBlock = findIfNewBlock(Data, currBlock, currSess, iT);
        if isNewBlock
            LPR_prev = 0;
        end
        
        for iC = 1 : length(Data.CueLoc{iT})
            % Update LPR
            hTerm = (1 - ParamStruct.ObserverH) / ParamStruct.ObserverH;
            checkNotNan(hTerm)
            
            Phi = computePhi(LPR_prev, ParamStruct.ObserverH);
            checkNotNan(Phi)
            
            LLR = ParamStruct.ObserverBeta * Data.CueLoc{iT}(iC);
            checkNotNan(LLR)
            
            LPR_new = LLR + Phi;
            if LPR_new == Inf
                error('Bug')
            end
            checkNotNan(LPR_new)
            
            % Compute additional variable of interest
            KeyVars.CueLoc{iT}(iC) = Data.CueLoc{iT}(iC);
            KeyVars.CueLLR{iT}(iC) = LLR;
            KeyVars.AfterCueLPR{iT}(iC) = LPR_new;
            KeyVars.PreCueUncert{iT}(iC) = -abs(Phi);
            KeyVars.PreCueLPriorR{iT}(iC) = Phi;
            coshTerm1 = cosh((LLR + LPR_prev)/2);
            coshTerm2 = cosh((LLR - LPR_prev)/2);
            KeyVars.AfterCueCPP{iT}(iC) ...
                = 1 ./ (1 + (hTerm .* (coshTerm1 ./ coshTerm2)));
            
            % Get ready for the next cue
            LPR_prev = LPR_new;
            checkNotNan(LPR_prev)
        end
        
        KeyVars.TrialEndLPR(iT) = LPR_new;
        checkNotNan(KeyVars.TrialEndLPR(iT))
    
    elseif strcmp(Data.BlockType(iT), 'instructed')
        assert(size(Data.CueLoc{iT}, 2) == 1)
        KeyVars.CueLoc{iT} = Data.CueLoc{iT};
    else
        error('Bug')
    end
    
    currBlock = Data.BlockNum(iT);
    currSess = Data.SessionNum(iT);
end

end

function checkNotNan(var)
if any(isnan(var))
    error('Bug')
end
end





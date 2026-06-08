function SimDSet = simulateRespAndAccFromStim(TrlDSet, basedOn, ...
    modelName, varargin)
% Simulates a response and accuracy using the stimulus shown on each trial 
% in the 'inferred' condition, and overwrites these in TrlDSet. For the 
% 'instructed' condition nothing else is simulated.

% INPUT
% TrlDSet: Dataset in the standard format, that stores data at the level of
%   trials, to which simulated data will be added.
% basedOn: string. Simulate based on randomly picked values ('randParams'), 
%   simulated based on fitted parameter values ('fittedParams'). Pass
%   'noParams' if there are no free parameters of the model.
% modelName: str. The name of the model to simulate with.
% varargin{1}: FitsTrlDSet. If basedOn=='fittedParams', then the 
%   simulations are based on model fits in this dataset. Specifically, 
%   the parameters for participant i in FitsTrlDSet will be used to 
%   simulate the responses of participant i in TrlDSet. Therefore, must
%   have the same number of participants in each.
% vararing{2}: positive integer. If provided the dataset is replicated this
%   many times before simulations are perfromed. E.g. if this value is 3,
%   the dataset will be replicated 3 times, and 3 independent simulations
%   will be performed for each trial.

% HISTORY
% 09.2023 Updated for Coimbra data

if (~isempty(varargin)) && (~isempty(varargin{1}))
    FitsTrlDSet = varargin{1};
    assert(strcmp(basedOn, 'fittedParams'))
    assert(length(TrlDSet.P) == length(FitsTrlDSet.P))
else
    assert(any(strcmp(basedOn, {'randParams', 'noParams'})))
end

if (length(varargin)>1) && (~isempty(varargin{2}))
    repFactor = varargin{2};
else
    repFactor = 1;
end

DForm = findDataFormat(TrlDSet);
TrlDSet = replicateData(TrlDSet, repFactor);

SimDSet = TrlDSet;
SimDSet.SimSpec.Name = modelName;
if isfield(SimDSet.P, 'Models')
    SimDSet.P = rmfield(SimDSet.P, 'Models');
end
for iP = 1 : length(SimDSet.P)
    SimDSet.P(iP).Data = rmfield(SimDSet.P(iP).Data, DForm.IsRespA);
    SimDSet.P(iP).Data = rmfield(SimDSet.P(iP).Data, 'Acc');
end

for iP = 1 : length(SimDSet.P)
    
    % What parameters to use?
    if strcmp(basedOn, 'randParams')
        if ~strcmp(modelName, 'miscal-h-b-normative')
            error('Not coded up yet.')
        end
        
        % Randomly assign some parameters to simulate with
        ParamStruct.ObserverH = 0.01 + (rand(1)*0.2);
        ParamStruct.ObserverBeta = 0.6 + (rand(1)*40);
        ParamStruct.DecisionNoiseSigma = 0.05 + (rand(1)*2);
        
    elseif strcmp(basedOn, 'fittedParams')
        modelIdx = mT_findModelIdx(FitsTrlDSet, modelName);
        ParamStruct = FitsTrlDSet.P(iP).Models(modelIdx).BestFit.Params;
        
    elseif strcmp(basedOn, 'noParams')
        ParamStruct = struct();
    else
        error('Unknown input option')
    end
    SimDSet.P(iP).Sim.Params = ParamStruct;
    
    TmpData = TrlDSet.P(iP).Data;
    TmpData.(DForm.IsRespA) ...
        = true([length(TrlDSet.P(iP).Data.(DForm.IsRespA)), 1]);
    
    % Determine the probability of each response
    probRespA = exp(sR_computeTrialLL(modelName, ParamStruct, ...
        TmpData, SimDSet.Spec));
    
    % Checks
    inferredTrials = ismember(TmpData.BlockType, DForm.AllInferenceBlks);
    instructedTrials = strcmp(TmpData.BlockType, 'instructed');
    assert((sum(inferredTrials) + sum(instructedTrials)) ...
        == length(TmpData.BlockType))
    assert(all(probRespA >= 0))
    assert(all(probRespA <= 1))

    % Draw a response according to this probability
    respA = rand([length(TrlDSet.P(iP).Data.(DForm.IsRespA)), 1]) ...
        < probRespA;
    respA = double(respA);
    
    SimDSet.P(iP).Data.(DForm.IsRespA) = respA;
    SimDSet.P(iP).Data.Acc = nan(size(respA));

    % Determine accuracy
    for iT = 1 : length(SimDSet.P(iP).Data.(DForm.IsRespA))
        thisBlkType = SimDSet.P(iP).Data.BlockType(iT);
        
        if ismember(thisBlkType, DForm.AllTwoLevelBlks)

            % Was the response correct? Find our case in the lookup table
            allCases = findAccTable();
            isRuleA = SimDSet.P(iP).Data.(DForm.IsRuleAForTrial)(iT);
            isStimA = SimDSet.P(iP).Data.(DForm.IsStimA)(iT);
            isRespA = SimDSet.P(iP).Data.(DForm.IsRespA)(iT);
            thisCase = [isRuleA, isStimA, isRespA];
            
            matchesCase = ismember(allCases(:, 1:3), thisCase, 'rows');
            assert(length(matchesCase) == 8)
            if sum(matchesCase) ~= 1; error('Bug'); end
            
            SimDSet.P(iP).Data.Acc(iT, 1) = allCases(matchesCase, 4);
        
        elseif ismember(thisBlkType, 'inference-only')
            thisAcc = SimDSet.P(iP).Data.(DForm.IsRespA)(iT) ...
                == SimDSet.P(iP).Data.DistIsUpperForTrial(iT);
            SimDSet.P(iP).Data.Acc(iT, 1) = double(thisAcc);
        else
            error('Bug')
        end
    end
    
    assert(all(ismember(SimDSet.P(iP).Data.(DForm.IsRespA), [0, 1])))
    assert(all(ismember(SimDSet.P(iP).Data.Acc, [0, 1])))
end




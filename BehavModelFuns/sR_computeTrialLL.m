function trialLL = sR_computeTrialLL(modelName, ParamStruct, Data, ...
    DSetSpec)
% Compute log-posterior ratio (LPR) inferred by the participant after the
% presentation of each cue, and at the end of each trial

% HISTORY
% 2020-2021, JCT
% 23.02.2023 Read through, including called functions
% 03.07.2023 Updated for Coimbra data

expectedParams = findIncParams(modelName);
assert(isequal(expectedParams, fieldnames(ParamStruct)))

DForm = findDataFormat(Data);
totTrials = length(Data.BlockNum);

if isVariant(modelName, {'miscal-h-b-normative'})
    KeyVars = computeKeyModelVariables(ParamStruct, Data);
    decisionVar = KeyVars.TrialEndLPR;

elseif isVariant(modelName, {'miscal-h-normative'})  
    ParamStruct.ObserverBeta = computeOptimalBeta(DSetSpec);
    KeyVars = computeKeyModelVariables(ParamStruct, Data);
    decisionVar = KeyVars.TrialEndLPR;
    
elseif isVariant(modelName, {'normative', 'normative-no-noise'})
    ParamStruct.ObserverBeta = computeOptimalBeta(DSetSpec);
    ParamStruct.ObserverH = findTrueHazardRateInInferred(Data);
    if strcmp(modelName, 'normative-no-noise')  
        ParamStruct.DecisionNoiseSigma = 0;
    end
    
    KeyVars = computeKeyModelVariables(ParamStruct, Data);
    decisionVar = KeyVars.TrialEndLPR;
    
elseif isVariant(modelName, {'last-sample'})
    decisionVar = findLastSample(Data);
    
elseif isVariant(modelName, {'perfect-acc'})
    decisionVar = findCueLocAccumulation(Data);
    
elseif isVariant(modelName, {'bound-acc'})
    decisionVar = findCueLocAccumulation(Data, ParamStruct.AccumBound);
    
elseif isVariant(modelName, {'leaky-acc'})
    decisionVar = findCueLocAccumulation(Data, Inf, ParamStruct.AccumLeak);
else
    error('Unknown model')
end

assert(isequal(size(decisionVar), [totTrials, 1]))
probUseRuleA = nan(totTrials, 1);
probRespA = nan(totTrials, 1);
probResp = nan(totTrials, 1);
assert(all(ismember(Data.BlockType, DForm.AllPermittedBlks)))


%% Two-level task blocks
% Instructed blocks
instructedBlocks = ismember(Data.BlockType, 'instructed');
lastSamp = findLastSample(Data);
assert(~any(isnan(lastSamp)))
lastSampSupportsA = lastSamp > 0;
probUseRuleA(instructedBlocks & lastSampSupportsA) = 1; 
probUseRuleA(instructedBlocks & (~lastSampSupportsA)) = 0; 

assert(all(isnan(probUseRuleA(~instructedBlocks))))
assert(~any(isnan(probUseRuleA(instructedBlocks))))

% Full task inference blocks
fullTaskInferBlocks = ismember(Data.BlockType, DForm.FullTaskInferBlks);
probUseRuleA(fullTaskInferBlocks) ...
    = 1 - normcdf(0, decisionVar(fullTaskInferBlocks), ...
        ParamStruct.DecisionNoiseSigma);

% Determine probability observer responds A
twoLvlBlks = ismember(Data.BlockType, DForm.AllTwoLevelBlks);
assert(isequal(sort(DForm.AllTwoLevelBlks), ...
    sort([DForm.FullTaskInferBlks, {'instructed'}])))

% Datasets with inference only blocks may contain nan values for stimulus.
% Hence, have to treat carefully.
isStimA_withNan = Data.(DForm.IsStimA);
uniqueStims = unique(isStimA_withNan(~isnan(isStimA_withNan)));
if sum(twoLvlBlks) == 0
    assert(isempty(uniqueStims))
else
    assert(isequal(uniqueStims, [0, 1]'))
end
isStimA = isStimA_withNan == 1;
isStimB = isStimA_withNan == 0;
assert(isequal(isStimA | isStimB, ~isnan(isStimA_withNan)))

isBlkAndStimA = isStimA & twoLvlBlks;
isBlkAndNotStimA = isStimB & twoLvlBlks;

probRespA(isBlkAndStimA) = probUseRuleA(isBlkAndStimA);
probRespA(isBlkAndNotStimA) = 1 - probUseRuleA(isBlkAndNotStimA);

assert(all(isnan(probRespA(~twoLvlBlks))))
assert(~any(isnan(probRespA(twoLvlBlks))))


%% Inference only blocks
% Determine probability observer responds A
infOnlyBlocks = ismember(Data.BlockType, 'inference-only');
probRespA(infOnlyBlocks) ...
    = 1 - normcdf(0, decisionVar(infOnlyBlocks), ...
        ParamStruct.DecisionNoiseSigma);

assert(~any(isnan(probRespA)))


%% All blocks

% Lapse
noLapseModels = { ...
    'miscal-h-b-normative', ...
    'miscal-h-normative', ...
    'normative', ...
    'normative-no-noise', ...
    'last-sample', ...
    'perfect-acc', ...
    'bound-acc', ...
    'leaky-acc', ...
    };
lapseModels = {
    'miscal-h-b-normative-lapse', ...
    'miscal-h-normative-lapse', ...
    'normative-lapse', ...
    'last-sample-lapse', ...
    'perfect-acc-lapse', ...
    'bound-acc-lapse', ...
    'leaky-acc-lapse', ...
    };
if ismember(modelName, noLapseModels)
    assert(~isfield(ParamStruct, 'LapseRate'))
    ParamStruct.LapseRate = 0;

elseif ismember(modelName, lapseModels)
    assert(isfield(ParamStruct, 'LapseRate'))
else
    error('Unrecognised model')
end

probRespA = (ParamStruct.LapseRate * 0.5) + ...
    ((1 - ParamStruct.LapseRate) * probRespA);

% Determine the probability of the observered response
isRespA = Data.(DForm.IsRespA);
uniqueResps = unique(isRespA(~isnan(isRespA)));
posResps = [0; 1];
assert(all(ismember(uniqueResps, posResps)))

probResp(isRespA == 1) = probRespA(isRespA == 1);
probResp(isRespA == 0) = 1 - probRespA(isRespA == 0);

assert(~any(isnan(probResp(logical(Data.RtIsValid)))))
trialLL = log(probResp);

assert(all(trialLL(logical(Data.RtIsValid)) <= 0))

end


function isIn = isVariant(thisModel, setOfPermitted)

alsoPermitted = cell(length(setOfPermitted), 1);
for iPer = 1 : length(setOfPermitted)
    alsoPermitted{iPer} = [setOfPermitted{iPer}, '-lapse'];
end

allPermitted = [setOfPermitted(:); alsoPermitted(:)];
assert(size(allPermitted, 2) == 1)
isIn = any(strcmp(thisModel, allPermitted));

end




        
        
function [Preds, cueNumRelResp, outcomeVector, iceUsed] = ...
    computeIndividualPredMatricies(ThisData, ParamStruct, cuesToConsider, ...
    zscorePreds, binSize)
% Compute key model variables, and then reorganise these into various
% helpful matricies of predictors, and the outcome.

% INPUT
% ThisData: A part of the dataset in standard format, that stores data at 
%   the level of trials. Specifically, TrlDSet.P(i).Data for one 
%   participant.
% ParamStruct: What parameters should be used for estimating the key
%   variables of the compuational model, that will become the predictor
%   variables?
% cuesToConsider: Predictors are made up of cues in the run up to a
%   decision. How many cues prior to a decision should we consider?
% zscorePreds: Boolean. If true predictors are z-scored seperately for each
%   predictor, and for each cue position (i.e. sperately for the cues
%   3 cues prior to response, 2 cues prior to response, 1 cue prior...).
%   Note this is conducted after any binning requested using the 'binSize'
%   input. Only the variables in Preds are z-scored, not outcomeVector, or 
%   iceUsed.
% binSize: integer. If 1 has no effect. Otherwise must be a scalar that 
%   cuesToConsider is divisible by. Predictor data will be binned on the 
%   basis of cue number relative to decision, and treated as if all 
%   cases in each bin are from the same cue number relative to the
%   decision as the bin point of the bin.

% OUTPUT
% Preds: Structure with the following fields: 'LLR', 'CPP', 'Uncert', and
%   'SCP' (subsequent change probability). Each field contains a matrix 
%   of shape [num cases X (cuesToConsider/binSize)], describing the value 
%   of each named varaible, in the cues leading up to response. Note that 
%   SCP for the final cue is always zero (prior to z-scoring).
% cueNumRelResp: columns vector as a long as cuesToConisder/binSize. 
%   Describes the cue number relative to the response, for which each 
%   column of data in each of the fields of Preds corresponds.
% outcomeVector: column vector describing the rule actually used by the 
%   observer in each trial (i.e. each case) of the two-level inference
%   task, or describing the response made in each trial of the inference
%   only task (i.e. the task with no additional context-dependent 
%   stimulus-response mapping task). Signs are such that, regardless of the
%   trial type, possitive LLR supports a positive outcome vector. It will
%   be as long as the number of included responses X binSize.
% iceUsed: A [num cases X 1] column vector describing whether ice
%   water was used

% HISTORY
% 2021, JCT
% 10.10.2023 Updated for Coimbra data

DForm = findDataFormat(ThisData);

% For this we will assume the data are in order
checkDataOrdering(ThisData)

KeyVars = computeKeyModelVariables(ParamStruct, ThisData);
cueNumRelResp = [-cuesToConsider : -1]';

% Second step, put the key variables into correctly shaped matricies, and 
% store the associated outcomes
% Aim: trials x (cuesToConsider/numBins) predictor matrix for each 
% predictor, and a trials x 1 outcome column vector
totalCues = sum(cellfun(@length, ThisData.CueLoc));
cueLLR = nan(totalCues, 1);
afterCueCPP = nan(totalCues, 1);
preCueUncert = nan(totalCues, 1);
blockNum = nan(totalCues, 1);
sessNum = nan(totalCues, 1);

totalCueCount = 0;
caseCount = 0;
trialIncluded = false(length(ThisData.BlockNum), 1);

for iT = 1 : length(ThisData.BlockNum)
    
    % Progress report
    if mod(iT, round(length(ThisData.BlockNum)/10)) == 0
        disp(['Regression prep (for one pariticipant): ' ...
            num2str(100*round(iT / length(ThisData.BlockNum), 2)) ...
            '% complete.'])
    end
    
    if any(strcmp(ThisData.BlockType(iT), DForm.AllInferenceBlks))
        for iC = 1 : length(ThisData.CueLoc{iT})
            
            totalCueCount = totalCueCount +1;
            
            % Store data about this cue
            cueLLR(totalCueCount) = KeyVars.CueLLR{iT}(iC);
            afterCueCPP(totalCueCount) = KeyVars.AfterCueCPP{iT}(iC);
            preCueUncert(totalCueCount) ...
                = KeyVars.PreCueUncert{iT}(iC);
            blockNum(totalCueCount) = ThisData.BlockNum(iT);
            sessNum(totalCueCount) = ThisData.SessionNum(iT);
            
            
            % If this is the final cue of a trial, consider it for
            % inclusion as a case in the regression
            if iC == length(ThisData.CueLoc{iT})
                
                finalIdx = totalCueCount;
                firstIdx = finalIdx - cuesToConsider +1;
                
                % Are there enough cues in this block to include this case
                % in the predictor matrix? And is this even a valid trial?
                if ~ThisData.RtIsValid(iT)
                    enough = false;
                elseif firstIdx <= 0
                    enough = false;
                else
                    % Find the data associated with the most recent cues
                    theseBlockNums = blockNum(firstIdx : finalIdx);
                    theseBlockNums = unique(theseBlockNums);
                    theseSessNums = sessNum(firstIdx : finalIdx);
                    theseSessNums = unique(theseSessNums);
                    
                    if (length(theseBlockNums) == 1) ...
                            && (length(theseSessNums) == 1)
                        enough = true;
                    elseif (length(theseBlockNums) < 1) ...
                            || (length(theseSessNums) < 1)
                        error('Bug')
                    else
                        enough = false;
                    end
                end
                
                if enough
                    caseCount = caseCount +1;
                    Preds.LLR(caseCount, :) = ...
                        cueLLR(firstIdx : finalIdx)';
                    Preds.CPP(caseCount, :) = ...
                        afterCueCPP(firstIdx : finalIdx)';
                    Preds.Uncert(caseCount, :) = ...
                        preCueUncert(firstIdx : finalIdx)';
                    Preds.SCP(caseCount, :) = ...
                        computeScp(afterCueCPP(firstIdx : finalIdx));
                    
                    iceUsed(caseCount, 1) = ThisData.WasIceSess(iT);
                    
                    if any(strcmp(ThisData.BlockType(iT), ...
                            DForm.FullTaskInferBlks))
                        outcomeVector(caseCount, 1) ...
                            = ThisData.(DForm.UsedRuleA)(iT);
                        
                    elseif strcmp(ThisData.BlockType(iT), ...
                            'inference-only')
                       outcomeVector(caseCount, 1) ...
                            = ThisData.(DForm.IsRespA)(iT);
                    else
                        error('Bug')
                    end
                    
                    if trialIncluded(iT)
                        error(['Bug: This trial was about to ', ...
                            'be double counted.'])
                    end
                    trialIncluded(iT) = true;
                end
            end
        end
    end
end

% Checks
isInferred = ismember(ThisData.BlockType, DForm.AllInferenceBlks);
assert(~any((~isInferred) & trialIncluded))
disp('Proportion of inference trials included in regression:')
disp(num2str(sum(trialIncluded) / sum(isInferred)))
disp('')
checkOutputData(Preds, cueNumRelResp, outcomeVector, iceUsed, ...
    caseCount, length(cueNumRelResp))

[Preds, cueNumRelResp, outcomeVector, iceUsed] = ...
    binOnCuePosition(Preds, cueNumRelResp, outcomeVector, iceUsed, ...
    binSize);
checkOutputData(Preds, cueNumRelResp, outcomeVector, iceUsed, ...
    caseCount*binSize, cuesToConsider/binSize)

if zscorePreds
    predNames = fieldnames(Preds);
    for iPD = 1 : length(predNames)
        Preds.(predNames{iPD}) = zscore(Preds.(predNames{iPD}));
    end
end

end


function SCP = computeScp(CPP)
% Compute a rough estimate of the probability that a change occoured some
% time following each cue, and before the next response (subsequent 
% change probability; SCP). Only approximate and the correct/full 
% probabalistic calculations are not being conducted here.

% INPUT
% CPP: [n X 1] vector. CPP values for each cue in the series leading up to 
%   the response currently being considered. Must be in order with the 
%   first entry corresponding to the cue furthest before the current 
%   response.

noChangeProb = 1 - CPP;

assert(length(size(noChangeProb)) == 2)
assert(size(noChangeProb, 2) == 1)

cumNoChangeProb = cumprod(noChangeProb, 1, "reverse");
SCP_offset = 1 - cumNoChangeProb;

% Need to offset by one row (the SCP of the final cue is always zero)
SCP = zeros(size(SCP_offset));
assert(length(size(SCP)) == 2)
assert(size(SCP, 2) == 1)
SCP(1:end-1) = SCP_offset(2:end);

end


function checkOutputData(Preds, cueNumRelResp, outcomeVector, iceUsed, ...
    expectNumCases, expectNumCuePositions)

assert(all(ismember(outcomeVector, [0, 1])))
checkExpectedPredsAndSize(Preds, [expectNumCases, expectNumCuePositions])
assert(isequal(size(cueNumRelResp), [expectNumCuePositions, 1]))
assert(isequal(size(iceUsed), [expectNumCases, 1]))
assert(isequal(size(outcomeVector), [expectNumCases, 1]))

end


function checkExpectedPredsAndSize(Preds, expectedSize)

expectPreds = {'LLR', 'CPP', 'Uncert', 'SCP'}';
assert(isequal(sort(fieldnames(Preds)), sort(expectPreds)))

for iE = 1 : length(expectPreds)
    thisPred = Preds.(expectPreds{iE});
    assert(isequal(expectedSize, size(thisPred)))
end
end


function [Preds, cueNumRelResp, outcomeVector, iceUsed] = ...
    binOnCuePosition(Preds, cueNumRelResp, outcomeVector, iceUsed, binSize)
% Bin data based on cue position relative to response.

if binSize == 1
    return
end

oldNumCases = size(Preds.LLR, 1);
numCuesConsidered = length(cueNumRelResp);
numBinnedCuesTmp = numCuesConsidered / binSize;
numBinnedCues = round(numBinnedCuesTmp);
if numBinnedCues ~= numBinnedCuesTmp
    error('Number of cues considered must be divisible by binSize.')
end

predFields = fieldnames(Preds);
for iPr = 1 : length(predFields)
    Preds.(predFields{iPr}) = reshape(Preds.(predFields{iPr}), ...
        [oldNumCases*binSize, numBinnedCues]);
end

outcomeVector = repmat(outcomeVector, binSize, 1);
iceUsed = repmat(iceUsed, binSize, 1);

cueNumRelResp = reshape(cueNumRelResp, [binSize, numBinnedCues]);
cueNumRelResp = mean(cueNumRelResp, 1);
cueNumRelResp = cueNumRelResp';

end













    
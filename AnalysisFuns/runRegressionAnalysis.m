function RegDSet = runRegressionAnalysis(TrlDSet, varargin)
% Run the main regression analysis looking at the effect of the cues at 
% different time points, uncertainty, and change point probability (CPP)
% in the inferred condition

% INPUT
% TrlDSet: Dataset in the standard format, that stores data at the level of
%   trials
% varargin{1}: str. For selecting variants of the standard regression.
%   If set to the string 'iceMod', then the regression also includes terms 
%   for the modulatory effect of the ice water. If 'SCP' then the 
%   regression uses LLR and the approximate probabilty that a piece of 
%   information has become outdated as the regressors (subsequent change 
%   probability).
% varargin{2}: str. 'trueParams' (default) to use the true parameter values
%   to calculate LLR, CPP, and uncertainty for the regression, or 
%   a model name to use the fitted parameter values for this 
%   model
% varargin{3}: bool. If true (default) bin the resulting regression 
%   coefficients and average within bins. Different to varargin{5} because
%   varargin{3} requests binning *after* the regression has been conducted.
% varargin{4}: bool. If true (default) z-score the predictors in the
%   regression
% varargin{5}: integer. If 1 (default) has no effect. Otherwise must be a 
%   scalar that cuesToConsider is divisible by. Predictor data will be 
%   binned on the basis of cue number relative to decision, and treated as 
%   if all cases in each bin are from the same cue number relative to the
%   decision as the bin point of the bin.

% OUTPUT
% RegDSet: Dataset in the standard format, that stores regression
%   coefficents for each participant unless varargin{1} is set to 'iceMod'.
%   In this latter case then a structure with two fields is returned. Each
%   field contains a dataset in the standard format, that stores regression
%   coefficents for each participant. The field 'BothSeries' contains the
%   regression results seperately for with and without ice, while
%   'DiffSeries' contains the difference in the regression results between
%   with and without ice (not sure about the direction).

% HISTORY
% 2021, JCT
% 10.10.2023 Updated for Coimbra data

numCuesToConsider = 15;

% Process input
if (~isempty(varargin)) && (~isempty(varargin{1}))
    variety = varargin{1};
else
    variety = 'default';
end

if (length(varargin)>1) && (~isempty(varargin{2}))
    paramType = varargin{2};
else
    paramType = 'trueParams';
end

if (length(varargin)>2) && (~isempty(varargin{3}))
    doBinning = varargin{3};
else
    doBinning = true;
end

if (length(varargin)>3) && (~isempty(varargin{4}))
    zscorePreds = varargin{4};
else
    zscorePreds = true;
end

if (length(varargin)>4) && (~isempty(varargin{5}))
    binSize = varargin{5};
else
    binSize = 1;
end


% Add required information
TrlDSet = computeTrialDerivs(TrlDSet);

if strcmp(paramType, 'trueParams')
    % Construct predictor matrix using key model variables computed using
    % the true parameter values.
    ParamStruct = computeTrueParams(TrlDSet);
    ParamStruct = repmat({ParamStruct}, length(TrlDSet.P), 1);

else
    appliedModels = mT_findAppliedModels(TrlDSet);
    matchingModel = strcmp(appliedModels, paramType);
    
    if sum(matchingModel) ~= 1
        error('Requested model not found')
    end
        
    ParamStruct = mT_findFittedParams(TrlDSet, find(matchingModel));

    if strcmp(paramType, 'miscal-h-b-normative')
        % Nothing do do as have all the parameters we need already

    elseif strcmp(paramType, 'miscal-h-normative-lapse')
        TrueParamStruct = computeTrueParams(TrlDSet);

        for iP = 1 : length(ParamStruct)
            assert(~isfield(ParamStruct{iP}, 'ObserverBeta'))
            TheseParams = ParamStruct{iP};
            TheseParams.ObserverBeta = TrueParamStruct.ObserverBeta;
            ParamStruct{iP} = TheseParams;
        end
    else
        error('Case not yet covered')
    end
end

for iP = 1 : length(TrlDSet.P)
    ThisData = TrlDSet.P(iP).Data;
     
    [SepPreds, cueNumRelResp, outcomeVector, iceUsed] = ...
        computeIndividualPredMatricies(ThisData, ParamStruct{iP}, ...
        numCuesToConsider, zscorePreds, binSize);
    
    % Construct the predictor matrix out of the individual predictors, and
    % record ordering for later use when storing the fitted 
    % regression coefficients
    if strcmp(variety, 'default')
        predOrdering = {'LLR', 'LLR_x_CPP', 'LLR_x_Uncert'};
        numPreds = repmat(length(cueNumRelResp), 3, 1);
        predMatrix = [ SepPreds.LLR, ...
            SepPreds.LLR.*SepPreds.CPP, ...
            SepPreds.LLR.*SepPreds.Uncert ...
            ];
        
    elseif strcmp(variety, 'iceMod')
        predOrdering = {'LLR', 'LLR_x_CPP', 'LLR_x_Uncert', ...
                    'LLR_x_Ice', 'LLR_x_CPP_x_Ice', 'LLR_x_Uncert_x_Ice'};
        numPreds = repmat(length(cueNumRelResp), 6, 1);
        predMatrix = [ SepPreds.LLR, ...
            SepPreds.LLR.*SepPreds.CPP, ...
            SepPreds.LLR.*SepPreds.Uncert ...
            SepPreds.LLR.*iceUsed, ...
            SepPreds.LLR.*SepPreds.CPP.*iceUsed, ...
            SepPreds.LLR.*SepPreds.Uncert.*iceUsed ...
            ];
        
    elseif strcmp(variety, 'SCP')
        predOrdering = {'LLR', 'LLR_x_SCP'};
        % SCP of the final cue is always zero (prior to z-scoring) so 
        % remove from the regression
        numScpPreds = length(cueNumRelResp)-1;
        numPreds = [length(cueNumRelResp); numScpPreds];
        predMatrix = [ SepPreds.LLR, ...
                SepPreds.LLR(:, 1:numScpPreds) ...
                .*SepPreds.SCP(:, 1:numScpPreds)];
    else
        error('Unknown input')
    end
    assert(size(predMatrix, 2) == sum(numPreds))

    % Matlab uses the highest valued category as the reference, and
    % requires positive integers for all categories
    uniqueVals = unique(outcomeVector);
    assert(all(uniqueVals == [0, 1]'))
    outcomeVector(outcomeVector == 0) = 2;
    
    % Run regression   
    B = mnrfit(predMatrix, outcomeVector, 'IterationLimit', 100000);
    
    % Store results
    assert(length(B) == (1 + sum(numPreds)))
    predUsed = false(length(B), 1);
    
    RegDSet.P(iP).Data.Intercept = B(1);
    predUsed(1) = true;
    
    assert(size(numPreds, 2) == 1)
    startIdxs = cumsum([2; numPreds]);
    endIdxs = startIdxs(2:end) -1;
    startIdxs = startIdxs(1:end-1);
    assert(size(startIdxs, 2) == 1)
    assert(size(endIdxs, 2) == 1)
    assert(length(startIdxs) == length(endIdxs))
    
    for iPred = 1 : length(predOrdering)
        relIdxs = startIdxs(iPred) : endIdxs(iPred);
        assert(~any(predUsed(relIdxs)))
        predUsed(relIdxs) = true;
        
        thesePreds = B(relIdxs);
        assert(length(thesePreds) == numPreds(iPred));
        
        numCuePositions = length(cueNumRelResp);
        if length(thesePreds) == numCuePositions
            % Nothing to do
        elseif length(thesePreds) < numCuePositions
            assert(strcmp(predOrdering{iPred}, 'LLR_x_SCP'))
            % Fill out with zeros assuming that it is the cues nearest 
            % the response for which there are no predictors
            assert(size(thesePreds, 2) == 1)
            numMissing = numCuePositions - length(thesePreds);
            thesePreds = [thesePreds; zeros(numMissing, 1)];
            assert(length(thesePreds) == numCuePositions)
        else
            error('Bug')
        end
        
        RegDSet.P(iP).Data.(predOrdering{iPred}) = thesePreds;
    end  
    assert(all(predUsed))
    
    RegDSet.P(iP).Data.CueNumRelativeToNextResponse = cueNumRelResp;
    
    if isfield(TrlDSet.P(iP), 'Spec')
        RegDSet.P(iP).Spec = TrlDSet.P(iP).Spec;
    end
end

if doBinning
    RegDSet = binRelativeToResp(RegDSet);
end

% If using ice do some reorganising of the RegDSet. Instead of
% RegDSet.P(iP).Data containing columns for all of 'LLR', 'LLR_x_CPP', 
% 'LLR_x_Uncert', 'LLR_x_Ice', 'LLR_x_CPP_x_Ice', 'LLR_x_Uncert_x_Ice',
% change to only having columns for 'LLR', 'LLR_x_CPP', 
% 'LLR_x_Uncert', but now each column contains two entries for each time
% point. One of the entries for each time point describes the effect
% without ice, and one with ice. We will add another field to indicate
% which is which. It is easy to compute the effects with/without ice
% becuase above ice is coded as a dummy variable taking the values of 0 and
% 1 only.
if strcmp(variety, 'iceMod')
    OrigDSet = RegDSet;
    origLength = length(OrigDSet.P(1).Data.LLR);

    for iP = 1 : length(OrigDSet.P)
        ThisData = OrigDSet.P(iP).Data;
        NewData = struct();
        
        NewData.CueNumRelativeToNextResponse ...
            = [ThisData.CueNumRelativeToNextResponse; ...
                ThisData.CueNumRelativeToNextResponse];
        NewData.WasIceSess ...
            = [ zeros(size(ThisData.CueNumRelativeToNextResponse)); ...
                ones(size(ThisData.CueNumRelativeToNextResponse))];
        NewData.LLR = ...
            [   ThisData.LLR; 
                (ThisData.LLR + ThisData.LLR_x_Ice)];
        NewData.LLR_x_CPP ...
            = [ ThisData.LLR_x_CPP; 
                (ThisData.LLR_x_CPP + ThisData.LLR_x_CPP_x_Ice)];
        NewData.LLR_x_Uncert ...
            = [ ThisData.LLR_x_Uncert; 
                (ThisData.LLR_x_Uncert + ThisData.LLR_x_Uncert_x_Ice)];
        
        % Check shape
        fields = fieldnames(NewData);
        for iF = 1 : length(fields)
           assert(isequal(size(NewData.(fields{iF})), [2*origLength, 1]))
        end
        
        RegDSet.BothSeries.P(iP).Data = NewData;
    end

    for iP = 1 : length(OrigDSet.P)
        ThisData = OrigDSet.P(iP).Data;
        NewData = struct();
        
        NewData.CueNumRelativeToNextResponse ...
            = ThisData.CueNumRelativeToNextResponse;
        NewData.LLR = ...
            (ThisData.LLR + ThisData.LLR_x_Ice) - ThisData.LLR;
        NewData.LLR_x_CPP ...
            = (ThisData.LLR_x_CPP + ThisData.LLR_x_CPP_x_Ice) ...
                - ThisData.LLR_x_CPP;
        NewData.LLR_x_Uncert ...
            = (ThisData.LLR_x_Uncert + ThisData.LLR_x_Uncert_x_Ice) ...
                - ThisData.LLR_x_Uncert;
        
        % Check shape
        fields = fieldnames(NewData);
        for iF = 1 : length(fields)
           assert(isequal(size(NewData.(fields{iF})), [origLength, 1]))
        end
        
        RegDSet.DiffSeries.P(iP).Data = NewData;
    end
end
        
        
        
        
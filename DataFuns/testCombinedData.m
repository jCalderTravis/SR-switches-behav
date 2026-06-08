function testCombinedData(TrlDSet, CueDSet)
% Run various tests on the trial and cue dataset, once data from all 
% participants has been combined into a single structure, and make some key
% diagnostic plots

% HISTORY
% 2021, JCT
% 22.02.2023 Read through, including called functions

%% Cue data

% Estimate the appoximate offset between the video retrace and the time
% we are requesting events for, and add this as a column to new, temporary
% versions of the dataset.
TmpTrlDSet = TrlDSet;
TmpCueDSet = CueDSet;

for iP = 1 : length(TmpTrlDSet.P)
    videoRetraceOffset = TmpTrlDSet.P(iP).Data.StimFlipEnd_1 ...
        - TmpTrlDSet.P(iP).Data.StimRequestedTime_1;
    
    TmpTrlDSet.P(iP).Data.RetraceOffset = videoRetraceOffset;
    
    numCues = length(TmpCueDSet.P(iP).Data.CueID);
    TmpCueDSet.P(iP).Data.RetraceOffset = nan(numCues, 1);
    
    for iC = 1 : numCues
        thisTrial = TmpCueDSet.P(iP).Data.TrialNum(iC);
        thisBlock = TmpCueDSet.P(iP).Data.BlockNum(iC);
        thisSess = TmpCueDSet.P(iP).Data.SessionNum(iC);
        
        match = (thisTrial == TmpTrlDSet.P(iP).Data.TrialNum) & ...
            (thisBlock == TmpTrlDSet.P(iP).Data.BlockNum) & ...
            (thisSess == TmpTrlDSet.P(iP).Data.SessionNum);
        assert(sum(match) == 1)
        assert(size(match, 2) == 1)
        assert(length(size(match)) == 2)
        assert(length(match) == length(videoRetraceOffset))
        
        TmpCueDSet.P(iP).Data.RetraceOffset(iC) ...
            = videoRetraceOffset(match);
    end
end

testTimeDiscrepancy(TmpCueDSet, 'CueRequestedTime', 'CueFlipEnd')
testTimeDiscrepancy(TmpCueDSet, 'CueRequestedClearTime', 'CueClearEnd')
    
cueFields = fieldnames(CueDSet.P(1).Data);
cueFields = setdiff(cueFields, {'BlockType'});
for iF = 1 : length(cueFields)
    checkForNoNaNs(CueDSet, cueFields{iF})
end


%% Trial Data
testTimeDiscrepancy(TmpTrlDSet, 'FixFlipTime', 'FixFlipEnd2')
testTimeDiscrepancy(TmpTrlDSet, 'StimClearRequestedTime', 'StimClearEndTime')
testTimeDiscrepancy(TmpTrlDSet, 'StimRequestedTime_1', 'StimFlipEnd_1')
if isfield(TmpTrlDSet, 'StimRequestedTime_2')
    testTimeDiscrepancy(TmpTrlDSet, 'StimRequestedTime_2', 'StimFlipEnd_2')
end
testTimeDiscrepancy(TmpTrlDSet, 'FixRotateTimeRequested', 'FixRotateEndTime')

% Check for NaNs
dontCheck = {'BlockType', 'CueLoc', 'RuleIsHorizToLeftForCue'};
trlFields = fieldnames(TrlDSet.P(1).Data);
for iF = 1 : length(trlFields)
    if any(strcmp(trlFields{iF}, dontCheck))
        continue
    end
    checkForNoNaNs(TrlDSet, trlFields{iF})
end

% Check we have a consistent record of the number of cues
for iP = 1 : length(TrlDSet.P)
    est1 = TrlDSet.P(iP).Data.NumCuesInTrial;
    est2 = cellfun(@length, TrlDSet.P(iP).Data.CueLoc);
    
    assert(all(size(est1) == size(est2)))
    assert(all(est1 == est2))
end


%% Consistency
checkConsistency(TrlDSet, CueDSet)


%% Check accuracy values
ruleIsHorizToLeftData = stackVertically(TrlDSet, ...
    'RuleIsHorizToLeftForTrial');
stimIsHorizData = stackVertically(TrlDSet, 'StimIsHoriz');
respIsLeftData = stackVertically(TrlDSet, 'RespIsLeft');
accData = stackVertically(TrlDSet, 'Acc');

ruleNames = {'horizToRight', 'horizToLeft'};
for ruleIsHorizToLeft = [0, 1]
    response = {'Right'; 'Left'};
    stimHorizAcc = [NaN NaN];
    stimVertAcc = [NaN NaN];
    
    for respIsLeft = [0, 1]
        relData = (ruleIsHorizToLeftData == ruleIsHorizToLeft) ...
            & (respIsLeftData == respIsLeft) ...
            & (stimIsHorizData == 1);
        accVals = accData(relData);
        accVals = unique(accVals);
        assert(length(accVals) == 1)
        stimHorizAcc(respIsLeft +1) = accVals;
        
        relData = (ruleIsHorizToLeftData == ruleIsHorizToLeft) ...
            & (respIsLeftData == respIsLeft) ...
            & (stimIsHorizData == 0);
        accVals = accData(relData);
        accVals = unique(accVals);
        assert(length(accVals) == 1)
        stimVertAcc(respIsLeft +1) = accVals;
    end
    
    stimHorizAcc = stimHorizAcc';
    stimVertAcc = stimVertAcc';
    accTable = table(response, stimHorizAcc, stimVertAcc);
    disp(['Accuracy when rule is ' ruleNames{ruleIsHorizToLeft +1}])
    disp(accTable)
end


%% Plots (separetely for each participant and condition)

for iP = 1 : length(CueDSet.P)
    figure; hold on
    ThisData = CueDSet.P(iP).Data;
    histogram(ThisData.CueLoc(logical(ThisData.RuleIsHorizToLeftForCue)))
    histogram(ThisData.CueLoc(~logical(ThisData.RuleIsHorizToLeftForCue)))
    title('Cue locations under the two rules')
    
    rtField = findRelevantRtField(TrlDSet.P(iP).Data);
    
    figure
    histogram(TrlDSet.P(iP).Data.(rtField))
    title('Response times, relative to trial start')
    
    figure
    histogram(TrlDSet.P(iP).Data.(rtField) ...
        - TrlDSet.P(iP).Data.FixRotateTime)
    title('Response times, relative to resp window start')
end

end


function testTimeDiscrepancy(Struct, DataFieldA, DataFieldB)

disp(' ')
disp(['Testing time discrepancy between ' DataFieldA ' and ' DataFieldB])

timesA = [];
timesB = [];
retraceOffsets = [];

for iP = 1 : length(Struct.P)
    timesA = [timesA; Struct.P(iP).Data.(DataFieldA)];
    timesB = [timesB; Struct.P(iP).Data.(DataFieldB)];
    retraceOffsets = [retraceOffsets; Struct.P(iP).Data.RetraceOffset];
end

% Including retrace offsets
discrepancy = abs(timesB - timesA);
largestDisc = max(discrepancy(:));
   
disp('Not taking into account retrace...')
checkFractionAboveTol(discrepancy, 0.018, 0.01)
checkFractionAboveTol(discrepancy, 0.025, 0.005)

disp(['Largest time discrepancy: ' num2str(largestDisc)])
if largestDisc > 0.1
    error('Greater time discrepancy than tolerance.')
end

% Exlcuding delay caused by retrace offsets (hence only look for lateness,
% not absolute value.)
discrepancyMinusOffset = timesB - timesA - retraceOffsets;
largestDiscMinusOffset = max(discrepancyMinusOffset(:));

disp('Taking into account retrace...')
checkFractionAboveTol(discrepancyMinusOffset, 0.006, 0.01)
checkFractionAboveTol(discrepancyMinusOffset, 0.01, 0.005)

disp(['Largest time discrepancy (taking into account retrace: ' ...
    num2str(largestDiscMinusOffset)])
if abs(largestDiscMinusOffset) > 0.09
    error('Greater time discrepancy than tolerance.')
end

end


function checkFractionAboveTol(dataPoints, toleratedVal, toleratedFrac)

fracAboveTol = sum(dataPoints > toleratedVal) / length(dataPoints);
if fracAboveTol > toleratedFrac
    error('Fraction above tolerance exceeded.')
end

disp(['Tolerance: ' num2str(toleratedVal) ...
    '. Fraction exceeding: ' num2str(fracAboveTol)])

end


function checkForNoNaNs(Struct, DataField)

data = [];
for iP = 1 : length(Struct.P)
    data = [data; Struct.P(iP).Data.(DataField)];
end

if any(isnan(data(:)))
    error('NaNs found')
end

end


function checkAllNaNs(Struct, DataField)

data = [];
for iP = 1 : length(Struct.P)
    data = [data; Struct.P(iP).Data.(DataField)];
end

if ~all(isnan(data(:)))
    error('Not all NaNs')
end

end


function data = stackVertically(Struct, DataField)

data = [];
for iP = 1 : length(Struct.P)
    data = [data; Struct.P(iP).Data.(DataField)];
end

end

function pStep_runTests(~)
% Run various code tests

% INPUT
% Options: Ignored. Specific tests use specific configurations.

%% Phi computation
LPR_prev = -500 : 500;
H = 0.01 : 0.01 : 0.2;
[LPR_prev, H] = meshgrid(LPR_prev, H);
LPR_prev = LPR_prev(:);
H = H(:);

oldPhi = nan(length(H), 1);
newPhi = nan(length(H), 1);

for iCalc = 1 : length(H)
    oldPhi(iCalc) = computePhi(LPR_prev(iCalc), H(iCalc), 'old');
    newPhi(iCalc) = computePhi(LPR_prev(iCalc), H(iCalc), 'robust');
end

figure
scatter(oldPhi, newPhi)
refline(1, 0)

maxDiff = compareVals(oldPhi, newPhi);
if maxDiff > (10^(-8))
    error('Bug')
end


%% CPP calculation
testCppCalc()


%% Test accumulation functions
% There should be an equaivalence under certain parameter conditions

TrlDSet = loadData('mainStudy', 'relative_time_real_data');

lastSamp = findLastSample(TrlDSet.P(1).Data);
trialEndAccum = findCueLocAccumulation(TrlDSet.P(1).Data, Inf, 1);
assert(isequal(lastSamp, trialEndAccum))


%% Test findIfNewBlock

TrlDSet = loadData('coimbra', 'relative_time_real_data');

for iP = 1 : length(TrlDSet.P)
    ThisData = TrlDSet.P(iP).Data;
    
    combos = unique([ThisData.SessionNum, ThisData.BlockNum], 'rows');
    totNumBlks = size(combos, 1);
    
    currBlock = 0;
    currSess = 0;
    blkCount = 0;
    
    for iT = 1 : length(ThisData.BlockNum)
        isNewBlock = findIfNewBlock(ThisData, currBlock, currSess, iT);
        
        if isNewBlock
            blkCount = blkCount +1;
        end
        
        currBlock = ThisData.BlockNum(iT);
        currSess = ThisData.SessionNum(iT);
    end
    
    assert(isequal(blkCount, totNumBlks))
end
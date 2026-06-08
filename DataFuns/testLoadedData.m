function testLoadedData(TrialData, CueData, skipTimeTests)
% Do some very basic processing of loaded behavioural data, and run various
% tests on it

% INPUT
% skipTimeTests: boolean. If true, skip all tests based on timings.
% Useful for when have simualated data.

% HISTORY
% 2020-2021, JCT
% 21.02.2023 Read through, including called functions

if skipTimeTests
    disp('Skipping time based checks of the data.')
else
    assert(all(diff(CueData.CueFlipTime)>0))
end
    
assert(isequal(unique(TrialData.TrialNum), unique(CueData.TrialNum)))

% Test number of cues in trial
cuesInTrial = zeros(length(TrialData.TrialNum), 1);
for trialNum = 1 : length(TrialData.TrialNum)
    cuesInTrial(trialNum) = sum(CueData.TrialNum == trialNum);
end

assert(isequal(cuesInTrial, TrialData.NumCuesInTrial))








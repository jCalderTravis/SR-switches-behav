function checkConsistency(TrlDSet, CueDSet)
% Run certain checks on the consistency of the trial-based and cue-based
% data representations.

% HISTORY
% 22.02.2023 Read through, including called functions

ConvCueDSet = convertDSet(TrlDSet);

numPtpnts = length(TrlDSet.P);
assert(numPtpnts == length(CueDSet.P))
assert(numPtpnts == length(ConvCueDSet.P))

for iP = 1 : numPtpnts
    ThisOrigData = CueDSet.P(iP).Data;
    ThisConvData = ConvCueDSet.P(iP).Data;
    
    origFields = fieldnames(ThisOrigData);
    convFields = fieldnames(ThisConvData);
    sharedFields = intersect(convFields, origFields);
    assert(length(sharedFields) > 3)
    
    for iF = 1 : length(sharedFields)
        thisField = sharedFields{iF};
        
        assert(isequal(ThisOrigData.(thisField), ThisConvData.(thisField)))
    end
end
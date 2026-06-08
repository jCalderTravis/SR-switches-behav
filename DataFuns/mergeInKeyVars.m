function CueData = mergeInKeyVars(CueData, KeyVars)
% Merge data on computational varaibles into the cue data.

% INPUT
% CueData: struct. CueDSet.P(iP).Data for some iP, were CueData is the 
%   standard dataset storing data at the level of cues.
% KeyVars: struct. Output of computeKeyModelVariables. Note the odering
%   of cues must be consistent with the ordering of cues in CueData, with
%   no gaps in either. It will be checked that the cue locations of each
%   cue match in the two representations.

mergeFields = {'CueLoc', 'CueLLR', 'AfterCueLPR', 'AfterCueCPP', ...
    'PreCueUncert', 'PreCueLPriorR'}';
extraFields = {'TrialEndLPR'};
expectedFields = union(mergeFields, extraFields);
assert(isequal(sort(fieldnames(KeyVars)), sort(expectedFields)))

ConcatKeyVars = struct();
for iF = 1 : length(mergeFields)
    ConcatKeyVars.(mergeFields{iF}) = [];
end

for iT = 1 : length(KeyVars.CueLoc)
    for iF = 1 : length(mergeFields)
        
        theseVars = KeyVars.(mergeFields{iF}){iT};
        assert(size(theseVars, 2) == 1)

        ConcatKeyVars.(mergeFields{iF}) = ...
            [ConcatKeyVars.(mergeFields{iF}); theseVars];
    end
end

assert(isequal(CueData.CueLoc, ConcatKeyVars.CueLoc))

for iF = 1 : length(mergeFields)
    assert(length(CueData.CueLoc) == ...
        length(ConcatKeyVars.(mergeFields{iF})))

    CueData.(mergeFields{iF}) = ConcatKeyVars.(mergeFields{iF});
end


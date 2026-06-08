function RepDSet = replicateData(DSet, reps)
% Replicate a dataset and concatinate the results. The resulting dataset
% is the same as the input dataset except that each participant now has
% [original num. trials] x reps trials, where this number is achieved by
% replicating trials. (Fields in DSet beyond DSet.Spec and DSet.P and
% fields in DSet.P beyond Spec and Data will be dropped.) New data will
% appear as if it comes from new sessions. I.e. new session numbers will be
% created for the duplicated data

assert(round(reps) == reps)
checkDataOrdering(DSet)

RepDSet = struct();
RepDSet.Spec = DSet.Spec;

for iP = 1 : length(DSet.P)

    fields = fieldnames(DSet.P(iP).Data);
    numTrials = length(DSet.P(iP).Data.(fields{1}));
    maxSess = max(DSet.P(iP).Data.SessionNum);
    checkFieldSizes(DSet.P(iP).Data, numTrials)

    ThisData = struct();

    for iF = 1 : length(fields)
        theseVals = DSet.P(iP).Data.(fields{iF});
        assert(length(size(theseVals)) == 2)
        assert(size(theseVals, 2) == 1)

        theseVals = repmat(theseVals, reps, 1);
        
        if strcmp(fields{iF}, 'SessionNum')
            % Need to assign unique session numbers to the replicated 
            % sessions
            sessOffset = 1:reps;
            sessOffset = (sessOffset-1) * maxSess;
            sessOffset = repelem(sessOffset, numTrials)';

            uniqueSess = length(unique(theseVals));
            assert(isequal(size(sessOffset), size(theseVals)))

            theseVals = theseVals + sessOffset;
            assert((uniqueSess*reps) == length(unique(theseVals)))
        end

        ThisData.(fields{iF}) = theseVals;
    end

    checkFieldSizes(ThisData, numTrials*reps);
    RepDSet.P(iP).Data = ThisData;
    RepDSet.P(iP).Spec = DSet.P(iP).Spec;
end

checkDataOrdering(RepDSet)
end


function checkFieldSizes(struct, expect)
% Check that all fields of a struct contain arrays of size [expect, 1]

fields = fieldnames(struct);
for iF = 1 : length(fields)
    
    thisSize = size(struct.(fields{iF}));
    assert(isequal(thisSize, [expect, 1]))
end


end
function DSet = binRelativeToResp(DSet)
% For datasets that contain a 'CueNumRelativeToNextResponse' variable,
% assign the values of that variable into bins and, within participants,
% average data in each bin.

% HISTORY
% 10.10.2023 Updated for Coimbra data

% Check that binning is appropriate. Need to make sure that prior to
% binning, each 'CueNumRelativeToNextResponse' is unique.
for iP = 1 : length(DSet.P)
    relPos = DSet.P(iP).Data.CueNumRelativeToNextResponse;
    assert(length(relPos) == length(unique(relPos)))
end

for iP = 1 : length(DSet.P)
    relPos = DSet.P(iP).Data.CueNumRelativeToNextResponse;
    relPos = (floor(relPos ./ 3).*3) + 1;
    DSet.P(iP).Data.CueNumRelativeToNextResponse = relPos;
end

for iP = 1 : length(DSet.P)
    thisData = DSet.P(iP).Data;
    numLags = length(thisData.CueNumRelativeToNextResponse);
    theseFields = fieldnames(thisData);
    theseFields = setdiff(theseFields, 'CueNumRelativeToNextResponse');
    
    [grp, newLag] = findgroups(thisData.CueNumRelativeToNextResponse);
    assert(all(diff(newLag) > 0))
    assert(all(diff(grp) >= 0))

    % Check splitapply outputs results in the order that we expect
    newLag2 = splitapply(@mean, thisData.CueNumRelativeToNextResponse, ...
        grp);
    assert(isequal(newLag, newLag2))
    
    thisData.CueNumRelativeToNextResponse = newLag;
    
    for iF = 1 : length(theseFields)
        if length(thisData.(theseFields{iF})) == numLags
            thisData.(theseFields{iF}) = splitapply(@(x)mean(x), ...
                thisData.(theseFields{iF}), grp);
            assert(length(thisData.(theseFields{iF})) == length(newLag))
        else
            assert(strcmp(theseFields{iF}, 'Intercept'))
            assert(length(thisData.(theseFields{iF})) == 1)
        end
    end
    
    DSet.P(iP).Data = thisData;
end
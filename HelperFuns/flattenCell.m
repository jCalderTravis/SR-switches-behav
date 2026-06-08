function vec = flattenCell(cellOfVec)
% Take a columns cell array where each element is a column vector and 
% flatten into a single column vector. Empty elements are skipped.

checkColumn(cellOfVec)

vec = [];

for iEl = 1 : length(cellOfVec)
    theseVals = cellOfVec{iEl};
    
    if isempty(theseVals)
        continue
    end
    
    checkColumn(theseVals)
    vec = [vec; theseVals];
end

end

function checkColumn(thisArray)
    assert(length(size(thisArray)) == 2)
    assert(size(thisArray, 2) == 1)
end

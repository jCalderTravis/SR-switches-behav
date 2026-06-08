function accVals = computePerPtpntAcc(DSet, blockType)

% INPUT
% blkType: str or cell array of str. If cell array, then trials with a
%   block type matching any of the entries in the cell array are included.

accVals = mT_stackData(DSet.P, @(st)computeAcc(st.Data, blockType));
assert(length(accVals) == length(DSet.P))

end
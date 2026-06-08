function DSet = mergeBlocks(DSet, toMerge, mergeName)
% Merge different block types by renaming the block type where appropriate
% to a new shared name. Specifically works on the DSet.P(i).Data.BlockType
% field.

% INPUT
% DSet: Dataset in the standard format
% toMerge: cell-array of str. Strings give the names of the block types
%   that we want to merge.
% mergeName: str. The new name for the merged block type.

for iP = 1 : length(DSet.P)
    match = ismember(DSet.P(iP).Data.BlockType, toMerge);
    DSet.P(iP).Data.BlockType(match) = {mergeName};
end
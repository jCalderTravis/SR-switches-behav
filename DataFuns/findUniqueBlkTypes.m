function blkTypes = findUniqueBlkTypes(DSet)
% Find a list of the blocks types that appear anywhere in the dataset for
% any participant. A list with unique elements is returned.

blkTypes = {};
for iP = 1 : length(DSet.P)
   theseBlkTypes = unique(DSet.P(iP).Data.BlockType);
   blkTypes = [blkTypes; theseBlkTypes];
   assert(size(blkTypes, 2) == 1)
   blkTypes = unique(blkTypes);
end

end

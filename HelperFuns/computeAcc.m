function acc = computeAcc(Data, blkType)

% INPUT
% blkType: str or cell array of str. If cell array, then trials with a
%   block type matching any of the entries in the cell array are included.

if iscell(blkType)
    % Nothing to do
elseif ischar(blkType)
    blkType = {blkType};
else
    error('Unknown input type')
end

inc = ismember(Data.BlockType, blkType) & (~isnan(Data.Acc)) ...
    & logical(Data.RtIsValid);
acc = sum(Data.Acc(inc)==1) / sum(inc==1);

end
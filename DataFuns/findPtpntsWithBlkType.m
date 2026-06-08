function relPtpnts = findPtpntsWithBlkType(DSet, blkType)
% Return the indices in DSet.P of participants who have at least some data
% from the block type blkType

% INPUT
% blkType: str.

relPtpnts = [];

for iP = 1 : length(DSet.P)
   if sum(strcmp(blkType, DSet.P(iP).Data.BlockType)) > 0
       relPtpnts = [relPtpnts; iP];
   else
      disp(['Participant ' num2str(iP) ' has no ' blkType ' data.'])
   end
end

end



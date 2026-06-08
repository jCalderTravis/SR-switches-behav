function isNewBlock = findIfNewBlock(Data, prevBlockNum, prevSessNum, iT)
% Find out whether the block of the trial at trial index iT is the next
% block after previousBlockNum or not.

if (Data.BlockNum(iT) ~= prevBlockNum) ...
        || (Data.SessionNum(iT) ~= prevSessNum)
    
    isNewBlock = true;
    
    enteredNextBlock = Data.BlockNum(iT) > prevBlockNum;
    enteredNextSession = Data.SessionNum(iT) > prevSessNum;
    if ~(enteredNextBlock || enteredNextSession)
        error('Bug: Trials don''t seem to be ordered.')
    end
    
else
    isNewBlock = false;
end
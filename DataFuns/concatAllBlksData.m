function [ConcatTrlData, ConcatCueData] = concatAllBlksData(ptpntID, ...
    AllTrlData, AllCueData, allBlockNums, allSessNums)
% Concatinate data, taking care that the resulting data ends up in order

% HISTORY
% 2020-2021, JCT
% 07.02.2023 Read through, including called functions

assert(length(allBlockNums) == length(allSessNums))
assert(length(allBlockNums) == length(AllTrlData))
assert(length(allBlockNums) == length(AllCueData))

maxBlock = max(allBlockNums);
maxSess = max(allSessNums);
ConcatTrlData = [];
ConcatCueData = [];
dataWasConcatinated = false(length(allBlockNums), 1);

for iS = 1 : maxSess
    
    inThisSess = allSessNums == iS;
    if sum(inThisSess) == 0
        warning(['No data found for participant ' num2str(ptpntID) ...
            ' in session ' num2str(iS)])
        continue
    end
    
    for iB = 1 : maxBlock
        inThisBlock = allBlockNums == iB;
        thisBlockAndSess = inThisBlock & inThisSess;
        
        skipBlock = false;
        if sum(thisBlockAndSess) == 0
            warning(['No data found for participant ' num2str(ptpntID) ...
                ' for session ' num2str(iS) ' and block ' num2str(iB)])
            skipBlock = true;
        elseif sum(thisBlockAndSess) > 1
            error(['This function should always pick out just a single '...
                'block from a single session. But this did not happen.'])
        end
        
        if ~skipBlock
            ThisTrialData = AllTrlData{thisBlockAndSess};
            ThisCueData = AllCueData{thisBlockAndSess};
            ConcatTrlData = concatinateStructures(ConcatTrlData, ThisTrialData);
            ConcatCueData = concatinateStructures(ConcatCueData, ThisCueData);
            
            % Checks. We use dataWasConcatinated to keep a record of which
            % data has already been concatinated.
            previouslyUsed = dataWasConcatinated(thisBlockAndSess);
            if any(previouslyUsed(:))
                error('Bug: Data is being double counted')
            end
            dataWasConcatinated(thisBlockAndSess) = true;
        end
    end
end

% Check that all data was used
if any(~dataWasConcatinated(:))
    error('Not all data was used during concatination.')
end

function [TrlDSet, CueDSet] = formatCoimbraData(TrlDSet)
% Make some changes to the format of the Coimbra dataset so that it even
% more closely aligns with the previously collected data

% Key steps...
% (1) Flip CueLoc where appropropriate so that positive CueLoc always
%   indicates evidence for the houseToLeft rule
% (2) Flip CueLoc where appropriate so that positive CueLoc always supports
%   distIsUpper


checkCoimbraData(TrlDSet)

for iP = 1 : length(TrlDSet.P)
    assert(~isfield(TrlDSet.P(iP).Data, 'WasIceSess'))
    TrlDSet.P(iP).Data.WasIceSess = ...
        zeros(size(TrlDSet.P(iP).Data.TrialNum));
end

for iP = 1 : length(TrlDSet.P)
    ThisData = TrlDSet.P(iP).Data;
    
    for iT = 1 : length(ThisData.TrialNum)
        if strcmp(ThisData.BlockType{iT}, 'inference-only')
            ThisData.CueLoc{iT} = -ThisData.CueLoc{iT};
            
        elseif any(strcmp(ThisData.BlockType{iT}, ...
                {'full_task_lab', 'full_task_scanner'}))
            
            if TrlDSet.P(iP).Spec.RuleConfiguration == 1
                ThisData.CueLoc{iT} = -ThisData.CueLoc{iT};
            elseif TrlDSet.P(iP).Spec.RuleConfiguration == 0
                % Nothing to do
            else
                error('Bug')
            end
        else
            error('Bug')
        end
    end
    TrlDSet.P(iP).Data = ThisData;
end

CueDSet = convertDSet(TrlDSet);

checkCoimbraData(TrlDSet)
checkCoimbraData(CueDSet)
checkReportedCueStats(CueDSet)




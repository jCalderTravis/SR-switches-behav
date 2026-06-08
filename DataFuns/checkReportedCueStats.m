function checkReportedCueStats(CueDSet)
% Check the statistics for the cues reported in CueDSet.Spec closely match
% the empirically observed statistics.

DForm = findDataFormat(CueDSet);
checkSpecificCategorisation(CueDSet, DForm.IsRuleAForCue)

blkTypes = findUniqueBlkTypes(CueDSet);
if any(strcmp('inference-only', blkTypes))
    
    relPtpnts = findPtpntsWithBlkType(CueDSet, 'inference-only');
    TmpCueDSet = CueDSet;
    TmpCueDSet.P = TmpCueDSet.P(relPtpnts);
    checkSpecificCategorisation(TmpCueDSet, 'DistIsUpperForCue')
end

end


function checkSpecificCategorisation(CueDSet, categoryFieldname)
% Check the reported cue statistics for the cues falling into the two 
% categories labeled by the field with name categoryFieldname

DForm = findDataFormat([]);

for iP = 1 : length(CueDSet.P)
    ThisData = CueDSet.P(iP).Data;
    
    expected = ismember(ThisData.BlockType, DForm.AllPermittedBlks);
    assert(all(expected(:)))
    
    infCues = ismember(ThisData.BlockType, DForm.AllInferenceBlks);
    
    rule2Cues = ThisData.CueLoc(...
        (ThisData.(categoryFieldname) == 1) & infCues);
    rule1Cues = ThisData.CueLoc(...
        (ThisData.(categoryFieldname) == 0) & infCues);
    
    meanDiff = mean(rule2Cues) - mean(rule1Cues);
    assert(CueDSet.Spec.CueMeanDiff > 0)
    assertNearTarget(CueDSet.Spec.CueMeanDiff, meanDiff)
    
    stdRule1 = std(rule1Cues);
    assertNearTarget(CueDSet.Spec.CueSigma, stdRule1)
    
    stdRule2 = std(rule2Cues);
    assertNearTarget(CueDSet.Spec.CueSigma, stdRule2)
end

end

function assertNearTarget(target, value)

tol = abs(target * 0.1);
diff = abs(value - target);
assert(diff < tol)

end
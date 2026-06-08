function maxDiff = compareVals(valsA, valsB)

diffs = abs(valsA - valsB);
maxDiff = max(diffs);
disp(['Biggest discrepancy: ' num2str(maxDiff)])
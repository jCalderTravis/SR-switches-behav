function hazardRate = findTrueHazardRateInInferred(Data)

hazardRate = unique(Data.HazardRate);
assert(length(hazardRate) == 1)
assert(~isnan(hazardRate))
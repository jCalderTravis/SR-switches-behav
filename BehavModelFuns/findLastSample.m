function lastSamp = findLastSample(Data)

lastSamp = nan(length(Data.BlockNum), 1);
for iT = 1 : length(Data.BlockNum)
    theseCues = Data.CueLoc{iT};
    lastSamp(iT) = theseCues(end);
end

assert(~any(isnan(lastSamp)))
assert(isequal(size(lastSamp), [length(Data.BlockNum), 1]))

end
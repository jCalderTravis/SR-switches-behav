function saveStructAsCsv(struct, savename)

thisTable = struct2table(struct);
assert(isequal(savename(end-3:end), '.csv'))
writetable(thisTable, savename)
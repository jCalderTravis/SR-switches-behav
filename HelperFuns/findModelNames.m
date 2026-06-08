function modelNames = findModelNames(modelList)
% Find nice versions of model names for plotting purposes

origNames = {'miscal-h-b-normative', 'miscal-h-normative', 'normative', ...
    'last-sample', ...
    'perfect-acc', 'bound-acc', 'leaky-acc'};
niceNames = {'Miscal. h & b norm.', 'Miscal. h norm.', 'Normative', ...
    'Last sample', ...
    'Perfect accu.', 'Bounded accu.', 'Leaky accu.'};

assert(length(origNames), length(niceNames))
newOrigNames = cell(1, length(origNames));
newNiceNames = cell(1, length(origNames));

for iN = 1 : length(origNames)
    newOrigNames{iN} = [origNames{iN}, '-lapse'];
    newNiceNames{iN} = [niceNames{iN} ' (lapse)'];
end
origNames = [origNames, newOrigNames];
niceNames = [niceNames, newNiceNames];

modelNames = modelList;

for iE = 1 : length(modelList)
    match = strcmp(modelList{iE}, origNames);
    assert(sum(match) == 1)
    
    modelNames{iE} = niceNames{match};
end
    
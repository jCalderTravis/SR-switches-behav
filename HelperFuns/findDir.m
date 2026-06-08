function dirToUse = findDir(Options, stage)
% Find the name of a suitable directiory for saving analysis results, and 
% create this directory if needed.
%
% The returned directory is a subfolder of the configured StepResultsDir or
% FinalResultsDir. The subfolder name incorporates the config, step, and any
% additional option fields so that outputs are stored in a consistent folder.
%
% INPUT
% Options: The options structure that was passed to the processsing step 
%   for which we wish to save results.
% stage: str. 'step' or 'final'. Are we saving a mid-point of the analysis,
%   or something final (e.g. a plot)?

% HISTORY
% 2022 JCT
% 07.02.2023 Read through, and called functions

KeyDirs = loadConfig(Options.Config, 'keyDirs');

if strcmp(stage, 'step')
    baseDir = KeyDirs.StepResultsDir;
elseif strcmp(stage, 'final')
    baseDir = KeyDirs.FinalResultsDir;
else
    error('Incorrect use of inputs.')
end

specificDir = '';
theseFields = fieldnames(Options)';

% Order fields for a consistent save name regardless of original ordering
% of the options
forStart = {'Config', 'Step'};
orderedFields = setdiff(theseFields, forStart, 'sorted');
orderedFields = [forStart, orderedFields];
assert(isequal(size(orderedFields), size(theseFields)))

for iF = 1 : length(orderedFields)
    thisVal = Options.(orderedFields{iF});
    assert(ischar(thisVal))
    
    if iF > 1
        spacer = '_';
    else
        spacer = '';
    end
    
    specificDir = [specificDir, spacer, orderedFields{iF}, '-', thisVal];
end

dirToUse = fullfile(baseDir, specificDir);
dirToUse = [dirToUse, '\'];

if ~exist(dirToUse, 'dir')
    mkdir(dirToUse)
end

function DSet = simulateDataSetWrapper(saveDir, basedOn, varargin)
% Simulate an entirely new dataset and then simulate responses/accuracy 
% in one of three ways, determined by basedOn

% INPUT
% saveDir: Where to save temporary files.
% basedOn: string. Simulate based on randomly picked values ('randParams'), 
%   simulate based on fitted parameter values ('fittedParams'), or 
%   simulate based on optimal parameters ('theoryMax'). May need to provide
%   additional inputs, depending on the option selected. See comments
%   below.
% varargin{1}: TrlDSet. If basedOn=='fittedParams', then the simulations 
%   are based on model fits in this dataset. If basedOn=='theoryMax', then
%   key properties of the stimulus are extracted from TrlDSet and used to 
%   compute the optimal parameters.
% varargin{2}: str. If basedOn=='randParams' or 'fittedParams', then this 
%   input gives the name of the model to use to stimulate (and to set the 
%   parameter values in the case of 'fittedParams').
% varargin{3}: struct. Allows to customise the properties of the simulated
%   stimulus (e.g. number of trials). Is passed as the settings structure 
%   to runExperiment.m. See the comments on that function for the avalaible
%   options.
% varargin{4}: str. 'halfIce' to mark half the sessions as corresponding to
%   ice sessions, or 'noIce' to mark all sessions as control sessions.
%   Defaults to 'halfIce'.
% 
% OUTPUT
% DSet: simulated dataset in the same format used elsewhere by
%   the analysis pipeline.

% HISTORY
% 2020-2022, JCT

[RealTrlDSet, modelName, ExtraSettings, iceMode] = ...
    processSimVarargs(basedOn, varargin);

% Settings depend of the type of simulations
if strcmp(basedOn, 'randParams')
    numPtpnts = 10;
elseif any(strcmp(basedOn, {'theoryMax', 'fittedParams'}))
    numPtpnts = length(RealTrlDSet.P);
else
    error('Unknown input arguement')
end

% Always want 4 four simualted sessions (sessions 2 to 5 as session 1 is 
% behavioural only)
firstSession = 2;
lastSession = 5;

% Save temporary files in a temporary subfolder of the specified directory, 
% to ensure that different simulations do no interfere with each other
tempDir = [tempname(saveDir), '/'];
mkdir(tempDir)
disp(['Temporary directory in use (will delete after): ' tempDir])

for iP = 1 : numPtpnts
    simulateStimulus(iP, tempDir, firstSession, lastSession, ...
        ExtraSettings);
end

% Simulate ice vs. control sessions
entry = 0;
for iP = 1 : numPtpnts
    for iS = firstSession : lastSession
        entry = entry +1;
        IceStructure.PtpntID(entry) = iP;
        IceStructure.Session(entry) = iS;
        
        if strcmp(iceMode, 'halfIce')
            IceStructure.IceUsed(entry) = mod(iS, 2);
        elseif strcmp(iceMode, 'noIce')
            IceStructure.IceUsed(entry) = 0;
        else
            error('Unknown option')
        end
    end
end

% Load the simulated stimulus data and convert into a helpful format 
tmpSaveDirs = repmat({tempDir}, numPtpnts, 1);
ptpntNums = 1:numPtpnts;
[DSet, ~, ~] = loadAllPtpntData(tmpSaveDirs, ptpntNums, ...
    IceStructure, true, true, false);

% Delete temporary directory
rmdir(tempDir, 's')

% Simulate responses on the basis of the simulated stimuli
if strcmp(basedOn, 'randParams')
    DSet = simulateRespAndAccFromStim(DSet, 'randParams', modelName);
    
elseif strcmp(basedOn, 'theoryMax')
    % Check the relevant settings are identical in the simulated dataset,
    % and real dataset, so that optimal performance is also the same.
    OptParams = computeTrueParams(RealTrlDSet);
    OptParamsV2 = computeTrueParams(DSet);
    assert(isequal(OptParams, OptParamsV2))
    
    DSet = simulateRespAndAccFromStim(DSet, 'noParams', ...
        'normative-no-noise');
    
elseif strcmp(basedOn, 'fittedParams')
    DSet = simulateRespAndAccFromStim(DSet, 'fittedParams', ...
        modelName, RealTrlDSet);
else
    error('Unknown option selected')
end






    
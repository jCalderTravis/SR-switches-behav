function simulateStimulus(ptpntNum, saveDir, ...
                            firstSession, lastSession, varargin)
% Simulates a stimulus for one participant and saves files with the
% simulated data

% INPUT
% saveDir: Where to save the results. Should have a
% trailing slash.
% firstSession: Number. Number of the first session to simulate
% lastSession: Number. Number of the last session to simulate
% varargin{1}: Structure to pass as the settings structure to
% runExperiment.m. See the comments on that function for the avalaible
% options.

% HISTORY
% 2020, JCT

% There are certain settings we will always use. We may also add more if
% specified in varargin{1}
Settings.SimOnly = true;
Settings.SaveDir = saveDir;

if ~isempty(varargin)
    ExtraSettings = varargin{1};
    extraFields = fieldnames(ExtraSettings);
    for iF = 1 : length(extraFields)
       Settings.(extraFields{iF}) = ExtraSettings.(extraFields{iF});
    end
end


% Run the simulation and save results
addRemoveReqPaths('remove')
for sessionNum = firstSession : lastSession
    runExperiment(ptpntNum, sessionNum, false, Settings);
end
addRemoveReqPaths('add')




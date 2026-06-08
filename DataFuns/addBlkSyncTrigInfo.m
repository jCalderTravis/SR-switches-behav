function Data = addBlkSyncTrigInfo(Data, blkSyncTrigTime)
% To either the cue data or the trial data for one block, add info on the
% time of the unique block syncronisation trigger.

% INTPUT
% blkSyncTrigTime: scalar. Time of the unique block syncronisation trigger.

% HISTORY
% 07.02.2023 Read through, including called functions

assert(length(unique(Data.BlockNum)) == 1)
assert(length(unique(Data.SessionNum)) == 1)
assert(~isfield(Data, 'BlkSyncTrigTime'))

numTrials = length(Data.TrialNum);
Data.BlkSyncTrigTime = repmat(blkSyncTrigTime, numTrials, 1);

% Check that timings seem sensible
if isfield(Data, 'FixFlipTime')
    timeDiffs = Data.FixFlipTime - Data.BlkSyncTrigTime;
elseif isfield(Data, 'CueFlipTime')
    timeDiffs = Data.CueFlipTime - Data.BlkSyncTrigTime;
else
    error('No time checks were possible')
end

assert(all(timeDiffs(:) > 0))
assert(all(timeDiffs(:) < (60*10))) % A block lasting longer than 10 mins
% is possible and not necessarily the sign of a bug (e.g. participant
% didn't respond for ages), therefore this test is a bit over strong.
assert(all(diff(timeDiffs(:)) > 0))
function rtField = findRelevantRtField(Data)
% Find out whether RT data is stored in a field called 'RT' or 'RtAbs'

% INPUT
% Data: struct. Either has field 'RT' or 'RtAbs'

% HISTORY
% 07.02.2023 Read through, including called functions

if isfield(Data, 'RT') && isfield(Data, 'RtAbs')
    error('Cannot have both RT representations')
elseif (~isfield(Data, 'RT')) && (~isfield(Data, 'RtAbs'))
    error('Must have an RT representation')
elseif isfield(Data, 'RT')
    rtField = 'RT';
elseif isfield(Data, 'RtAbs')
    rtField = 'RtAbs';
else
    error('Bug')
end
function pStep_makeRtTable(Options)
% Make a table of average response times

% INPUT
% Options: Struct. Has the following fields...
%   Config: See runMatlabStep.m
%   Step: See runMatlabStep.m

% LOADS
% Save files from: pStep_collateData

TrlDSet = loadData(Options.Config, 'relative_time_real_data');

disp('Average RT table')

for iP = 1 : length(TrlDSet.P)
    valid = logical(TrlDSet.P(iP).Data.RtIsValid);
    
    avRT = mean(TrlDSet.P(iP).Data.RT(valid) ...
        - TrlDSet.P(iP).Data.FixRotateTime(valid));
    
    disp(['''' num2str(TrlDSet.P(iP).Spec.PtpntID) ...
        ''': ' num2str(avRT) ','])
end
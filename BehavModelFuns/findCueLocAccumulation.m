function trialEndAccum = findCueLocAccumulation(Data, varargin)
% For the end of each trial (i.e. response time), find the accumulated sum 
% of the cue locations presented so far that block (i.e. the accumulated
% evidence).

% INPUT
% varargin{1}: positive scalar. Bound on the absolute value of the
%   evidence accumulation. Default is no bound.
% varargin{2} scalar between 0 and 1 (including 0 and 1). Leak. 0
%   represents that all information is retained each step, while 1
%   represents that all previous information is lost on each update.
%   Default is no leak, i.e., 0.

% OUTPUT
% trialEndAccum: vector. As long as the number of trials. Gives the state
%   of the evidnece accumulation at the end of each trial (i.e. at the time
%   of main stimulus presentation and response).

% HISTORY
% 09.06.2023 Updated for Coimbra data

if (~isempty(varargin)) && (~isempty(varargin{1}))
    accumBound = varargin{1};
    assert(accumBound > 0)
else
    accumBound = Inf;
end

if (length(varargin) > 1) && (~isempty(varargin{2}))
    leak = varargin{2};
    assert(leak >= 0)
    assert(leak <= 1)
else
    leak = 0;
end

trialEndAccum = nan(length(Data.BlockNum), 1);
currBlock = 0;
currSess = 0;
cueAccum = 0;

for iT = 1 : length(Data.BlockNum)
    isNewBlock = findIfNewBlock(Data, currBlock, currSess, iT);
    if isNewBlock
        cueAccum = 0;
    end
    
    for iC = 1 : length(Data.CueLoc{iT})
        cueAccum = (1 - leak) * cueAccum;
        cueAccum = cueAccum + Data.CueLoc{iT}(iC);
        
        if cueAccum > accumBound
            cueAccum = accumBound;
        elseif cueAccum < -accumBound
            cueAccum = -accumBound;
        end
    end
    
    trialEndAccum(iT) = cueAccum;
    currBlock = Data.BlockNum(iT);
    currSess = Data.SessionNum(iT);
end

assert(~any(isnan(trialEndAccum)))
assert(isequal(size(trialEndAccum), [length(Data.BlockNum), 1]))

end
function Phi = computePhi(LPR_prev, H, varargin)
% Compute the "prior", using the previous log-posterior ratio (LPR_prev),
% and the hazard rate (H)

% INPUT
% varargin{1}: str. If 'old' use an old method for calculating phi. If
%   'robust' use a newer method, that is more robust to large values of
%   LPR_prev. Default is 'robust'.

assert(length(LPR_prev) == 1)
assert(length(H) == 1)

if ~isempty(varargin)
    method = varargin{1};
else
    method = 'robust';
end

hTerm = (1 - H) / H;

if strcmp(method, 'old')
    Phi = LPR_prev + log(hTerm + exp(-LPR_prev)) ...
        - log(hTerm + exp(LPR_prev));
    
elseif strcmp(method, 'robust')
    if LPR_prev >= 0
        Phi = log(hTerm + exp(-LPR_prev)) ...
            - log((hTerm * exp(-LPR_prev)) + 1);
    elseif LPR_prev < 0
        Phi = log((hTerm * exp(LPR_prev)) + 1) ...
            - log(hTerm + exp(LPR_prev));
    end
else
    error('Bug')
end
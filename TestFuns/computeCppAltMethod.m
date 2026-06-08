function CPP = computeCppAltMethod(cueLoc, posterior, meanDiff, cueSd, H)
% Compute the change point probability (CPP) using the equation from Murphy
% et al. (2021). 

% INPUT
% cueLoc: A vector as long as the number of cues giving the cue location
% posterior: A vector as long as the number of cues giving the probability,
%   after the corresponding cue, that the generative mean of the cues is
%   currently postitive
% meanDiff: scalar. Gives the difference between the two possible
%   generative means (which are assumed to be centred on zero)
% cueSd: scalar. Gives the stadnard deviation of the distribution from 
%   which cues are drawn. (This standard deviation is assumed to be the 
%   same regardless of the generative mean).
% H: scalar. Hazard rate.

% OUTPUT
% CPP: Vector as long as the number of cues. Gives the CPP following that
% cue

% NOTES
% We will use "1" to indcate the case where the generative mean is
% positive, and "2" to indicate the oppposie

mean1 = meanDiff / 2;
mean2 = - meanDiff / 2;

% We often need the posterior for the *previous* cue
posterior1 = posterior(:);
postPrev1 = [0.5; posterior1(1:end-1)];
postPrev2 = 1 - postPrev1;

term1 = (normpdf(cueLoc, mean1, cueSd) .* postPrev2) + ... 
    (normpdf(cueLoc, mean2, cueSd) .* postPrev1);
term1 = term1 * H;

term2 = (normpdf(cueLoc, mean1, cueSd) .* postPrev1) + ... 
    (normpdf(cueLoc, mean2, cueSd) .* postPrev2);
term2 = term2 * (1-H);

CPP = term1 ./ (term1 + term2);
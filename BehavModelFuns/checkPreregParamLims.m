function checkPreregParamLims(TrlDSet, relevantModel)
% Check the limits on the parameter match the preregistered limits

% INPUT
% TrlDSet: The fitted dataset.
% relevantModel: scalar. What is the index of the model that corresponds to
%   the preregistered model?

% Preregisted values
LowerBound.ObserverH = 0;
LowerBound.ObserverBeta = 0.01;
LowerBound.DecisionNoiseSigma = 0; 

PLB.ObserverH = 0.001;
PLB.ObserverBeta = 0.1;
PLB.DecisionNoiseSigma = 0.05; 

PUB.ObserverH = 0.5;
PUB.ObserverBeta = 300;
PUB.DecisionNoiseSigma = 5; 

UpperBound.ObserverH = 1;
UpperBound.ObserverBeta = 2000;
UpperBound.DecisionNoiseSigma = 20; 

for iP = 1 : length(TrlDSet.P)
    UsedSettings = TrlDSet.P(iP).Models(relevantModel).Settings;
    UsedBounds = UsedSettings.ParamBounds;
    
    assert(isequal(UsedBounds.LowerBound, LowerBound))
    assert(isequal(UsedBounds.PLB, PLB))
    assert(isequal(UsedBounds.PUB, PUB))
    assert(isequal(UsedBounds.UpperBound, UpperBound))
end
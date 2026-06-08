function testCppCalc()
% Note: Does not test the computation of the likelihood or posterior

% HISTORY
% 29.10.2023 Checked matched maths in preregistration, and in Murphy et
% al.(2021), including all relevant subfunctions

numTrials = 1000;
cuesPerTrial = 10;

meanDiff = 10; % Diff between mean under rule 1 and rule 2
distSd = 10; % = SD of dist under rule 1 = SD of dist under rule 2
H = 0.08;

Data.SessionNum = ones(numTrials, 1); 
Data.BlockNum = ones(numTrials, 1);
Data.BlockType = repmat({'inferred'}, numTrials, 1);
Data.CueLoc = cell(numTrials, 1);

for iT = 1 : numTrials
    Data.CueLoc{iT} = (rand(cuesPerTrial, 1) - 0.5) * meanDiff * 8;
end

% Calculaton 1
ParamStruct.ObserverH = H;
ParamStruct.ObserverBeta = meanDiff / (distSd^2);

KeyVars = computeKeyModelVariables(ParamStruct, Data);

CPP_orig = [];
cueVec = [];
logPostRatioVec = [];
for iT = 1 : numTrials
   CPP_orig = [CPP_orig; KeyVars.AfterCueCPP{iT}(:)];
   cueVec = [cueVec; Data.CueLoc{iT}(:)];
   logPostRatioVec = [logPostRatioVec; KeyVars.AfterCueLPR{iT}(:)];
end
postVec = 1 ./ (1 + exp(-logPostRatioVec));

% Calculation 2
CPP = computeCppAltMethod(cueVec, postVec, meanDiff, distSd, H);

% Comparison
compareVals(CPP_orig, CPP);

scatter(CPP, CPP_orig)
refline(1, 0)
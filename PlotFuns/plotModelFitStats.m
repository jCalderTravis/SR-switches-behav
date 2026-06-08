function plotModelFitStats(TrlDSet, plotSaveDir, saveName, varargin)
% Plot AIC and BIC for model fits

% INPUT
% saveName: str. String to add to the default save name. May pass ''.
% varargin{1}: bool. If true (default) also plot the number of participants
%   best fit by each model.
% varargin{2}: cell array. Any models with names that start with the 
%   any of the strings in this cell array will be excluded. When using 
%   this argument "limModels" is appended to the save name. If using this 
%   arguement multiple times, will need to ensure that results are not 
%   overwritten, by passing unique inputs to saveName.
% varargin{3}: scalar. If provided the y-limits on the plots of information 
%   criteria means will be extended by this quantity at the lower y-limit. 
%   Default 0.
% varargin{4}: bool. If true (default) also plot BIC results, not just AIC
%   results.
% varargin{5}: vector of length 2. Override default height and width of
%   the saved PDF.
% varargin{6}: bool. If true (default) letter the subplots.

if ~isempty(varargin)
    comprehensive = varargin{1};
else
    comprehensive = true;
end

if (length(varargin) >= 2) && (~isempty(varargin{2}))
    exclude = varargin{2};
else
    exclude = {};
end

if (length(varargin) >= 3) && (~isempty(varargin{3}))
    expandY = varargin{3};
else
    expandY = 0;
end

if (length(varargin) >= 4) && (~isempty(varargin{4}))
    plotBic = varargin{4};
else
    plotBic = true;
end

if (length(varargin) >= 5) && (~isempty(varargin{5}))
    overrideSize = varargin{5};
else
    overrideSize = [];
end

if (length(varargin) >= 6) && (~isempty(varargin{6}))
    lettering = varargin{6};
else
    lettering = true;
end

appliedModels = mT_findAppliedModels(TrlDSet);

if ~isempty(exclude)
    incMask = true(1, length(appliedModels));

    for iM = 1 : length(appliedModels)
        incMask(iM) = ~startsWith(appliedModels{iM}, exclude);
    end
    incModels = find(incMask);

    for iP = 1 : length(TrlDSet.P)
        TrlDSet.P(iP).Models = TrlDSet.P(iP).Models(incModels);
    end
    appliedModels = mT_findAppliedModels(TrlDSet);
end

[aicData, bicData] = mT_collectBicAndAicInfo(TrlDSet);
if plotBic
    % pass
else
    bicData = [];
end
mT_plotAicAndBic(aicData, bicData, [], '', false, ...
    findModelNames(appliedModels), expandY, lettering, comprehensive);

if ~comprehensive
    addText1 = '_fewerPlts';
    width = 15.9 / 2;
else
    addText1 = '';
    width = 15.9;
end

if ~isempty(exclude)
    addText2 = '_limModels';
else
    addText2 = '';
end

if ~plotBic
    addText3 = '_noBic';
else
    addText3 = '';
end

if isempty(overrideSize)
    pdfHeight = 15.9;
    pdfWidth = width;
else
    pdfHeight = overrideSize(1);
    pdfWidth= overrideSize(2);
end

mT_exportNicePdf(pdfHeight, pdfWidth, plotSaveDir, ['aicBic', addText1, ...
    addText2, addText3, saveName])

end



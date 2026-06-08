function [DSetSpec, WaterBlocks] = loadExpInfoFiles(relFiles, ptpntID, ...
    allSessNums)
% Load the file that stores general experiment info and which is
% saved each session.

% INPUT
% relFiles: Struct array of relevant files, in the same format as produced
%   by MATLABs dir function. Note this gives the file names of the files
%   storing information on individual blocks. The code will work out where
%   to load the general experiment info file sfrom, from this.
% allSessNums: vecotr as long as relFiles. Gives the corresponding session
%   number for each file

% OUTPUT
% WaterBlocks: struct. Contains info on which blocks ice/control water was 
%   used prior to them, for each session.

% HISTORY
% 2020-2021, JCT
% 07.02.2023 Read through, including called functions

assert(length(allSessNums(:)) == length(relFiles(:)))
assert(length(allSessNums) == length(relFiles))

cueMeanDiff = nan(length(relFiles), 1);
cueSigma = nan(length(relFiles), 1);
WaterBlocks = struct();
WaterBlocks.PtpntID = [];
WaterBlocks.Sess = [];
WaterBlocks.BlockNum = [];
WaterBlocks.TypeOfWater = {};
PrevLoadedWaterBlocks = struct();

for iF = 1 : length(relFiles)
    thisSess = allSessNums(iF);
    
    generalInfoFile = dir([relFiles(iF).folder ...
        '/ptpnt' num2str(ptpntID) ...
        '_session' num2str(thisSess) ...
        '*_expInfo_*_expEnd.mat']);
    
    if isempty(generalInfoFile)
        % This may be old data saved with a slightly different format
        generalInfoFile = dir([relFiles(iF).folder ...
            '/ptpnt' num2str(ptpntID) ...
            '_session' num2str(thisSess) ...
            '_expInfo.mat']);
    end
    
    if length(generalInfoFile) ~= 1
        error('Expected 1 and only 1 general experiment info file.')
    end
    
    Loaded = load(fullfile(generalInfoFile(1).folder, ...
        generalInfoFile(1).name));
    ExpInfo = Loaded.ExpInfo;
    
    cueMeanDiff(iF) = ExpInfo.Cues.MeanDiff;
    cueSigma(iF) = ExpInfo.Cues.Sigma;
    
    theseWaterBlocks = ExpInfo.IceBlocks;
    for iIce = 1 : length(theseWaterBlocks)
        
        matches = (WaterBlocks.PtpntID == ptpntID) & ...
            (WaterBlocks.Sess == thisSess) & ...
            (WaterBlocks.BlockNum == theseWaterBlocks(iIce));
        
        if sum(matches) == 1
            if strcmp(WaterBlocks.TypeOfWater{matches}, 'Unknown')
                assert(~isfield(ExpInfo, 'TypeOfWater'))
            else
                assert(strcmp(WaterBlocks.TypeOfWater{matches}, ...
                    ExpInfo.TypeOfWater));
            end
        else
            assert(sum(matches) == 0)
            
            WaterBlocks.PtpntID(end+1, 1) = ptpntID;
            WaterBlocks.Sess(end+1, 1) = thisSess;
            WaterBlocks.BlockNum(end+1, 1) = theseWaterBlocks(iIce);
            if isfield(ExpInfo, 'TypeOfWater')
                WaterBlocks.TypeOfWater{end+1, 1} = ExpInfo.TypeOfWater;
            else
                WaterBlocks.TypeOfWater{end+1, 1} = 'Unknown';
            end 
        end
    end
    
    % Just some checks
    iceFieldname = ['Sess' num2str(thisSess)];
    if isfield(PrevLoadedWaterBlocks, iceFieldname)
        assert(isequal(PrevLoadedWaterBlocks.(iceFieldname), ...
            theseWaterBlocks))
    else
        PrevLoadedWaterBlocks.(iceFieldname) = theseWaterBlocks;
    end
end

cueMeanDiff = unique(cueMeanDiff);
assert(length(cueMeanDiff) == 1);
cueSigma = unique(cueSigma);
assert(length(cueSigma) == 1);

DSetSpec.CueMeanDiff = cueMeanDiff;
DSetSpec.CueSigma = cueSigma;
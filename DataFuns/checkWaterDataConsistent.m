function checkWaterDataConsistent(IceStructure, WaterBlocks, permitUnknown)
% The code uses two different representations for information on when
% ice/room temp water was used. And this data stems from two different
% sources (either the CSV storing ice info, or from the info input
% by the user when running the experiment). Run some checks for
% consistency.

% INPUT
% IceStructure: Matlab strcuture describing the sessions for which ice
%   water was used. Should have three fields, 'PtpntID', 'Session',
%   'IceUsed'. Each field contains a column vector, and all three column
%   vectors are the same size. Together they describe whether ice was used
%   for each participant and session.
% WaterBlocks: Matlab struct. Fields are as follows, and all contain either
%   vectors or cell vectors of the same length...
%       PtpntID
%       Sess
%       BlockNum: All and only blocks where a water immersion took place
%           are listed
%       TypeOfWater: vector of str. 'Ice water' or 'Room temprature water'
% permitUnknown: bool. If true, permit some entries to be set to the value
%   'Unknown' or 'Simulation'. In this case no comparison between the two 
%   representations is conducted.

% HISTORY
% 21.02.2023 Read through, including called functions

ptpntIDsInWaterBlocks = unique(WaterBlocks.PtpntID);

for iP = 1 : length(ptpntIDsInWaterBlocks)
    thisPtpntID = ptpntIDsInWaterBlocks(iP);
    
    relSessions = unique(...
        WaterBlocks.Sess(WaterBlocks.PtpntID == thisPtpntID));
    
    for iS = 1 : length(relSessions)
        thisSess = relSessions(iS);
        relEntriesInWaterBlocks = ...
            (WaterBlocks.PtpntID == thisPtpntID) & ...
            (WaterBlocks.Sess == thisSess);
        
        typeOfWater = unique(WaterBlocks.TypeOfWater(...
            relEntriesInWaterBlocks));
        
        if length(typeOfWater) ~= 1
            error(['Only one type of water should have been ', ...
                'used each session.'])
        end
        
        typeOfWater = typeOfWater{1};
        
        relEntriesInIceStruct = (IceStructure.PtpntID == thisPtpntID) & ...
            (IceStructure.Session == thisSess);
        assert(sum(relEntriesInIceStruct) == 1)
        iceUsed = IceStructure.IceUsed(relEntriesInIceStruct);
        
        if strcmp(typeOfWater, 'Ice water')
            assert(iceUsed)
        elseif strcmp(typeOfWater, 'Room temprature water')
            assert(~iceUsed)
        elseif any(strcmp(typeOfWater, {'Unknown', 'Simulation'})) ...
                && permitUnknown
            warning(['Skipping check that two water representations ', ...
                'are the same because at least one value wast ', ...
                'recorded as ''Unknown''.'])
        else
            error('Unrecognised type of water')
        end
    end
end







function [RealTrlDSet, modelName, ExtraSettings, iceMode] = ...
    processSimVarargs(basedOn, varargin)
% There are two functions which share the same varargs, and for which 
% these must be processed in the same way. 

% INPUT
% basedOn: string. Simulate based on randomly picked values ('randParams'), 
%   simulate based on fitted parameter values ('fittedParams'), or 
%   simulate based on optimal parameters ('theoryMax'). If use 'theoryMax' 
%   then also need to provde varargin{1}. If use 'fittedParams' then need 
%   to provide varargin{1} and varargin{2}.
% varargin{1}: TrlDSet. If basedOn=='fittedParams', then the simulations 
%   are based on model fits in this dataset. If basedOn=='theoryMax', then
%   key properties of the stimulus are extracted from TrlDSet and used to 
%   compute the optimal parameters.
% varargin{2}: number. If basedOn=='fittedParams', then this input
%   determines the fitted model to use to set the parameter values. 
%   Set to match the model number as numbered in TrlDSet.P(iP).Model (for 
%   the TrlDSet given in varargin{1})
% varargin{3}: struct. Allows to customise the properties of the simulated
%   stimulus (e.g. number of trials). Is passed as the settings structure 
%   to runExperiment.m. See the comments on that function for the avalaible
%   options.
% varargin{4}: str. 'halfIce' to mark half the sessions as corresponding to
%   ice sessions, or 'noIce' to mark all sessions as control sessions.
%   Defaults to 'halfIce'.


assert(length(varargin) == 1)
varargin = varargin{1};

if (~isempty(varargin)) && (~isempty(varargin{1}))
    RealTrlDSet = varargin{1};
    if strcmp(basedOn, 'randParams')
       error(['Random parameters were requested, but dataset was ', ...
           'also provided.'])
    end
else
    RealTrlDSet = [];
    if any(strcmp(basedOn, {'theoryMax', 'fittedParams'}))
        error('Need to specify the dataset to base simulations on')
    end
end

if (length(varargin)>1) && (~isempty(varargin{2}))
    modelName = varargin{2};
    if any(strcmp(basedOn, {'theoryMax'}))
       error('Model number does not need to be supplied in this case.')
    end
else
    modelName = [];
    if any(strcmp(basedOn, {'randParams', 'fittedParams'}))
        error('Need to specify which model to use')
    end
end

if (length(varargin)>2) && (~isempty(varargin{3}))
    ExtraSettings = varargin{3};
else
    ExtraSettings = struct();
end

if (length(varargin)>3) && (~isempty(varargin{4}))
    iceMode = varargin{4};
else
    iceMode = 'halfIce';
end

function runMatlabStep(configName, processingStep, varargin)
% Run an analysis step or several. 

% INPUT
% configName: str. Name of configuration to load from loadConfig
% processingStep: str. Name of set of analysis steps to run. See code 
%   for options
% varargin{1}: struct. Each fieldname is a option, and the corresponding 
%   value is a string giving the value for that option. See comments in the 
%   function for the processing step for the options avalaible.

% WRITING PROCESSING STEPS
% To use a processing step with this function, the associated function for
% running the step should be named "pStep_processingStep", where 
% "processingStep" is replaced with the actual name of the step. The
% function should accept one argument, which is a structure. This structure
% will have all the same fields as the structure passed as varargin{1}
% here, but additionally it will have fields 'Config' and 'Step' giving
% strings for the configName and processingStep respectively.

% HISTORY
% 2021-2022 JCT
% 07.02.2023 Read through

if (~isempty(varargin)) && (~isempty(varargin{1}))
    Options = varargin{1};
else
    Options = struct();
end

assert(~any(strcmp('Config', fieldnames(Options))))
Options.Config = configName;

assert(~any(strcmp('Step', fieldnames(Options))))
Options.Step = processingStep;

addRemoveAllSubpaths('add')

feval(['pStep_' processingStep], Options)

addRemoveAllSubpaths('remove')

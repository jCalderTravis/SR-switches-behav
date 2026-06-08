function [groups, uniqueGroups, uniqueGroupNames] = findGroupInfo(DSet)
% Find various information of the groups of participants in the dataset

% INPUT
% DSet: Dataset structure 

% OUPUT
% groups: cell array as long as the number of pariticipants. Contains
%   the string describing the group to which the participant belongs.
% uniqueGroups: cell array as long as the number of unique groups in sorted
%   order.
% uniqueGroupNames: cell array. Same as unique groups except that group
%   names are replaced with plot-friendly versions, if known.

hasGroup = false(length(DSet.P), 1);
for iP = 1 : length(DSet.P)
    hasGroup(iP) = isfield(DSet.P(iP).Spec, 'Group');
end

if ~any(hasGroup)
    groups = repmat({'no_group'}, length(DSet.P), 1);

elseif all(hasGroup)
    groups = cell(length(DSet.P), 1);
    
    for iP = 1 : length(DSet.P)
        groups{iP} = DSet.P(iP).Spec.Group;
    end
else
    error('Case not considered')
end

uniqueGroups = unique(groups);
    
likelyGroups = {'older_adults', 'young_adults'}';
correspondGroupNames = {'older adults', 'young adults'}';
if isequal(likelyGroups, uniqueGroups)
    uniqueGroupNames = correspondGroupNames;
else
    uniqueGroupNames = uniqueGroups;
end
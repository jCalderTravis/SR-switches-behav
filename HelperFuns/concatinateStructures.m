function CombinedStruct = concatinateStructures(StructA, StructB)
% StructA and StructB should be two structures with the same fields. This
% function loops through the fields, concatinating the arrays in each
% field. If StructA is an empty array this input will be ignored and
% StructB will be returned unchanged.

% HISOTRY
% 2021, JCT
% 07.02.2023 Read through, including called functions

if isempty(StructA)
    CombinedStruct = StructB;
else
    fields = fieldnames(StructA);
    for iField = 1 : length(fields)
        StructA.(fields{iField}) ...
            = [StructA.(fields{iField}); StructB.(fields{iField})];
    end
    CombinedStruct = StructA;
end

end

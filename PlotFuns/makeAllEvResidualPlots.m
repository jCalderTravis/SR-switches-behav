function Figs = makeAllEvResidualPlots(plotSaveDir, DSets, Options)
% Makes several evidence residuals plots

% INPUT
% plotSaveDir: string. Directory where plots should be saved
% DSets: struct. Keys are names of specific datasets and the values provide
%   those datasets in the standard format. The required keys depend on the
%   input 'type'. Possible keys are...
%       RealTrlDSet: Data in the standard format, that stores data at the
%           level of trials, for the real data, and that contains model
%           fitting results
%       SimTrlDSet: (optional) A simulated dataset, simulated based on
%           fitted parameter values from the dataset in RealTrlDSet.
%           Participants should match up in terms of order in RealTrlDSet.
%           Fewer plots will be made if not provided.
% Options: struct. Has the following keys:
%   ExtraIndividualPlots: bool. If true, makes some extra
%       plots on a individual participant basis.
%   SkipIce: bool. If true skip some plots of the effect of
%       ice.

% OUTPUT
% Figs: struct. Contains figure handles. Keys and values are...
%   Ev_resid_BLOCK: The figure for the main evidence residuals analysis, 
%       including model fits if requested. BLOCK is replaced with the name 
%       of the block type that the plot is for. If block contains '-' 
%       charachters these will be replaced by '_'.

if isequal(sort(fieldnames(DSets)), {'RealTrlDSet'})
    type = 'real';
elseif isequal(sort(fieldnames(DSets)), {'RealTrlDSet', 'SimTrlDSet'}')
    type = 'model';
else
    error('Inputs not permitted')
end

RealTrlDSet = DSets.RealTrlDSet;
if strcmp(type, 'model')
    SimTrlDSet = DSets.SimTrlDSet;
else
    assert(strcmp(type, 'real'))
end
Figs = struct();


%% Convert formats
RealCueDSet = convertDSet(RealTrlDSet);
RealCueDSet = computeCueDerivs(RealCueDSet);
RealStkdCueDSet = stackCueDSet(RealCueDSet);
if any(strcmp(type, {'model'}))
    SimCueDSet = convertDSet(SimTrlDSet);
    SimCueDSet = computeCueDerivs(SimCueDSet);
    SimStkdCueDSet = stackCueDSet(SimCueDSet);
end


%% Plot effect of the cues, both for the whole dataset, and for individuals

% Plots are done seperately for different blocks, so 
% merge blocks that are the same just in different locations
toMerge = {'full_task_scanner', 'full_task_lab'};
mergeName = 'full_task_anywhere';
RealStkdCueDSet = mergeBlocks(RealStkdCueDSet, toMerge, mergeName);
if strcmp(type, 'model')
    SimStkdCueDSet = mergeBlocks(SimStkdCueDSet, toMerge, mergeName);
else
    assert(strcmp(type, 'real'))
end

blkTypes = findUniqueBlkTypes(RealStkdCueDSet);
for iBT = 1 : length(blkTypes)

    if strcmp(blkTypes{iBT}, 'instructed')
        continue
    elseif strcmp(blkTypes{iBT}, 'inferred')
        incBlockName = false;
    else
        incBlockName = true;
    end
    
    relPtpnts = findPtpntsWithBlkType(RealStkdCueDSet, blkTypes{iBT});
    TrimRealStkdCueDSet = RealStkdCueDSet;
    TrimRealStkdCueDSet.P = TrimRealStkdCueDSet.P(relPtpnts);
    if any(strcmp(type, {'model'}))
        TrimSimStkdCueDSet = SimStkdCueDSet;
        TrimSimStkdCueDSet.P = TrimSimStkdCueDSet.P(relPtpnts);
    end
    
    % Whole dataset
    [~, expectedGroups, ~] = findGroupInfo(TrimRealStkdCueDSet);
    sigHeights = [-0.01 -0.02];
    if length(expectedGroups) == 1
        sigHeights = sigHeights(1);
    end
    assert(length(sigHeights) == length(expectedGroups))

    plotFun = @(TrimDSet, figHandle, colour, thisSigHeight) ...
        plotCueEffect(TrimDSet, 'scatter', false, blkTypes{iBT}, ...
            figHandle, colour, plotSaveDir, thisSigHeight, incBlockName);
    figHandle = plotSepByGroup(plotFun, TrimRealStkdCueDSet, ...
        expectedGroups, [], sigHeights);

    if any(strcmp(type, {'model'}))
        plotFun = @(TrimDSet, figHandle, colour, sigHeight) ...
            plotCueEffect(TrimDSet, 'errorShading', false, ...
                blkTypes{iBT}, figHandle, colour, [], [], incBlockName);
        plotSepByGroup(plotFun, TrimSimStkdCueDSet, expectedGroups, ...
            figHandle);
    end
    Figs.(['Ev_resid_', strrep(blkTypes{iBT}, '-', '_')]) = figHandle;
    mT_exportNicePdf(15.9/2, 15.9*(2/3), plotSaveDir, ...
        ['effectOfCues_' blkTypes{iBT}])
    
    % Individual participant plots
    if Options.ExtraIndividualPlots
        for iP = 1 : length(TrimRealStkdCueDSet.P)
            SingleRealStkdCueDSet = TrimRealStkdCueDSet;
            SingleRealStkdCueDSet.P = SingleRealStkdCueDSet.P(iP);
            figHandle = plotCueEffect(SingleRealStkdCueDSet, ...
                'scatterOnly', false, blkTypes{iBT});
            
            if any(strcmp(type, {'model'}))
                SingleSimStkdCueDSet = TrimSimStkdCueDSet;
                SingleSimStkdCueDSet.P = SingleSimStkdCueDSet.P(iP);
                plotCueEffect(SingleSimStkdCueDSet, 'line', false, ...
                    blkTypes{iBT}, figHandle);
            end
            mT_exportNicePdf(15.9/2, 15.9*(2/3), plotSaveDir, ...
                ['effectOfCues_ptpnt' num2str(iP) '_' blkTypes{iBT}])
        end
    end
end


%% Plot the effect of cues seperately for the ice vs. control
if ~Options.SkipIce
    figHandle = plotCueEffect(RealStkdCueDSet, 'scatter', true, ...
        'inferred');
    if any(strcmp(type, {'model'}))
        plotCueEffect(SimStkdCueDSet, 'errorShading', true, ...
            'inferred', figHandle)
    end
    mT_exportNicePdf(15.9/2, 15.9*(2/3), plotSaveDir, 'effectOfCuesAndIce')
end
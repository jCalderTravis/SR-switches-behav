function loadedData = loadData(config, dataAspect)
% Load some aspect of the data

% INPUT
% config: str. Name of configuration to load from loadConfig.
% dataAspect: str. What is loaded is determined by this string

if strcmp(dataAspect, 'relative_time_real_data')
    LoadOptions.Config = config;
    LoadOptions.Step = 'collateData';
    loadDir = findDir(LoadOptions, 'step');
    fname = [loadDir, 'DSet'];
    Loaded = load(fname);
    loadedData = Loaded.TrlDSet;
    
elseif any(strcmp(dataAspect, {'fitted_data', 'fitted_baseline_data'}))
    LoadOptions.Config = config;
    LoadOptions.Step = 'fitModel';
    
    if strcmp(dataAspect, 'fitted_baseline_data')
        LoadOptions.Condition = 'baseline';
    else
        assert(strcmp(dataAspect, 'fitted_data'))
    end
    
    loadFile = [findDir(LoadOptions, 'step') 'fittedDSet'];
    Loaded = load(loadFile);
    loadedData = Loaded.TrlDSet;
else
    error('Unrecognised option')
end
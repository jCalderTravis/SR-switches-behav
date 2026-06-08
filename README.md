# SR-switches-behav

## Overview

This repository contains the Matlab analysis pipeline used for the computational behavioural modelling in two projects:

Calder-Travis, van den Brink, Thawani, Schwabe & Donner (2026). Cortex-wide Dynamics of Internal Decisions About Behavioral Context. *eLife*. https://doi.org/10.7554/eLife.110682.1

Ribeiro, Calder-Travis, Canário, Castelo-Branco & Donner (2026). Impaired Sensory-motor Reconfiguration and Pupil-linked Arousal in Aging. *bioRxiv*. https://doi.org/10.64898/2026.06.01.729265



The main start point is `runMatlabStep.m`, which dispatches data processing, model fitting, simulation, and plotting via named processing steps.

## Using the code

- Open Matlab in the repository root.
- Copy `loadCoreDirs.example.m` to `loadCoreDirs.m`, then update the directory paths in this script for your local environment. This file defines the folders containing the data and the folders to be used for analysis output. Specifically:
    - CoreDirs.DataDir: The full path of the directory containing the data. 
    - CoreDirs.StepsResultsDir: Where intermediate analysis results will be saved.
    - CoreDirs.FinalResultsDir: Where final analysis results will be saved.
- You only need to update the paths for the `configName` that you will use. 
- The following options for `configName` can be used:
    - `mainStudy` for analysing data from the Calder-Travis et al. (2026) study, for which this code was originally written. (A previous option, `pilot`, is no longer in use.)
    - `coimbra` for analysing data from the Ribeiro et al. (2026) study, for which this code was extensively adapted.
- Run a processing step. For example:

```matlab
runMatlabStep('mainStudy', 'collateData');
```

## Common commands

```matlab
% Collate the behavioral data
runMatlabStep('mainStudy', 'collateData');

% Fit the models
runMatlabStep('mainStudy', 'fitModel');

% Generate event CSVs after fitting, containing data on key events and computational variables
runMatlabStep('mainStudy', 'makeEventsCsv');

% Plot the data
runMatlabStep('mainStudy', 'plot', struct('Plots', 'real'));
```

## Key files

- `runMatlabStep.m` - main analysis start point
- `loadConfig.m` - configurations for specific experiments
- `loadCoreDirs.example.m` - template for local directory configuration
- `loadModellingConfig.m` - configurations for computational modelling
- `ProcessingSteps/` - named processing routines


## Processing steps

`runMatlabStep` calls a processing step from the folder `ProcessingSteps/` following the naming convention `pStep_<stepName>`. Key processing steps:

- `collateData` - collates raw behavioural data and saves prepared datasets
- `fitModel` - fits behavioural models to the collated data
- `makeEventsCsv` - exports CSV files containing data on key events and computational variables derived from the model fitting
- `plot` - produces various plots
- `simulate` - generates simulated datasets based on fitted or theoretical models


## Code history
Written by Joshua Calder-Travis (partly using GitHub Copilot for tidying code), apart from submodules and code in folders "External" and "Code_from_others". Begun 2020.

function modelNum = modelNameToNum(TrlDSet, modelName)

models = mT_findAppliedModels(TrlDSet);
modelNum = find(strcmp(models, modelName));
assert(length(modelNum) == 1)
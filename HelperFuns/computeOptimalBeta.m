function optBeta = computeOptimalBeta(DSetSpec)

optBeta = DSetSpec.CueMeanDiff ./ (DSetSpec.CueSigma.^2); 
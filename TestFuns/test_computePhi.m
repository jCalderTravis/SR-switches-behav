function test_computePhi()

nSim = 10000;
H = rand(nSim, 1);
LPR_prev = randn(nSim, 1) * 100;
Phi_old = nan(nSim, 1);
Phi_robust = nan(nSim, 1);

for iT = 1 : nSim
    Phi_old(iT) = computePhi(LPR_prev(iT), H(iT), 'old');
    Phi_robust(iT) = computePhi(LPR_prev(iT), H(iT), 'robust');
end

compareVals(Phi_old, Phi_robust);

figure
scatter(Phi_old, Phi_robust)
refline(1, 0)
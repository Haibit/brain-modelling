%% exp01_qrd_lsl
close all;

nsamples = 1000;
noise = randn(nsamples,1);

a_coefs = [1 -1.6 0.95];
ncoefs = length(a_coefs);
x = filter(1,a_coefs,noise); % from Friedlander1982, case 1
figure;
plot(x);

% normalize x to unit variance
x = x/std(x);
disp(var(x/std(x))) % should be 1
figure;
plot(x)

%% Estimate the AR coefficients
M = 2;
[a_est, e] = lpc(x, M)

%% Estimate the Reflection coefficients from the AR coefficients
[~,~,k_est] = rlevinson(a_est,e)

%% Estimate the Reflection coefficients using the QRD-LSL algorithm
M = 2;
lambda = 0.99;
lf = QRDLSL(M,lambda);
Kb = zeros(M,nsamples);
Kf = zeros(M,nsamples);
for i=1:nsamples
    lf.update(x(i));
    Kb(:,i) = lf.Kb;
    Kf(:,i) = lf.Kf;
end

%% Compare true and estimated
k_true = repmat(k_est,1,nsamples);
k_true = [k_true; zeros(M-ncoefs,nsamples)];
scale = 1;

figure;
rows = M;
cols = 1;
for k=1:M
    subaxis(rows, cols, k,...
        'Spacing', 0, 'SpacingVert', 0, 'Padding', 0, 'Margin', 0.05);
    plot(1:nsamples, k_true(k,1:nsamples));
    hold on;
    plot(1:nsamples, scale*Kb(k,1:nsamples));
    plot(1:nsamples, scale*Kf(k,1:nsamples));
end
legend('true','Kb','Kf');
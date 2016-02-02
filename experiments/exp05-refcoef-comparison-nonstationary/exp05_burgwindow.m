%% exp05_burgwindow
close all;

% create the data
exp05_data

%% Estimate the Reflection coefficients using a windowed Burg's algorithm
i = 1;
lattice = [];

M = 2;
nwindow = 10;
lambda = 0;
lattice(i).alg = BurgWindow(M, nwindow, lambda);
lattice(i).scale = 1;
lattice(i).name = sprintf('BurgWindow M%d W%d lambda=%0.2f',M,nwindow,lambda);
i = i+1;

M = 2;
nwindow = 50;
lambda = 0;
lattice(i).alg = BurgWindow(M, nwindow, lambda);
lattice(i).scale = 1;
lattice(i).name = sprintf('BurgWindow M%d W%d lambda=%0.2f',M,nwindow,lambda);
i = i+1;

% estimate the reflection coefficients
lattice = estimate_reflection_coefs(lattice, x);

%% Compare true and estimated

figure;
plot_reflection_coefs(lattice, k_true);
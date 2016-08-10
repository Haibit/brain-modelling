%% exp32_benchmark_varnocoupling


%% set options
nsims = 20;
nchannels = 4;

order_est = 10;
lambda = 0.98;

verbosity = 0;

data_type = 'vrc-coupling0-fixed';
nsamples = 2000;
data_params = {'nsamples', nsamples};

% TODO add burg and nuttall strand

%% set up benchmark params

k=1;
sim_params = [];

ntrials = 5;
sim_params(k).filter = MCMTQRDLSL1(ntrials,nchannels,order_est,lambda);
sim_params(k).data = data_type;
sim_params(k).data_params = data_params;
sim_params(k).label = sim_params(k).filter.name;
k = k+1;

sim_params(k).filter = MQRDLSL1(nchannels,order_est,lambda);
sim_params(k).data = data_type;
sim_params(k).data_params = data_params;
sim_params(k).label = sim_params(k).filter.name;
k = k+1;

sim_params(k).filter = MQRDLSL2(nchannels,order_est,lambda);
sim_params(k).data = data_type;
sim_params(k).data_params = data_params;
sim_params(k).label = sim_params(k).filter.name;
k = k+1;

sigma = 10^(-1);
gamma = sqrt(2*sigma^2*nsamples*log(nchannels));
sim_params(k).filter = MLOCCD_TWL(nchannels,order_est,'lambda',lambda,'gamma',gamma);
sim_params(k).data = data_type;
sim_params(k).data_params = data_params;
sim_params(k).label = sim_params(k).filter.name;
k = k+1;

%% run
run_lattice_benchmark(...
    mfilename('fullpath'),...
    'name','',...
    'sim_params', sim_params,...
    'nsims', 20,...
    'noise_warmup', true,...
    'plot_avg_mse', true,...
    'plot_avg_nmse', true);




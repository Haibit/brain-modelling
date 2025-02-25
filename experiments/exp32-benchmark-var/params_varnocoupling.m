%% params_varnocoupling

%% set options
nsims = 20;
nchannels = 4;

order_est = 10;
lambda = 0.99;

verbosity = 0;

data_type = 'vrc-coupling0-fixed';
nsamples = 2000;
data_params = {'nsamples', nsamples};

% data_type = 'vrc-cp-ch2-coupling1-fixed';
% nsamples = 358;
% data_params = {};

% TODO add nuttall strand

%% set up benchmark params

k=1;
sim_params = [];

ntrials = 5;
sim_params(k).filter = MCMTQRDLSL1(nchannels,order_est,ntrials,lambda);
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

sim_params(k).filter = MQRDLSL3(nchannels,order_est,lambda);
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

sim_params(k).filter = MLOCCD_TWL(nchannels,order_est,'lambda',lambda,'gamma',gamma*2);
sim_params(k).data = data_type;
sim_params(k).data_params = data_params;
sim_params(k).label = sim_params(k).filter.name;
k = k+1;

sim_params(k).filter = MLOCCD_TWL2(nchannels,order_est,'lambda',lambda,'gamma',gamma);
sim_params(k).data = data_type;
sim_params(k).data_params = data_params;
sim_params(k).label = sim_params(k).filter.name;
k = k+1;

sim_params(k).filter = MCMTLOCCD_TWL2(nchannels,order_est,ntrials,'lambda',lambda,'gamma',gamma);
sim_params(k).data = data_type;
sim_params(k).data_params = data_params;
sim_params(k).label = sim_params(k).filter.name;
k = k+1;

sim_params(k).filter = MCMTLOCCD_TWL4(nchannels,order_est,ntrials,'lambda',lambda,'gamma',gamma);
sim_params(k).data = data_type;
sim_params(k).data_params = data_params;
sim_params(k).label = sim_params(k).filter.name;
k = k+1;

sim_params(k).filter = BurgVectorWindow(nchannels,order_est,'nwindow',30);
sim_params(k).data = data_type;
sim_params(k).data_params = data_params;
sim_params(k).label = sim_params(k).filter.name;
k = k+1;

sim_params(k).filter = BurgVectorWindow(nchannels,order_est,'nwindow',60);
sim_params(k).data = data_type;
sim_params(k).data_params = data_params;
sim_params(k).label = sim_params(k).filter.name;
k = k+1;

sim_params(k).filter = BurgVectorWindow(nchannels,order_est,'nwindow',60,'ntrials',5);
sim_params(k).data = data_type;
sim_params(k).data_params = data_params;
sim_params(k).label = sim_params(k).filter.name;
k = k+1;

sim_params(k).filter = BurgVector(nchannels,order_est,'nsamples',nsamples/4);
sim_params(k).data = data_type;
sim_params(k).data_params = data_params;
sim_params(k).label = sim_params(k).filter.name;
k = k+1;

sim_params(k).filter = BurgVector(nchannels,order_est,'nsamples',nsamples/2);
sim_params(k).data = data_type;
sim_params(k).data_params = data_params;
sim_params(k).label = sim_params(k).filter.name;
k = k+1;

sim_params(k).filter = BurgVector(nchannels,order_est,'nsamples',nsamples);
sim_params(k).data = data_type;
sim_params(k).data_params = data_params;
sim_params(k).label = sim_params(k).filter.name;
k = k+1;
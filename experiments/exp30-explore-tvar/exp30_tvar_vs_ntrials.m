%% exp30_tvar_vs_ntrials

%% set options
nsims = 20;
trials = [89 2 3 5 8 13 21 34 55];
ntrials_opts = length(trials);
ntrials_max = max(trials);

channels = [2 4 8 14];
nchannel_opts = length(channels);

order_est = 10;
lambda = 0.98;

verbosity = 0;

data_type = 'vrc-cp-ch2-coupling1-fixed';
data_type_params = {};
% data_type = 'vrc-cp-ch2-coupling2-rnd';
% data_type_params = {'time',358,'order',10};

%% set up benchmark params and run
for k=1:nchannel_opts
    nchannels = channels(k);

    sim_params = [];
    for j=1:ntrials_opts
        ntrials = trials(j);
        sim_params(j).filter = MCMTQRDLSL1(nchannels,order_est,ntrials,lambda);
        sim_params(j).data = data_type;
        sim_params(k).data_params = data_type_params;
        sim_params(j).label = sprintf('%d trials',ntrials);
    end
    
    % run 
    run_lattice_benchmark(...
        'outdir',sim_params(1).filter.name,...
        'basedir',mfilename('fullpath'),...
        'sim_params', sim_params,...
        'nsims', nsims,...
        'warmup_noise', true,...
        'plot_avg_mse', true,...
        'plot_avg_nmse', true);
    
    close all;
    
end
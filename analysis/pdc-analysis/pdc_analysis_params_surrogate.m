%% pdc_analysis_params_surrogate

params = [];
k=1;

%% aal-coarse-19-outer-nocer-plus2 envelope

% NOTE gamma parameter not stable in surrogateping step
% params(k).downsample = 4;
% params(k).metrics = {'diag'};
% params(k).ntrials = 20;
% params(k).order = 12;
% params(k).lambda = 0.99;
% params(k).gamma = 1e-6; % not stable
% params(k).normalization = 'allchannels';
% params(k).envelope = true;
% params(k).nresamples = 100;
% params(k).alpha = 0.05;
% params(k).null_mode = 'estimate_ind_channels';
% k = k+1;

% % GOOD config
% params(k).downsample = 4;
% params(k).metrics = {'euc','diag'};
% params(k).ntrials = 20;
% params(k).order = 11;
% params(k).lambda = 0.99;
% params(k).gamma = 1e-5;
% params(k).normalization = 'allchannels';
% params(k).envelope = true;
% params(k).nresamples = 100;
% params(k).alpha = 0.05;
% params(k).null_mode = 'estimate_ind_channels';
% k = k+1;

%NOTE null_mode estimate_all_channels can become unstable

%% aal-coarse-19-outer-nocer-plus2, envelope, eachchannel

% g 1e-6, l 0.99, order 13

% % NOTE: lambda = 0.995 gives very little in terms of output
% params(k).downsample = 4;
% params(k).metrics = {'diag','euc','info'};
% params(k).ntrials = 20;
% params(k).order = 7;
% params(k).lambda = 0.995;
% params(k).gamma = 0.38;
% params(k).normalization = 'eachchannel';
% params(k).envelope = true;
% params(k).prepend_data = 'flipdata';
% params(k).nresamples = 100;
% params(k).alpha = 0.05;
% params(k).null_mode = 'estimate_ind_channels';
% k = k+1;

% NOTE bayes opt: gamma 0.733, lambda 0.99, order 11

% new optimization: gamma 0.26, lambda 0.99, order 11, note just tried
% order 11 and lambda 0.99
% new optimization: gamma 0.01, lambda 0.99, order 11, note just tried
% order 11 and lambda 0.99 with [100 1] weighting
% new optimization: gamma 0.0008695, lambda 0.99, order 11, note just tried
% order 11 and lambda 0.99 with [600 1] weighting

params(k).downsample = 4;
% params(k).metrics = {'diag','euc','info'};
params(k).metrics = {'diag'};
params(k).ntrials = 20;
params(k).order = 10;
params(k).lambda = 0.94;
params(k).gamma = 1.72377e-06;
params(k).normalization = 'eachchannel';
params(k).envelope = true;
params(k).prepend_data = 'flipdata';
params(k).nresamples = 100;
params(k).alpha = 0.05;
params(k).null_mode = 'estimate_ind_channels';
k = k+1;

params(k).downsample = 4;
% params(k).metrics = {'diag','euc','info'};
params(k).metrics = {'diag'};
params(k).ntrials = 20;
params(k).order = 6;
params(k).lambda = 0.99;
params(k).gamma = 7.147e-5;
params(k).normalization = 'eachchannel';
params(k).envelope = true;
params(k).prepend_data = 'flipdata';
params(k).nresamples = 100;
params(k).alpha = 0.05;
params(k).null_mode = 'estimate_ind_channels';
k = k+1;

%% mode
mode = 'run';
flag_plot = true;
flag_surrogate = true;

%% set up eeg

stimulus = 'std';
subject = 3;
deviant_percent = 10;
patch_options = {...
    'patchmodel','aal-coarse-19',...
    'patchoptions',{'outer',true,'cerebellum',false,'flag_add_auditory',true}};

out = eeg_processall_beta(...
    stimulus,subject,deviant_percent,patch_options);

%% run variations
pdc_analysis_variations(...
    out.file_sources,...
    out.file_sources_info,...
    params,...
    'outdir',out.outdir_sources,...
    'mode',mode,...
    'flag_plot_seed',flag_plot,...
    'flag_plot_conn',flag_plot,...
    'flag_surrogate',flag_surrogate);

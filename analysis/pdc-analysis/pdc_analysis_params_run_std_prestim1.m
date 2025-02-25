%% pdc_analysis_params_run_std_prestim1

params = [];
k=1;

%% envelope, eachchannel, each trial for warmup
%% new optimization

params(k).downsample = 4;
params(k).metrics = {'diag'};
params(k).ntrials = 20;
params(k).order = ?;
params(k).lambda = 0.99;
params(k).gamma = 10^(-5);
params(k).normalization = 'eachchannel';
params(k).envelope = true;
params(k).prepend_data = 'none';
params(k).nresamples = 100;
params(k).alpha = 0.05;
params(k).null_mode = 'estimate_ind_channels';
k = k+1;

params(k).downsample = 4;
params(k).metrics = {'diag'};
params(k).ntrials = 20;
params(k).order = ?;
params(k).lambda = 0.99;
params(k).gamma = 10^(-4);
params(k).normalization = 'eachchannel';
params(k).envelope = true;
params(k).prepend_data = 'none';
params(k).nresamples = 100;
params(k).alpha = 0.05;
params(k).null_mode = 'estimate_ind_channels';
k = k+1;

params(k).downsample = 4;
params(k).metrics = {'diag'};
params(k).ntrials = 20;
params(k).order = ?;
params(k).lambda = 0.99;
params(k).gamma = 10^(-3);
params(k).normalization = 'eachchannel';
params(k).envelope = true;
params(k).prepend_data = 'none';
params(k).nresamples = 100;
params(k).alpha = 0.05;
params(k).null_mode = 'estimate_ind_channels';
k = k+1;

%% mode
% flag_run = false;
% flag_tune = true;
mode = 'tune';
flag_surrogate = false;

%% set up eeg

stimulus = 'std-prestim1';
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
    'flag_surrogate',flag_surrogate);

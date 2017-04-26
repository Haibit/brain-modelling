function [opt,labels] = tune_lattice_filter_bayesopt(outdir,tune_file,varargin)

p = inputParser();
p.StructExpand = false;
addRequired(p,'outdir',@ischar);
addRequired(p,'tune_file',@ischar);
addParameter(p,'opt_mode','',@ischar);
addParameter(p,'filter_params',[],@isstruct);
addParameter(p,'criteria_samples',[],@isnumeric);
parse(p,outdir,tune_file,varargin{:});

switch p.Results.opt_mode
    case 'MCMTLOCCD_TWL4_gamma'
        filter_params = {...
            p.Results.filter_params.nchannels,...
            p.Results.filter_params.norder,...
            p.Results.filter_params.ntrials,...
            'lambda',p.Results.filter_params.lambda};
        
        func_bayes = @(x) tune_lattice_filter(...
            tune_file,...
            outdir,...
            'filter','MCMTLOCCD_TWL4',...
            'filter_params',[filter_params, 'gamma',x(1)],...
            'run_options',{'warmup_noise', false,'warmup_data', false},...
            'criteria','minorigin_normerror_norm1coefs_time',...
            'criteria_samples',p.Results.criteria_samples);
        
        n = 1;
        ub = 100; %[gamma]
        lb = zeros(n,1);
        labels = {'gamma'};
    otherwise
        error('not implemented %s',p.Results.opt_mode);
end

[~,datadir,~] = fileparts(tune_file);
bayes_dir = fullfile(outdir,datadir);
if ~exist(bayes_dir,'dir')
    mkdir(bayes_dir);
end

params_bayes = [];
params_bayes.n_iterations = 10;
params_bayes.n_init_samples = 10;
params_bayes.verbose_level = 2; % 6 errors -> log file
params_bayes.log_filename = fullfile(bayes_dir,'bayesopt.log');
params_file = fullfile(bayes_dir,'bayesopt.dat');
% if exist(params_file,'file')
%     params_bayes.load_save_flag = 3;
%     params_bayes.load_filename = params_file;
% else
    params_bayes.load_save_flag = 2;
    params_bayes.save_filename = params_file;
% end
[opt,y] = bayesoptcont(func_bayes, n, params_bayes, lb, ub);

for i=1:length(labels)
    fprintf('set %s to %g\n',labels{i},opt(i));
end

end
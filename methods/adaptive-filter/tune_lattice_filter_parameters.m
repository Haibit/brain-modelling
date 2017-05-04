function tune_lattice_filter_parameters(tune_file,outdir,varargin)

p = inputParser();
p.StructExpand = false;
addRequired(p,'tune_file',@ischar);
addRequired(p,'outdir',@ischar);
addParameter(p,'filter','MCMTLOCCD_TWL4',@ischar);
addParameter(p,'ntrials',1,@isnumeric);
addParameter(p,'order',1:14,@isnumeric);
gamma_exp = -14:2:1;
default_gamma = [10.^gamma_exp 5 20 30];
default_gamma = sort(default_gamma);
addParameter(p,'gamma',default_gamma,@isnumeric);
default_lambda = [0.9:0.02:0.98 0.99];
addParameter(p,'lambda',default_lambda,@isnumeric);
addParameter(p,'run_options',{},@iscell);
addParameter(p,'criteria_samples',[],@(x) (length(x) == 2) && isnumeric(x));
addParameter(p,'plot',false,@islogical);
parse(p,tune_file,outdir,varargin{:});

nlambda = length(p.Results.lambda);
norder = length(p.Results.order);
% ngamma = length(p.Results.gamma);

tune_obj = LatticeFilterOptimalParameters(tune_file,p.Results.ntrials);
[~,tunename,~] = fileparts(tune_file);
tune_outdir = tunename;

% get data size info from tune_file
tune_data = loadfile(tune_file);
[nchannels,~,~] = size(tune_data);

filter_params = [];
filter_params.nchannels = nchannels;
filter_params.ntrials = p.Results.ntrials;
trials_dir = sprintf('trials%d',p.Results.ntrials);

lambda_opt = NaN(norder,1);
for i=1:norder
    order_cur = p.Results.order(i);
    filter_params.norder = order_cur;
    order_dir = sprintf('order%d',order_cur);
    
    gamma_opt = NaN(nlambda,1);
    for j=1:nlambda
        lambda_cur = p.Results.lambda(j);
        filter_params.lambda = lambda_cur;
        lambda_dir = sprintf('lambda%g',lambda_cur);
        
        % check if i've already optimized gamma for this lambda and order
        gamma_opt(j) = tune_obj.get_opt('gamma','order',order_cur,'lambda',lambda_cur);
        if ~isnan(gamma_opt(j))
            fprintf('already optimized gamma for order %d, lambda %g\n',order_cur,lambda_cur);
            continue;
        end
        
        gamma_opt(j) = tune_lattice_filter_gamma(...
            tune_file,...
            fullfile(outdir,tune_outdir,trials_dir,order_dir,lambda_dir),...
            'plot_gamma_fit',p.Results.plot,...
            'filter','MCMTLOCCD_TWL4',...
            'filter_params',filter_params,...
            'gamma',p.Results.gamma,...
            'run_options',p.Results.run_options,...
            'criteria_samples',p.Results.criteria_samples);
        tune_obj.set_opt('gamma',gamma_opt(j),'order',order_cur,'lambda',lambda_cur);
        
    end
    
    % check if i've already optimized lambda for this order
    lambda_opt(i) = tune_obj.get_opt('lambda','order',order_cur);
    if ~isnan(lambda_opt(i))
        fprintf('already optimized lambda for order %d\n',order_cur);
        continue;
    end
    filter_params = rmfield(filter_params,'lambda');
    
    % tune lambda
    lambda_opt(i) = tune_lattice_filter_lambda(...
        tune_file,...
        fullfile(outdir,tune_outdir,trials_dir,order_dir),...
        'plot_lambda',p.Results.plot,...
        'filter','MCMTLOCCD_TWL4',...
        'filter_params',filter_params,...
        'lambda',p.Results.lambda,...
        'gamma_opt',gamma_opt,...
        'run_options',p.Results.run_options,...
        'criteria_samples',p.Results.criteria_samples);
    tune_obj.set_opt('lambda',lambda_opt(i),'order',order_cur);
    
end

% check if i've already optimized order
order_opt = tune_obj.get_opt('order');
if isnan(order_opt)
    order_opt = tune_lattice_filter_order(...
        tune_file,...
        fullfile(outdir,tune_outdir,trials_dir),...
        'plot_order',p.Results.plot,...
        'filter','MCMTLOCCD_TWL4',...
        'filter_params',filter_params,...
        'order',p.Results.order,...
        'lambda_opt',lambda_opt,...
        'gamma_opt',gamma_opt,...
        'run_options',p.Results.run_options,...
        'criteria_samples',p.Results.criteria_samples);
    tune_obj.set_opt('order',order_opt);
end

fprintf('order opt: %d\n',order_opt);
lambda_opt = tune_obj.get_opt('lambda','order',order_opt);
fprintf('lambda opt: %g\n',lambda_opt);
gamma_opt = tune_obj.get_opt('gamma','lambda',lambda_opt,'order',order_opt);
fprintf('gamma opt: %g\n',gamma_opt);

end
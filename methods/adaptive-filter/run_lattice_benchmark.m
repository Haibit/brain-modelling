function outfile = run_lattice_benchmark(varargin)
%RUN_LATTICE_BENCHMARK benchmarks lattice algs against each other
%   RUN_LATTICE_BENCHMARK benchmarks lattice algs against each other on a
%   specific data set
%
%   Input
%   -----
%
%   Parameters
%   ----------
%   outdir (string, default = 'output/benchmark1')
%       output directory, used for output files for specific experiment name
%
%       this allows you to run multiple benchmark scripts in the same
%       folder with different parameters without overwriting/mixing results
%       from a previous benchmark
%   basedir (string, default = pwd)
%       base output directory, can be specified with a directory or an
%       m-file name, the output directory will be placed in this folder.
%       the default directory will be the current working folder.
%   sim_params (struct array)
%       array of benchmark parameters, including the following fields
%       filter (object)
%           filter Object
%       gen_params (cell array)
%           parameters for VARGenerator
%       gen_config_params (cell array)
%           parameters to configure VARGenerator
%       label (string)
%           data label for plots
%   warmup (cell array, default = {'noise'})
%       options for warming up the filter, which are executed in the order
%       provided, options: noise, data, flipdata
%   nsims (integer)
%       number of simulations to average
%   force (logical, default = false)
%       force recomputation
%   verbosity (integer, default = 0)
%       verbosity level
%
%   plot_avg_mse (logical, default = true)
%       flag for plotting the averge MSE over all simulations
%   plot_avg_nmse (logical, default = true)
%       flag for plotting the averge NMSE over all simulations
%   plot_sim_mse (logical, default = false)
%       flag for plotting the individual MSE
%   plot_sim_nmse (logical, default = false)
%       flag for plotting the individual NMSE
%   plot_coef_values (logical, default = false)
%       plot histogram of unique reflection coefficient values

%% parse inputs
p = inputParser();
addParameter(p,'outdir',fullfile('output','benchmark1'),@(x) ischar(x) && ~isempty(x));
addParameter(p,'basedir','',@ischar);
% options_data_name = {'var-no-coupling'};
% addParameter(p,'data_name','var-no-coupling',@(x) any(validatestring(x,options_data_name)));
addParameter(p,'sim_params',[]);
addParameter(p,'warmup',{'noise'},@iscell);
addParameter(p,'normalized',false,@islogical);
addParameter(p,'nsims',1,@isnumeric);
addParameter(p,'force',false,@islogical);
addParameter(p,'verbosity',0,@isnumeric);
addParameter(p,'plot_avg_mse',true,@islogical);
addParameter(p,'plot_avg_nmse',true,@islogical);
addParameter(p,'plot_sim_mse',false,@islogical);
addParameter(p,'plot_sim_nmse',false,@islogical);
addParameter(p,'plot_coef_values',false,@islogical);
p.parse(varargin{:});

% copy params
nsims = p.Results.nsims;
sim_params = p.Results.sim_params;
nsim_params = length(sim_params);

outdir = setup_outdir(p.Results.basedir,p.Results.outdir);

% create script name for save_fig_exp
[~,name,~] = fileparts(p.Results.outdir);
if isempty(name)
    % try again, without the separator at the end?
    [~,name,~] = fileparts(p.Results.outdir(1:end-1));
    if iempty(name)
        name = 'benchmark1';
    end
end
script_name = fullfile(outdir,[name '.m']);

% set up parfor
parfor_setup();

%% loop over params

% allocate mem
data_args = [];
large_error = zeros(nsim_params,nsims);
large_error_name = cell(nsim_params,nsims);
labels = cell(nsim_params,1);

outfile = cell(nsim_params,nsims);

for k=1:nsim_params
    
    % copy sim parameters
    sim_param = sim_params(k);
    
    % allocate mem
    trace = cell(nsims,1);
    estimate = cell(nsims,1);
    kf_true_sims = cell(nsims,1);
    
    % figure out how many trials per sim
    if isprop(sim_param.filter,'ntrials')
        ntrials = sim_param.filter.ntrials;
    else
        ntrials = 1;
    end
    
    % load data
    nchannels = sim_param.filter.nchannels;
    var_gen = VARGenerator(sim_param.gen_params{:});
    if isfield(sim_param,'gen_config_params') && ~var_gen.hasprocess
        var_gen.configure(sim_param.gen_config_params{:});
    end
    data_var = var_gen.generate('ntrials',nsims*ntrials);
    % get the data time stamp
    data_time = get_timestamp(var_gen.get_file());
    
    % copy data
    if p.Results.normalized
        sources = data_var.signal_norm;
    else
        sources = data_var.signal;
    end
    %data_true = data_var.true;
    data_true_kf = data_var.true.Kf;
    
    % set up slugs
    [~,data_file,~] = fileparts(var_gen.get_file());
    slug_data = strrep(data_file,'_','-');
    
    slug_filter = sim_param.filter.name;
    slug_filter = strrep(slug_filter,' ','-');
    
    outfile_temp = cell(nsims,1);
    parfor j=1:nsims
%     for j=1:nsims
        fresh = false;
        
        slug_data_filt = sprintf('%s-s%d-%s',slug_data,j,slug_filter);
        outfile_temp{j} = fullfile(outdir,[slug_data_filt '.mat']);
        
        if exist(outfile_temp{j},'file')
            % check freshness of data and filter analysis
            filter_time = get_timestamp(outfile_temp{j});
            if data_time > filter_time
                fresh = true;
            end
        end
        
        if p.Results.force || fresh || ~exist(outfile_temp{j},'file')
            fprintf('running: %s\n', slug_data_filt)
            
            trace = LatticeTrace(sim_param.filter,'fields',{'Kf'});
            
            ntime = size(sources,2);
            
            sim_idx_start = (j-1)*ntrials + 1;
            sim_idx_end = sim_idx_start + ntrials - 1;
            
            trace.run(sources(:,:,sim_idx_start:sim_idx_end),...
                'warmup',p.Results.warmup,...
                'verbosity',p.Results.verbosity,...
                'mode','none');
            
            trace.name = trace.filter.name;
            
            estimate{j} = trace.trace.Kf;
            kf_true_sims{j} = data_true_kf;
            
            % save data
            data = [];
            data.truth = data_true_kf;
            data.estimate = estimate{j};
            save_parfor(outfile_temp{j},data);
        else
            fprintf('loading: %s\n', slug_data_filt);
            % load data
            data = loadfile(outfile_temp{j});
            estimate{j} = data.estimate;
            if ~isfield(data,'truth')
                % NOTE for backwards compatibility
                data.truth = data_true_kf;
                save_parfor(outfile_temp{j},data);
            end
            kf_true_sims{j} = data.truth;
        end
        
        data_mse = mse_iteration(estimate{j},kf_true_sims{j});
        if any(data_mse > 10)
            large_error_name{k,j} = slug_data_filt;
            large_error(k,j) = true;
        end
    end
    
    outfile(k,:) = outfile_temp;
    
    % plot MSE for each sim
    if p.Results.plot_sim_mse
        for j=1:nsims
            h = figure;
            clf;
            plot_mse_vs_iteration(...
                estimate{j}, kf_true_sims{j},...
                'mode','log',...
                'labels',{sprintf('%s sim: %d',slug_filter,j)});
            % TODO fix labels
            drawnow;
            save_fig_exp(script_name,...
                'tag',sprintf('mse-%s-%s-s%d',sim_param.gen_params{1},slug_filter,j));
            close(h);
        end
    end
    
    % plot NMSE for each sim
    if p.Results.plot_sim_nmse
        for j=1:nsims
            h = figure;
            clf;
            plot_mse_vs_iteration(...
                estimate{j}, kf_true_sims{j},...
                'mode','log',...
                'normalized',true,...
                'labels',{sprintf('%s sim: %d',slug_filter,j)});
            % TODO fix labels
            drawnow;
            save_fig_exp(script_name,...
                'tag',sprintf('nmse-%s-%s-s%d',sim_param.gen_params{1},slug_filter,j));
            close(h);
        end
    end
    
    % plot unique reflection coefficient values
    if p.Results.plot_coef_values
        h = figure;
        clf;
        kf_unique = unique(kf_true_sims{1});
        hist(kf_unique,linspace(-1,1,20));
        drawnow;
%         save_fig_exp(script_name,...
%             'tag',sprintf('coefs-c%d-s%d',channels(i),j),...
%             'formats',{'png'});
        close(h);
    end
    
    data_args = [data_args {estimate kf_true_sims}];
    labels{k} = sim_param.label;
    
end

%% Plot MSE

if p.Results.plot_avg_mse
    h = figure('Position',[1 1 800 500]);
    clf;
    plot_mse_vs_iteration(...
        data_args{:},...
        'mode','log',...
        'labels',labels);
    drawnow;
    save_fig_exp(script_name,'tag','mse-all');
    
    ylim([10^(-4) 10^(0)]);
    drawnow;
    save_fig_exp(script_name,'tag','mse-all-axis');
end

if p.Results.plot_avg_nmse
    h = figure('Position',[1 1 800 500]);
    clf;
    plot_mse_vs_iteration(...
        data_args{:},...
        'mode','log',...
        'normalized',true,...
        'labels',labels);
    drawnow;
    save_fig_exp(script_name,'tag','nmse-all');
    
    ylim([10^(-2) 10^(3)]);
    drawnow;
    save_fig_exp(script_name,'tag','nmse-all-axis');
end

%% Print extra info
fprintf('large errors\n');
for k=1:nsim_params
    for j=1:nsims
        if large_error(k,j) > 0
            fprintf('\tfile: %s\n',large_error_name{k,j});
        end
    end
end

end
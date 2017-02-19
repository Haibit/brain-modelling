function run_benchmark_pdc(script_name,varargin)
%
%   Input
%   -----
%   script_name (string)
%       full file name of the benchmark script, including the extension
%
%       example:
%           script_name = [mfilename('fullpath') '.m'];
%
%       the path is used as the base folder for all outputs, so the
%       folder will look like
%
%       script_folder/
%           -> [name parameter]/    filtered data
%           -> img/                 plots generated by the benchmark
%
%   Parameters
%   ----------
%   data_name (string)
%       data generator name
%   data_params (cell array)
%       params for data generator
%   name (string, default = 'benchmark1')
%       benchmark name
%   sim_params (struct array)
%       array of benchmark parameters, including the following fields
%       filter (object)
%           filter Object
%   warmup_noise (logical, default = true)
%       flag for warming up the filter with noise, this helps with filter
%       initialization
%   warmup_data (logical, default = false)
%       flag for warming up the filter with simulated data, this helps with
%       filter initialization
%   warmup_data_ntrials (integer, default = 1)
%       selects number of trials to pass through filter for warmup, relevant
%       only if warmup_data = true
%   force (logical, default = false)
%       force recomputation
%   verbosity (integer, default = 0)
%       verbosity level
%
%   plot_pdc (logical, default = true)
%       flag for plotting the pdc for each filter

%% parse inputs
p = inputParser();
addRequired(p,'script_name',@ischar);
addParameter(p,'name','benchmark1',@ischar);
addParameter(p,'data_name','vrc-coupling0-fixed',@ischar);
addParameter(p,'data_params',{},@iscell);
addParameter(p,'sim_params',[]);
addParameter(p,'warmup_noise',true,@islogical);
addParameter(p,'warmup_data',false,@islogical);
addParameter(p,'warmup_data_ntrials',1,@isnumeric);
addParameter(p,'force',false,@islogical);
addParameter(p,'verbosity',0,@isnumeric);
addParameter(p,'plot_pdc',true,@islogical);
p.parse(script_name,varargin{:});

% copy params
sim_params = p.Results.sim_params;
nsim_params = length(sim_params);

[expdir,~,ext] = fileparts(p.Results.script_name);
if isempty(ext)
    error('missing file name in script_name');
end
if ~isempty(p.Results.name)
    outdir = fullfile(expdir,p.Results.name,'output');
else
    outdir = fullfile(expdir,'output');
end
if ~exist(outdir,'dir')
    mkdir(outdir);
end

% set up parfor
parfor_setup();

%% set up data

% figure out how many trials per sim
ntrials_max = 1;
for k=1:nsim_params
    if isprop(sim_params(k).filter,'ntrials')
        if sim_params(k).filter.ntrials > ntrials_max
            ntrials_max = sim_params(k).filter.ntrials;
        end
    end
end

if p.Results.warmup_data
    nsims_generate = 1 + p.Results.warmup_data_ntrials;
else
    nsims_generate = 1;
end

% load data
% NOTE i'm assuming all filters have the same number of channels
nchannels = sim_params(1).filter.nchannels;
var_gen = VARGenerator(p.Results.data_name, nchannels);
if ~isempty(p.Results.data_params) && ~var_gen.hasprocess
    var_gen.configure(p.Results.data_params{:});
end
data_var = var_gen.generate('ntrials',nsims_generate*ntrials_max);
% get the data time stamp
data_time = get_timestamp(var_gen.get_file());

% copy data
sources = data_var.signal;
if ~isfield(data_var.true,'Kf')
    % add both kf and kb coefs to the data file
    nsamples = size(data_var.signal,2);
    data_var.true = [];
    data_var.true.Kf = data_var.process.get_coefs_vs_time(nsamples,'Kf');
    data_var.true.Kb = data_var.process.get_coefs_vs_time(nsamples,'Kb');
    data = data_var;
    save(var_gen.get_file(),'data');
    clear data;
end
data_true = data_var.true;

% set up data slug
[~,data_file,~] = fileparts(var_gen.get_file());
slug_data = strrep(data_file,'_','-');

%% loop over params

% allocate mem
large_error = zeros(nsim_params,1);
large_error_name = cell(nsim_params,1);

estimate_kf = cell(nsim_params,1);
estimate_kb = cell(nsim_params,1);

parfor k=1:nsim_params
    
    % copy sim parameters
    sim_param = sim_params(k);
    if isprop(sim_param.filter, 'ntrials')
        ntrials = sim_param.filter.ntrials;
    else
        ntrials = 1;
    end
    
    % set up filter slug
    slug_filter = sim_param.filter.name;
    slug_filter = strrep(slug_filter,' ','-');
    
    fresh = false;
    
    slug_data_filt = sprintf('%s-%s',slug_data,slug_filter);
    outfile = fullfile(outdir,[slug_data_filt '.mat']);
    
    if exist(outfile,'file')
        % check freshness of data and filter analysis
        filter_time = get_timestamp(outfile);
        if data_time > filter_time
            fresh = true;
        end
    end
    
    if p.Results.force || fresh || ~exist(outfile,'file')
        fprintf('running: %s\n', slug_data_filt)
        
        trace = LatticeTrace(sim_param.filter,'fields',{'Kf','Kb'});
        
        ntime = size(sources,2);
        
        % warmup filter with noise
        if p.Results.warmup_noise
            noise = gen_noise(nchannels, ntime, ntrials);
            
            % run filter on noise
            warning('off','all');
            trace.warmup(noise);
            warning('on','all');
        end
        
        % warmup filter with simulated data
        if p.Results.warmup_data
            % use last
            sim_idx_start = ntrials + 1;
            sim_idx_end = sim_idx_start + ntrials - 1;
            
            % run filter on sim data
            warning('off','all');
            trace.warmup(sources(:,:,sim_idx_start:sim_idx_end));
            warning('on','all');
        end
        
        % run the filter on data
        warning('off','all');
        trace.run(sources(:,:,1:ntrials),...
            'verbosity',p.Results.verbosity,...
            'mode','none');
        warning('on','all');
        
        trace.name = trace.filter.name;
        
        estimate_kf{k} = trace.trace.Kf;
        estimate_kb{k} = trace.trace.Kb;
        
        % save data
        data = [];
        data.estimate.Kf = estimate_kf{k};
        data.estimate.Kb = estimate_kb{k};
        save_parfor(outfile,data);
    else
        fprintf('loading: %s\n', slug_data_filt);
        % load data
        data = loadfile(outfile);
        estimate_kf{k} = data.estimate.Kf;
        estimate_kb{k} = data.estimate.Kb;
    end
    
    data_mse = mse_iteration(estimate_kf{k},data_true.Kf);
    if any(data_mse > 10)
        large_error_name{k} = slug_data_filt;
        large_error(k) = true;
    end
end
    
if p.Results.plot_pdc
    % plot true pdc
    result = rc2pdc(squeeze(data_true.Kf(end,:,:,:)),squeeze(data_true.Kb(end,:,:,:)));
    window_title = 'Truth';
    plot_pdc(result,window_title);
    
    % save
    drawnow;
    save_fig_exp(script_name,...
        'tag',sprintf('pdc-%s-%s',p.Results.data_name,'truth'));
    close(gcf);
    
    for k=1:nsim_params
        
        % copy params
        sim_param = sim_params(k);
        
        % set up filter slug
        slug_filter = sim_param.filter.name;
        slug_filter = strrep(slug_filter,' ','-');
        
        % plot filter pdc
        result = rc2pdc(squeeze(estimate_kf{k}(end,:,:,:)),squeeze(estimate_kb{k}(end,:,:,:)));
        window_title = sim_param.filter.name;
        plot_pdc(result,window_title);
            
        % save
        drawnow;
        save_fig_exp(script_name,...
            'tag',sprintf('pdc-%s-%s',p.Results.data_name,slug_filter));
        close(gcf);
    end
end

%% Print extra info
if any(large_error > 0)
    fprintf('large errors\n');
    for k=1:nsim_params
        if large_error(k) > 0
            fprintf('\tfile: %s\n',large_error_name{k});
        end
    end
end

end

function plot_pdc(pdc_result,name)
flg_print = [1 0 0 0 0 0 0];
fs = 1;
w_max = fs/2;
ch_labels = [];
flg_color = 0;
flg_sigcolor = 1;

h=figure;
set(h,'NumberTitle','off','MenuBar','none', 'Name', name )
xplot(pdc_result,flg_print,fs,w_max,ch_labels,flg_color,flg_sigcolor);
end
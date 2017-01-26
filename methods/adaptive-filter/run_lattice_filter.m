function outfiles = run_lattice_filter(script_name,datain,varargin)
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
%   datain (matrix/string)
%       data matrix or filename that contains the data matrix
%       data should have the size [channels time trials]
%
%   Parameters
%   ----------
%   name (string, default = 'lf1')
%       analysis name
%   filters (cell array)
%       array of filter objects
%   warmup_noise (logical, default = true)
%       flag for warming up the filter with noise, this helps with filter
%       initialization
%   warmup_data (logical, default = false)
%       flag for warming up the filter with data, this helps with filter
%       initialization
%   force (logical, default = false)
%       force recomputation
%   verbosity (integer, default = 0)
%       verbosity level
%
%   plot_pdc (logical, default = true)
%       flag for plotting the pdc for each filter
%
%   Output
%   ------
%   outfiles (cell array)
%       cell array of file names, files contain filtered data for each
%       filter, same order as filters parameter

%% parse inputs
p = inputParser();
addRequired(p,'script_name',@ischar);
addRequired(p,'datain',@(x) isnumeric(x) || ischar(x));
addParameter(p,'name','lf1',@ischar);
addParameter(p,'filters',[]);
addParameter(p,'warmup_noise',true,@islogical);
addParameter(p,'warmup_data',false,@islogical);
addParameter(p,'force',false,@islogical);
addParameter(p,'verbosity',0,@isnumeric);
addParameter(p,'plot_pdc',true,@islogical);
p.parse(script_name,datain,varargin{:});

% copy filters
filters = p.Results.filters;
nfilters = length(filters);

[expdir,~,ext] = fileparts(p.Results.script_name);
if isempty(ext)
    error('missing file name in script_name');
end
if ~isempty(p.Results.name)
    outdir = fullfile(expdir,p.Results.name);
else
    outdir = fullfile(expdir,'output');
end
if ~exist(outdir,'dir')
    mkdir(outdir);
end

% set up parfor
setup_parfor();

%% set up data

% load data
if ischar(p.Results.datain)
    % from file
    datain = loadfile(p.Results.datain);
    if ~isnumeric(datain)
        error('data in .mat file must be a matrix');
    end
    data_time = get_timestamp(p.Results.datain);
else
    data_time = now();
end
data_dims = size(datain);
if length(data_dims) == 2
    data_dims(3) = 1;
end


%% loop over params

% allocate mem
large_error = zeros(nfilters,1);
large_error_name = cell(nfilters,1);

estimate_kf = cell(nfilters,1);
estimate_kb = cell(nfilters,1);

% copy fields for parfor, don't want to pass another copy of datain if it's
% a struct
options = copyfields(p.Results,[],{...
    'warmup_noise','warmup_data','force','verbosity'});

nchannels = filters{1}.nchannels;
outfiles = cell(nfilters,1);

parfor k=1:nfilters
% for k=1:nfilters
    
    % copy sim parameters
    filter = filters{k};
    if isprop(filter, 'ntrials')
        ntrials = filter.ntrials;
    else
        ntrials = 1;
    end
    
    if p.Results.warmup_data
        ntrials_req = 2*ntrials;
    else
        ntrials_req = ntrials;
    end
    
    % check data size and filter size
    if data_dims(1) ~= filter.nchannels
        error('channel mismatch between data and filter %s',filter.name);
    elseif data_dims(3) < ntrials_req
        fprintf('trials\n\trequired: %d\n\thave: %d\n',ntrials_req,data_dims(3));
        error('trial mismatch between data and filter %s',filter.name);
    end
    
    % set up filter slug
    slug_filter = filter.name;
    slug_filter = strrep(slug_filter,' ','-');
    outfile = fullfile(outdir,[slug_filter '.mat']);
    outfiles{k} = outfile;
    
    fresh = false;
    
    if exist(outfile,'file')
        % check freshness of data and filter analysis
        filter_time = get_timestamp(outfile);
        if data_time > filter_time
            fresh = true;
        end
    end
    
    if options.force || fresh || ~exist(outfile,'file')
        fprintf('running: %s\n', slug_filter)
        
        trace = LatticeTrace(filter,'fields',{'Kf','Kb'});
        
        ntime = size(datain,2);
        
        % warmup filter with noise
        if options.warmup_noise
            noise = gen_noise(nchannels, ntime, ntrials);
            
            % run filter on noise
            warning('off','all');
            try
                trace.warmup(noise);
            catch me
                msgText = getReport(me);
                warning('on','all');
                warning(msgText);
            end
            warning('on','all');
        end
        
        % warmup filter with simulated data
        if options.warmup_data
            % use last
            idx_start = ntrials + 1;
            idx_end = idx_start + ntrials - 1;
            
            idx_start_wu = 1;
            idx_end_wu = idx_start_wu + ntrials - 1;
            
            % warm up filter on some data
            warning('off','all');
            try
                trace.warmup(datain(:,:,idx_start_wu:idx_end_wu));
            catch me
                msgText = getReport(me);
                warning('on','all');
                warning(msgText);
            end
            warning('on','all');
        else
            idx_start = 1;
            idx_end = idx_start + ntrials - 1;
        end
        
        % run the filter on data
        warning('off','all');
        try
            trace.run(datain(:,:,idx_start:idx_end),...
                'verbosity',options.verbosity,...
                'mode','none');
        catch me
            msgText = getReport(me);
            warning('on','all');
            warning(msgText);
        end
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
        fprintf('loading: %s\n', slug_filter);
        % load data
        data = loadfile(outfile);
        estimate_kf{k} = data.estimate.Kf;
        estimate_kb{k} = data.estimate.Kb;
    end
    
    % check mse from 0
    data_true_kf = zeros(size(estimate_kf{k}));
    data_mse = mse_iteration(estimate_kf{k},data_true_kf);
    if any(data_mse > 10)
        large_error_name{k} = slug_filter;
        large_error(k) = true;
    end
end
    
if p.Results.plot_pdc
%     % plot true pdc
%     result = rc2pdc(squeeze(data_true.Kf(end,:,:,:)),squeeze(data_true.Kb(end,:,:,:)));
%     window_title = 'Truth';
%     plot_pdc(result,window_title);
%     
%     % save
%     drawnow;
%     save_fig_exp(script_name,...
%         'tag',sprintf('pdc-%s-%s',p.Results.data_name,'truth'));
%     close(gcf);
    
    for k=1:nfilters
        
        % copy params
        filter = filters{k};
        
        % set up filter slug
        slug_filter = filter.name;
        slug_filter = strrep(slug_filter,' ','-');
        
        % plot filter pdc
        result = rc2pdc(squeeze(estimate_kf{k}(end,:,:,:)),squeeze(estimate_kb{k}(end,:,:,:)));
        window_title = filter.name;
        plot_pdc(result,window_title);
            
        % save
        drawnow;
        save_fig_exp(script_name,...
            'tag',sprintf('pdc-%s',slug_filter));
        close(gcf);
    end
end

%% Print extra info
if any(large_error > 0)
    fprintf('large errors\n');
    for k=1:nfilters
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
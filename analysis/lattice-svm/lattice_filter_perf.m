function lattice_filter_perf(data_path, varargin)
%   Input
%   -----
%   data_path (string)
%       path for filtered data

%% parse inputs
p = inputParser();
addRequired(p,'data_path',@ischar);
p.parse(data_path,varargin{:});

fprintf('working on:\n%s\n',data_path);

% get data name
pattern = '(params_sd_[\d\w_]*)';
out = regexp(data_path,pattern,'tokens');
data_name = out{1}{1};

% get filter name
pattern = 'lf-([\d\w-]*)';
out = regexp(data_path,pattern,'tokens');
slug_filter = out{1}{1};
filter_name = strrep(slug_filter,'-',' ');

%% get true data

% get parameters
fh = str2func(data_name);
params = fh('mode','short');

% figure out which label
pattern = 'al-([\d\w]*)';
out = regexp(data_path,pattern,'tokens');
data_label = out{1}{1};

idx = 0;
for i=1:length(params.conds)
    if isequal(data_label,params.conds(i).label)
        idx = i;
        break;
    end
end

% load true coefficients
datafile_true = params.var_gen(idx).get_file();
data_true = loadfile(datafile_true);

var_gen_params = struct(params.var_gen_params{idx}{:});
truth = data_true.true;
% truth = data_true.process.get_coefs_vs_time(var_gen_params.time,'Kf');

%% get filtered data
pattern = fullfile(data_path,'lattice-filtered-id*.mat');
result = dir(pattern);

% prep truth
datafile = fullfile(data_path,result(1).name);
data = loadfile(datafile);
% check number of iterations
nsamples_true = size(truth,1);
nsamples_estimate = size(data.Kf,1);
if ~isequal(nsamples_true, nsamples_estimate)
    nsamples_extra = nsamples_true - nsamples_estimate;
    % remove some from the beginning
    truth(1:nsamples_extra,:,:,:) = [];
end
%check order
norder_true = size(truth,2);
norder_est = size(data.Kf,2);
if ~isequal(norder_true,norder_est)
    % pad with zeros
    norder_max = max(norder_true,norder_est);
    if norder_est < norder_max
        data.Kf(end,norder_max,end,end) = 0;
    end
    if norder_true < norder_max
        truth(end,norder_max,end,end) = 0;
    end
end

% allocate mem
ntrials = length(result);
data_mse = zeros(ntrials,1);
trial_idx = zeros(ntrials,1);

% for each filtered trial
% parfor i=1:ntrials
for i=1:ntrials
    datafile = fullfile(data_path,result(i).name);
    data = loadfile(datafile);
    
    % take nmse over all coefficients and all trials
    data_mse(i) = nmse(data.Kf(:), truth(:));
    
    % get trial id
    pattern = 'id(\d*)';
    out = regexp(result(i).name,pattern,'tokens');
    trial_idx(i) = str2double(out{1}{1});
end

%% plot overall nmse

% plot
h = figure;
scatter(trial_idx,data_mse,'filled');
title(sprintf('NMSE over Trials: %s',filter_name));
xlabel('Trials');
ylabel('NMSE');
ylim([10^(-1) 10^(3)]);
set(gca,'yscale','log');

% save dated and tagged file
drawnow;
save_fig2('path',data_path,...
    'tag',sprintf('nmse-%s',slug_filter),'formats',{'png'});
close(h);

%% plot nmse vs iteration for trial 1
idx = 1;
datafile = fullfile(data_path, result(idx).name);
data = loadfile(datafile);

% plot
h = figure;
plot_mse_vs_iteration(...
    data.Kf, truth,...
    'mode','log',...
    'normalized',true,...
    'labels',{filter_name});
ylim([10^(-1) 10^(3)]);

% save dated and tagged file
drawnow;
save_fig2('path',data_path,...
    'tag',sprintf('nmse-%s-trial%d',slug_filter,idx));
close(h);

%% plot rc for trial 1

mode = 'image-order';

h = figure;
plot_rc(data,'mode',mode);
% save dated and tagged file
drawnow;
save_fig2('path',data_path,...
    'tag',sprintf('rc-%s-%s-trial%d',mode,slug_filter,idx));
close(h);

truth2 = [];
truth2.Kf = truth;

h = figure;
plot_rc(truth2,'mode',mode);
% save dated and tagged file
drawnow;
save_fig2('path',data_path,...
    'tag',sprintf('rc-%s-truth',mode));
close(h);

end
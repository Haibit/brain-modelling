function tune_lambda(pipeline,outdir,varargin)

p = inputParser();
addRequired(p,'pipeline',@(x) isa(x,'ftb.AnalysisBeamformer'));
addRequired(p,'outdir',@ischar);
addParameter(p,'patch_type','aal',@ischar);
addParameter(p,'ntrials',10,@isnumeric);
addParameter(p,'order',6,@(x) isnumeric(x) && length(x) == 1);
addParameter(p,'lambda',[0.9:0.02:0.98 0.99],@(x) isnumeric(x) && isvector(x));
addParameter(p,'gamma',1e-2,@(x) isnumeric(x) && length(x) == 1);
addParameter(p,'normalization','allchannels',@ischar); % also none
addParameter(p,'envelope',false,@islogical); % also none
addParameter(p,'plot',true,@islogical);
addParameter(p,'plot_crit','normerrortime',@ischar);
addParameter(p,'plot_orders',[],@isnumeric);
parse(p,pipeline,outdir,varargin{:});

lf_file = pipeline.steps{end}.lf.leadfield;
sources_file = pipeline.steps{end}.sourceanalysis;

%% set lattice options
lf = loadfile(lf_file);
patch_labels = lf.filter_label(lf.inside);
patch_labels = cellfun(@(x) strrep(x,'_',' '),...
    patch_labels,'UniformOutput',false);
npatch_labels = length(patch_labels);
clear lf;

nchannels = npatch_labels;

%% set up filters
filters = {};
data_labels = {};
% tuning over lambdas
for k=1:length(p.Results.lambda)
    lambda_cur = p.Results.lambda(k);
    data_labels{k} = sprintf('lambda %0.4f',lambda_cur);
    filters{k} = MCMTLOCCD_TWL4(nchannels,p.Results.order,p.Results.ntrials,...
        'lambda',lambda_cur,'gamma',p.Results.gamma);
end

%% lattice filter

% set up parfor
parfor_setup('cores',12,'force',true);

verbosity = 0;
lf_files = lattice_filter_sources(filters, sources_file,...
    'normalization',p.Results.normalization,...
    'envelope',p.Results.envelope,...
    'tracefields',{'Kf','Kb','Rf','ferror','berrord'},...
    'verbosity',verbosity,...
    ...'samples',[1:100],...
    'ntrials_max',100,...
    'outdir', outdir);

%% plot criteria for each gamma
crit_all = {'aic','ewaic','normerrortime'};

if p.Results.plot
    for k=1:length(lf_files)
        view_lf = ViewLatticeFilter(lf_files{k});
        view_lf.compute(crit_all);
        
        switch p.Results.plot_crit
            case {'ewaic','ewsc','normerrortime'}
                view_lf.plot_criteria_vs_order_vs_time(...
                    'criteria',p.Results.plot_crit,...
                    'orders',1:p.Results.order);
            case {'aic','sc','norm'}
                view_lf.plot_criteria_vs_order(...
                    'criteria',p.Results.plot_crit,...
                    'orders',1:p.Results.order);
        end
    end
end

%% plot criteria for best order across gamma
if p.Results.plot
    view_lf = ViewLatticeFilter(lf_files,'labels',data_labels);
    view_lf.compute(crit_all);
    
    switch p.Results.plot_crit
        case {'ewaic','ewsc','normerrortime'}
            view_lf.plot_criteria_vs_order_vs_time(...
                'criteria',p.Results.plot_crit,...
                'orders',p.Results.plot_orders,...
                'file_list',1:length(lf_files));
        case {'aic','sc','norm'}
            view_lf.plot_criteria_vs_order(...
                'criteria',p.Results.plot_crit,...
                'orders',p.Results.plot_orders,...
                'file_list',1:length(lf_files));
    end
end

end
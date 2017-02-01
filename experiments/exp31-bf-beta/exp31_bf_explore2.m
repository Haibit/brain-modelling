%% exp31_bf_explore2

stimulus = 'std';
subject = 6;
deviant_percent = 10;
patches_type = 'aal';
% patches_type = 'aal-coarse-13';

script_name = mfilename('fullpath');
if isempty(script_name)
    [~,work_dir,~] = fileparts(pwd);
    if isequal(work_dir,'exp31-bf-beta')
        script_dir = pwd;
    else
        error('cd to exp31-bf-beta');
    end
else
    [script_dir,~,~] = fileparts([script_name '.m']);
end

%%
[~,data_name,~] = get_data_andrew(subject,deviant_percent);

data_name2 = sprintf('%s-%s',stimulus,data_name);
outdir = fullfile(script_dir,'output',data_name2);

params = {...
    'recompute', false,...
    'save', true,...
    'overwrite', true,...
    'outpath', outdir,...
    };

%% beamforming

pipeline = build_pipeline_beamformer(paramsbf_sd_andrew(...
    subject,deviant_percent,stimulus,'patches',patches_type)); 
pipeline.process();

%%

eeg_file = fullfile('output',data_name2,'ft_rejectartifact.mat');
lf = loadfile(pipeline.steps{end}.lf.leadfield);

%% convert source analysis to EEG data structure

sources_file = pipeline.steps{end}.sourceanalysis;
params2 = {sources_file, eeg_file, 'labels', lf.filter_label(lf.inside)};
params2 = [params2 params];
file_eeg = fthelpers.run_ft_function('fthelpers.ft_sources2trials',[],params2{:});

%% compute phase-locked avg

file_phaselocked = fthelpers.run_ft_function('fthelpers.ft_phaselocked',[],'datain',file_eeg,params{:});

%% compute induced response

params2 = {file_phaselocked};
params2 = [params2 params];
file_induced = fthelpers.run_ft_function('fthelpers.ft_induced',[],'datain',file_eeg,params2{:});


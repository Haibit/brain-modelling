% stimulus = 'std-triplet';
stimulus = 'std';
subject = 3;
deviant_percent = 10;

addpath(fullfile(get_project_dir(),'..','robust-eeg-beamforming-paper','core'));

%% output dir
params_data = DataBeta(subject,deviant_percent);

% dataset = data_file;
data_name2 = sprintf('%s-%s',stimulus,params_data.data_name);
comp_name = get_compname();
switch comp_name
    case {sprintf('Valentina\n')}
        analysis_dir = fullfile(params_data.data_dir, 'analysis', 'rmvb');
    otherwise
        analysis_dir = fullfile(get_project_dir(),'analysis','rmvb');
end
outdir = fullfile(analysis_dir,'output',data_name2);

%% preprocess data for beamforming
eeg_preprocessing_beta(subject,deviant_percent,stimulus,...
    'outdir',outdir);

%% beamform sources
% epsilon = 0.08; % one strong source top of the head
epsilon = 0.02;

params_subject = paramsbf_sd_beta_rmv(...
    subject,deviant_percent,stimulus,'epsilon',epsilon);

% set up pipeline folder
pipedir = fullfile(analysis_dir,'output','ftb');
pipeline = build_pipeline_beamformer_rmv(params_subject,pipedir); 
parfor_setup();
pipeline.process();
parfor_close();
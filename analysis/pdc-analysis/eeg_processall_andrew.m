function out = eeg_processall_andrew(stimulus,subject,deviant_percent,patches_type)
% all eeg processing for Andrew's data, top level function 

%% output dir

[data_file,data_name,~] = get_data_andrew(subject,deviant_percent);

% dataset = data_file;
data_name2 = sprintf('%s-%s',stimulus,data_name);
analysis_dir = fullfile(get_project_dir(),'analysis','pdc-analysis');
outdir = fullfile(analysis_dir,'output',data_name2);

%% preprocess data for beamforming
eeg_preprocessing_andrew(subject,deviant_percent,stimulus,...
    'outdir',outdir);

%% beamform sources
pipeline = build_pipeline_beamformer(paramsbf_sd_andrew(...
    subject,deviant_percent,stimulus,'patches',patches_type)); 
pipeline.process();

%% compute induced sources
eeg_file = fullfile(outdir,'ft_rejectartifact.mat');
lf_file = pipeline.steps{end}.lf.leadfield;
sources_file = pipeline.steps{end}.sourceanalysis;

eeg_induced(sources_file, eeg_file, lf_file, 'outdir',outdir);

%% prep data for lattice filter

eeg_file = fullfile(outdir,'fthelpers.ft_phaselocked.mat');
% NOTE eeg_file needed only for fsample
[file_sources_info,file_sources] = eeg_prep_lattice_filter(...
    sources_file, eeg_file, lf_file, 'outdir', outdir, 'patch_type', patches_type);

%% save outputs
out = [];
out.pipeline = pipeline;
out.outdir = outdir;
out.file_sources_info = file_sources_info;
out.file_sources = file_sources;

end
function pipeline = build_pipeline_beamformer(params_subject)
%BUILD_PIPELINE_BEAMFORMER builds beamformer pipeline
%
%   params_subject (string)
%       parameter file for subject data and beamformer configuration

%% set up output folder

% use folder common to all experiments to avoid recomputation
pipedir = get_data_andrew_pipeline();

% %% set up parallel pool
% parfor_setup();

%% get subject specific parameters

if ischar(params_subject)
    params_func = str2func(params_subject);
    params_sd = params_func();
else
    params_sd = params_subject;
    %params_subject = params_sd.name;
end

%% set up beamformer analysis

pipeline = ftb.AnalysisBeamformer(pipedir);


param_list = [];
k = 1;

param_list(k).field = 'mri';
param_list(k).class = 'MRI';
param_list(k).prefix = 'MRI';
k = k+1;

param_list(k).field = 'hm';
param_list(k).class = 'Headmodel';
param_list(k).prefix = 'HM';
k = k+1;

param_list(k).field = 'elec';
param_list(k).class = 'Electrodes';
param_list(k).prefix = 'E';
k = k+1;

param_list(k).field = 'lf';
param_list(k).class = 'Leadfield';
param_list(k).prefix = 'L';
k = k+1;

param_list(k).field = 'eeg';
param_list(k).class = 'EEG';
param_list(k).prefix = 'EEG';
k = k+1;

param_list(k).field = 'bf';
param_list(k).class = 'BeamformerPatch';
param_list(k).prefix = 'BFPatch';
k = k+1;

%% add analysis steps
for i=1:length(param_list)
    field = param_list(i).field;
    
    if isfield(params_sd,field)
        step_name = get_analysis_step_name(params_sd.(field),param_list(i).prefix);
        ftb_handle = str2func(['ftb.' param_list(i).class]);
        step = ftb_handle(params_sd.(field),step_name);
        
        % add step
        pipeline.add(step);
    else
        fprintf('missing %s params\n',field);
    end

end

% %% set up MRI
% step_name = get_analysis_step_name(params_sd.mri,'MRI');
% m = ftb.MRI(params_sd.mri,step_name);
% 
% % add step
% pipeline.add(m);
% 
% %% set up HM
% 
% step_name = get_analysis_step_name(params_sd.hm,'HM');
% hm = ftb.Headmodel(params_sd.hm,step_name);
% 
% % add step
% pipeline.add(hm);
% 
% %% set up Electrodes
% 
% step_name = get_analysis_step_name(params_sd.elec,'E');
% e = ftb.Electrodes(params_sd.elec,step_name);
% 
% % add step
% pipeline.add(e);
% e.force = false;
% 
% %     % Manually rename channel
% %     % NOTE This is why the electrodes are processed ahead of time
% %     elec = loadfile(e.elec_aligned);
% %     idx = cellfun(@(x) isequal(x,'Afz'),elec.label);
% %     if any(idx)
% %         elec.label{idx} = 'AFz';
% %         save(e.elec_aligned,'elec');
% %     end
% 
% % % Process pipeline
% % pipeline.init();
% % pipeline.process();
% 
% % e.plot({'scalp','fiducials','electrodes-aligned','electrodes-labels'});
% 
% %% set up Leadfield
% 
% step_name = get_analysis_step_name(params_sd.lf,'L');
% lf = ftb.Leadfield(params_sd.lf,step_name);
% 
% % add step
% pipeline.add(lf);
% 
% lf.force = false;
% 
% % Process pipeline
% % pipeline.init();
% % pipeline.process();
% 
% %% set up EEG
% 
% step_name = get_analysis_step_name(params_sd.eeg,'EEG');
% eeg = ftb.EEG(params_sd.eeg, step_name);
% 
% % add step
% pipeline.add(eeg);
% 
% %% set up Beamformer
% 
% step_name = get_analysis_step_name(params_sd.bf,'BFPatch');
% bf = ftb.BeamformerPatchTrial(params_sd.bf,step_name);
% 
% % add step
% pipeline.add(bf);

%% init pipeline
pipeline.init();

end
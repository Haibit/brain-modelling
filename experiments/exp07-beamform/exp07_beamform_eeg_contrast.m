%% exp07_beamform_eeg_contrast
% Goal: 
%   Beamform EEG, Standard stimulus with prestimulus contrast

close all;

doplot = true;

% subject specific info
[datadir,subject_file,subject_name] = get_coma_data(22);

subject_specific = true;
% subject_condition = 'std';
subject_condition = 'odd';
% option_elec = 'subject';

% use absolute directories
[srcdir,~,~] = fileparts(mfilename('fullpath'));

%% Set up beamformer analysis
% use folder common to all experiments to avoid recomputation
out_folder = fullfile(srcdir,'..','output-common','fb');
if ~exist(out_folder,'dir')
    mkdir(out_folder);
end

analysis = ftb.AnalysisBeamformer(out_folder);

%% Create and process MRI and HM

hm_type = 3;

switch hm_type
    case 1
        % MRI
        params_mri = 'MRIS01.mat';
        m = ftb.MRI(params_mri,'S01');
        
        % Headmodel
        params_hm = 'HMdipoli-cm.mat';
        hm = ftb.Headmodel(params_hm,'dipoli-cm');
        
        % Add steps
        analysis.add(m);
        analysis.add(hm);
        
        % Process pipeline
        analysis.init();
        analysis.process();
        
    case 2
        
        % MRI
        params_mri = 'MRIS01.mat';
        m = ftb.MRI(params_mri,'S01');
        
        % Headmodel
        params_hm = 'HMopenmeeg-cm.mat';
        hm = ftb.Headmodel(params_hm,'openmeeg-cm');
        
        % Add steps
        analysis.add(m);
        analysis.add(hm);
        
        % Process pipeline
        analysis.init();
        analysis.process();
        
    case 3
        % MRI
        params_mri = [];
        params_mri.mri_data = 'std';
        m = ftb.MRI(params_mri,'std');
        
        % Headmodel
        params_hm = [];
        params_hm.fake = '';
        hm = ftb.Headmodel(params_hm,'std-cm');
        
        % Add steps
        analysis.add(m);
        analysis.add(hm);
        
        % Process pipeline
        analysis.init();
        m.load_file('mri_mat', 'standard_mri.mat');
        m.load_file('mri_segmented', 'standard_seg.mat');
        m.load_file('mri_mesh', 'MRIS01.mat'); % fake this
        hm.load_file('mri_headmodel', 'standard_bem.mat');
        % process should ignore the files above
        analysis.process();
        
        hm.plot({'scalp','skull','brain','fiducials'});
end

%% Create and process the electrodes

% Electrodes
params_e = [];
if subject_specific
    params_e.elec_orig = fullfile(datadir,[subject_file '.sfp']);
else
    % Not sure what cap to use easycap-M1 has right channel names but
    % too many
    error('fix me');
end

e = ftb.Electrodes(params_e,subject_name);
e.set_fiducial_channels('NAS','NZ','LPA','LPA','RPA','RPA');
analysis.add(e);
e.force = false;

% Process pipeline
analysis.init();
analysis.process();
e.force = false;

% Manually rename channel
% NOTE This is why the electrodes are processed ahead of time
elec = loadfile(e.elec_aligned);
idx = cellfun(@(x) isequal(x,'Afz'),elec.label);
if any(idx)
    elec.label{idx} = 'AFz';
    save(e.elec_aligned,'elec');
end

e.plot({'scalp','fiducials','electrodes-aligned','electrodes-labels'});


%% Create the rest of the pipeline

% Leadfield
% params_lf = 'L1cm-norm.mat';
% lf = ftb.Leadfield(params_lf,'1cm-norm');
% params_lf = 'L1cm.mat';
% lf = ftb.Leadfield(params_lf,'1cm');
params_lf = [];
params_lf.ft_prepare_leadfield.normalize = 'no';
params_lf.ft_prepare_leadfield.tight = 'yes';
params_lf.ft_prepare_leadfield.grid.resolution = 1;
params_lf.ft_prepare_leadfield.grid.unit = 'cm';
lf = ftb.Leadfield(params_lf,'1cm-full');
analysis.add(lf);
lf.force = false;

% EEG
switch subject_condition
    case 'std'
        eeg_name = 'std';
    case 'odd'
        eeg_name = 'odd';
    otherwise
        error('unknown condition %s', subject_condition);
end

% EEG
params_eeg = [];
params_eeg.ft_definetrial = [];
params_eeg.ft_definetrial.dataset = fullfile(datadir,[subject_file '-MMNf.eeg']);
% use default function
switch subject_condition
    case 'std'
        params_eeg.ft_definetrial.trialdef.eventtype = 'Stimulus';
        params_eeg.ft_definetrial.trialdef.eventvalue = {'S 11'}; % standard
    case 'odd'
        params_eeg.ft_definetrial.trialdef.eventtype = 'Stimulus';
        params_eeg.ft_definetrial.trialdef.eventvalue = {'S 16'}; % standard
end
params_eeg.ft_definetrial.trialdef.prestim = 0.2; % in seconds
params_eeg.ft_definetrial.trialdef.poststim = 0.5; % in seconds

% assuming data was already de-artifacted
%params_eeg.ft_preprocessing.method = 'trial';
params_eeg.ft_preprocessing.continuous = 'yes';
params_eeg.ft_preprocessing.detrend = 'no';
params_eeg.ft_preprocessing.demean = 'yes';
%params_eeg.ft_preprocessing.baselinewindow = [-0.2 0];
params_eeg.ft_preprocessing.channel = 'EEG';

params_eeg.ft_timelockanalysis.covariance = 'yes';
params_eeg.ft_timelockanalysis.covariancewindow = 'all'; % should be default
params_eeg.ft_timelockanalysis.keeptrials = 'yes'; % should be default
params_eeg.ft_timelockanalysis.removemean = 'yes';

% specify pre post times
params_eeg.pre.ft_redefinetrial.toilim = [-0.2 0];
params_eeg.pre.ft_timelockanalysis.covariance = 'yes';
params_eeg.pre.ft_timelockanalysis.covariancewindow = 'all'; % should be default

params_eeg.post.ft_redefinetrial.toilim = [0 0.5];
params_eeg.post.ft_timelockanalysis.covariance = 'yes';
params_eeg.post.ft_timelockanalysis.covariancewindow = 'all'; % should be default

eeg_prepost = ftb.EEGPrePost(params_eeg,[eeg_name]);
analysis.add(eeg_prepost);
eeg_prepost.force = false;

% Beamformer - Common
params_bfcommon = [];
params_bfcommon.ft_sourceanalysis.method = 'lcmv';
params_bfcommon.ft_sourceanalysis.lcmv.keepmom = 'no';
params_bfcommon.ft_sourceanalysis.lcmv.keepfilter = 'yes';
bf_common = ftb.Beamformer(params_bfcommon,'common');
analysis.add(bf_common);
bf_common.force = false;

%% Set up contrast

params_bfcontrast = [];
params_bfcontrast.ft_sourceanalysis.method = 'lcmv';
params_bfcontrast.ft_sourceanalysis.lcmv.keepmom = 'yes';
bf_contrast = ftb.BeamformerContrast(params_bfcontrast,'');
analysis.add(bf_contrast);
bf_contrast.force = false;

%% Process pipeline
analysis.init();
analysis.process();

%eeg_prepost.print_labels();

%% Plot all results
% TODO Check individual trials
% bf.remove_outlier(10);

% figure;
% cfg = [];
% cfg.datafile = fullfile(datadir,datafile);
% cfg.continuous = 'yes';
% ft_databrowser(cfg);

% figure;
% cfg = loadfile(eeg_std.definetrial);
% ft_databrowser(cfg);


%% Here are important PSOM variables. Whenever needed, PSOM will call
%% this script to initialize the variables. If PSOM does not behave the way
%% you want, this might be the place to fix that.

gb_psom_gb_vars = true;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% The following variables need to be changed to configure the pipeline %%
%% system                                                               %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% how to invoke matlab   
gb_psom_command_matlab = [matlabroot filesep 'bin' filesep 'matlab']; 

% how to invoke octave
gb_psom_command_octave = [matlabroot filesep 'bin' filesep 'octave']; 

% Options for the sge qsub/msub/condor system. For condor, see the help of 
% psom_condor.sh 
% Example : '-q all.q@yeatman,all.q@zeus'
% will force qsub to only use the yeatman and zeus workstations through the
% queue called all.q
gb_psom_qsub_options = ''; 

% Options for the shell in batch, qsub, msub or condor modes
gb_psom_shell_options = ''; 

% Options for the execution mode of the pipeline 
%gb_psom_mode = 'session'; 
gb_psom_mode = 'background'; 

% Options for the execution mode of the pipeline manager
gb_psom_mode_pm = 'session'; 

% Options for the maximal number of jobs
gb_psom_max_queued = 8;

% Default number of attempts of re-submission for failed jobs
% [] is 0 for session, batch and background modes, and 1 for
% qsub/msub modes.
gb_psom_nb_resub = [];

% Initialization of matlab
gb_psom_init_matlab = '';

% Matlab search path. An empty value will correspond to the search path of
% the session used to invoke PSOM_RUN_PIPELINE. A value 'gb_psom_omitted'
% will result in no search path initiated (the default Octave path is
% used). 
gb_psom_path_search = '';

% where to store temporary files
gb_psom_tmp = tempdir; 
if ~strcmp(gb_psom_tmp(end),filesep)
    gb_psom_tmp = [gb_psom_tmp filesep];
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% The following variables should not be changed %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% PSOM version
gb_psom_version = '1.0.4'; % PSOM release number

% Is the environment Octave or Matlab ?
if exist('OCTAVE_VERSION','builtin')    
    % this is octave !
    gb_psom_language = 'octave'; 
else
    % this is not octave, so it must be matlab
    gb_psom_language = 'matlab'; 
end

% Options to start matlab
switch gb_psom_language
    case 'matlab'
        if ispc
            gb_psom_opt_matlab = '-automation -nodesktop -singleCompThread -r';
        else
            gb_psom_opt_matlab = '-nosplash -nodesktop -singleCompThread -r';
        end        
    case 'octave'
        gb_psom_opt_matlab = '--silent --eval';       
end
    
% Get langage version
if strcmp(gb_psom_language,'octave');
    gb_psom_language_version = OCTAVE_VERSION;
else
    gb_psom_language_version = version;
end 

% In which path is PSOM ?
str_gb_vars = which('psom_gb_vars');
if isempty(str_gb_vars)
    error('PSOM is not in the path ! (could not find PSOM_GB_VARS)')
end
gb_psom_path_psom = fileparts(str_gb_vars);
if strcmp(gb_psom_path_psom,'.')
    gb_psom_path_psom = pwd;
end
gb_psom_path_psom = [gb_psom_path_psom filesep];

% In which path is the PSOM demo ?
gb_psom_path_demo = cat(2,gb_psom_path_psom,'data_demo',filesep);

% What is the operating system ?
if isunix
    gb_psom_OS = 'unix';
elseif ispc
    gb_psom_OS = 'windows';
else
    warning('System %s unknown!\n',comp);
    gb_psom_OS = 'unkown';
end

% Getting user name.
switch (gb_psom_OS)
    case 'unix'
        gb_psom_user = getenv('USER');
        devnull = '1>/dev/null 2>&1';
    case 'windows'
        gb_psom_user = getenv('USERNAME');	
        devnull = '1>NUL 2>&1';
    otherwise
        gb_psom_user = 'unknown';
end

% Getting the local computer's name
switch (gb_psom_OS)
    case 'unix'
        [gb_psom_tmp_var,gb_psom_localhost] = system('uname -n');
        gb_psom_localhost = deblank(gb_psom_localhost);
    otherwise
        gb_psom_localhost = 'unknown';
end

% How to open pdf files, will choos the firte one to exist 
pdf_viewers = {'evince', 'xpdf', 'okular', 'acroread'};
nb_v = length(pdf_viewers);

for i = 1:nb_v

    l_cmd = [ pdf_viewers{i} ' --help ' devnull];
    [retcode, text] = system(l_cmd) ;
    if retcode ~= 127
        gb_psom_pdf_viewer = [ pdf_viewers{i}];
        break
    end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Any following line will be executed at the begining of every PSOM command and every job %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Uncomment the following line to load the image processing package in Octave

% pkg load image

%% Don't use more to verbose "on-the-fly" in Octave

% more off

%% Use .mat files compatible with Matlab in Octave

% default_save_options('-7');    

%% This is a bit of a dangerous option, but it makes things run faster in Octave. 
%% You'll have to exit octave and start again if you want any change in the functions to be 
%% taken into account.

% ignore_function_time_stamp ('all')  

%% Use the local configuration file if any, will overwite global config
if ~exist('gb_psom_gb_vars_local','var')&&exist('psom_gb_vars_local.m','file')		
    gb_psom_gb_vars_local = true;
    psom_gb_vars_local
    return
end

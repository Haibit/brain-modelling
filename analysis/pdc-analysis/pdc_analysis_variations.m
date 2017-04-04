function pdc_analysis_variations(params,varargin)

p = inputParser();
addRequired(p,'params',@isstruct);
addParameter(p,'flag_run',true,@islogical);
addParameter(p,'flag_tune',false,@islogical);
addParameter(p,'flag_tune_order',false,@islogical);
addParameter(p,'flag_tune_lambda',false,@islogical);
addParameter(p,'flag_tune_gamma',false,@islogical);
addParameter(p,'flag_tune_trials',false,@islogical);
addParameter(p,'flag_bootstrap',false,@islogical);
parse(p,params,varargin{:});


for i=1:length(params)
    
    stimulus = 'std';
    subject = 3;
    deviant_percent = 10;
    
    [pipeline,outdirbase] = eeg_processall_andrew(...
        stimulus,subject,deviant_percent,params(i).patch_type);
    
    % separate following output based on patch model
    outdir = fullfile(outdirbase,params(i).patch_type);
    
    if p.Results.flag_tune
        if p.Results.flag_tune_order
            % use parameters specified in params, 
            % otherwise use default from tune_model_order
            params2 = params(i);
            params2 = rmfield(params2,'metrics');
            
            params2.plot = true;
            params2.plot_crit = 'ewaic';
            %params2.plot_orders = params2.order;
            
            params_func = struct2namevalue(params2);
            tune_model_order(pipeline,outdir,params_func{:});
        end
        
        if p.Results.flag_tune_lambda
            % use parameters specified in params, 
            % otherwise use default from tune_lambda
            params2 = params(i);
            params2 = rmfield(params2,'metrics');
            
            params2.plot = true;
            params2.plot_crit = 'normtime';
            %params2.plot_orders = [1 2 3 4];
            
            params_func = struct2namevalue(params2);
            tune_lambda(pipeline,outdir,params_func{:});
        end
        
        if p.Results.flag_tune_gamma
            % use parameters specified in params, 
            % otherwise use default from tune_gamma
            params2 = params(i);
            params2 = rmfield(params2,'metrics');
            
            params2.plot = true;
            params2.plot_crit = 'normtime';
            %params2.plot_orders = [1 2 3 4];
            
            params_func = struct2namevalue(params2);
            tune_gamma(pipeline,outdir,params_func{:});
        end
        
        if p.Results.flag_tune_trials
            % use parameters specified in params, 
            % otherwise use default from tune_trials
            params2 = params(i);
            params2 = rmfield(params2,'metrics');
            
            params2.plot = true;
            params2.plot_crit = 'normtime';
            %params2.plot_orders = [1 2 3 4];
            
            params_func = struct2namevalue(params2);
            tune_trials(pipeline,outdir,params_func{:});
        end
        
    end
    
    if p.Results.flag_run
        % copy params
        params2 = params(i);
        % remove metrics field
        params2 = rmfield(params2,'metrics');
        
        % loop over metrics
        for j=1:length(params(i).metrics)
            
            %% compute RC with lattice filter
            % select lf params
            params_lf = copyfields(params2,[],...
                {'ntrials','order','lambda','gamma','normalization','envelope'});
            params_lf.tracefields = {'Kf','Kb','Rf','ferror'};
            % added Rf for info criteria
            % added ferror for bootstrap
            params_func = struct2namevalue(params_lf);
            [lf_files,sources_mini_file] = lf_analysis_main(pipeline, outdir, params_func{:});
            
            %% compute pdc
            downsample_by = 4;
            pdc_params = {...
                'metric',params(i).metrics{j},...
                'downsample',downsample_by,...
                };
            pdc_files = rc2pdc_dynamic_from_lf_files(lf_files,'params',pdc_params);
            
            %% view set up
            % select pdc view params
            params_pdc_view = copyfields(params2,[],...
                {'patch_type','envelope'});
            params_pdc_view.downsample = downsample_by;
            params_func = struct2namevalue(params_pdc_view);
            
            eeg_file = fullfile(outdirbase,'fthelpers.ft_phaselocked.mat');
            leadfield_file = pipeline.steps{end}.lf.leadfield;
            % create the ViewPDC obj
            view_obj = pdc_analysis_create_view(...
                pdc_files{1},eeg_file,leadfield_file,params_func{:});
            
            % add params for viewing
            params_plot_seed{1} = {'threshold',0.001};
            
            %% bootstrap
            if p.Results.flag_bootstrap
                pdc_sig_file = pdc_bootstrap(...
                    lf_files{1},...
                    'null_mode','estimate_ind_channels',...
                    'data_file',sources_mini_file,...
                    'nresamples',100,...
                    'alpha',0.05,...
                    'normalization',params2.normalization,...
                    'pdc_params',pdc_params);
                
                check_bt_data = false;
                if check_bt_data
                    %pdc_bootstrap_check(pdc_sig_file, sources_mini_file);
                    resample_idx = 1;
                    pdc_bootstrap_check_resample(pdc_sig_file,resample_idx,...
                        params_func{:},...
                        'eeg_file',eeg_file,'leadfield_file',leadfield_file);
                end
                
                view_sig_obj = pdc_analysis_create_view(...
                    pdc_sig_file,eeg_file,leadfield_file,params_func{:});
                
                if params(i).envelope
                    view_switch(view_sig_obj,'10')
                    % following views at 0-10 Hz
                else
                    view_switch(view_sig_obj,'beta')
                    % following views at 15-25 Hz
                end
                nchannels = length(view_sig_obj.info.label);
                
                directions = {'outgoing','incoming'};
                for direc=1:length(directions)
                    for ch=1:nchannels
                        
                        created = view_sig_obj.plot_seed(ch,...
                            'direction',directions{direc},...
                            'threshold_mode','numeric',...
                            'threshold',0.001,...
                            'vertlines',[0 0.5]);
                        
                        if created
                            view_sig_obj.save_plot('save',true,'engine','matlab');
                        end
                        close(gcf);
                    end
                end
                
                % add significance threshold data
                view_obj.pdc_sig_file = pdc_sig_file;
                
                params_plot_seed{2} = {'threshold_mode','significance'};
            end
            
            %% views
            if params(i).envelope
                view_switch(view_obj,'10')
                % following views at 0-10 Hz
            else
                view_switch(view_obj,'beta')
                % following views at 15-25 Hz
            end
            nchannels = length(view_obj.info.label);
            
            %% plot seed
            directions = {'outgoing','incoming'};
            for direc=1:length(directions)
                for ch=1:nchannels
                    for idx_param=1:length(params_plot_seed)
                        params_plot_seed_cur = params_plot_seed{idx_param};
                        
                        created = view_obj.plot_seed(ch,...
                            'direction',directions{direc},...
                            params_plot_seed_cur{:},...
                            'vertlines',[0 0.5]);
                        
                        if created
                            view_obj.save_plot('save',true,'engine','matlab');
                        end
                        close(gcf);
                    end
                end
            end
            
            
        end
    end
end

end
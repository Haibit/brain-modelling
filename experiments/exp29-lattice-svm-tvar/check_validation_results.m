%% check_validation_results.m


% code to run analysis pipeline
% only run batch mode on first pipeline run
% pipeline = build_pipeline_lattice_svm('params_sd_tvar_p8_ch13','mode','batch');
% pipeline.run();
% pipeline = build_pipeline_lattice_svm('params_sd_tvar_p8_ch13','mode','session');
% pipeline.run();

params_subject = 'params_sd_tvar_p8_ch13';
params_name = {...
    'params_lf_MQRDLSL2_p10_l099',...
    'params_lf_MLOCCDTWL_p10_l099',...
    'params_lf_MLOCCDTWL_p10_l098',...
    'params_lf_MCMTQRDLSL1_mt5_p10_l099',...
    'params_lf_MCMTQRDLSL1_mt5_p10_l098',...
    'params_lf_MCMTQRDLSL1_mt5_p10_l09',...
    'params_lf_MCMTLOCCDTWL2_mt5_p10_l099',...
    'params_lf_MCMTLOCCDTWL2_mt5_p10_l098',...
    };

if exist('pipeline','var')
    print_results_lattice_svm(params_subject,params_name,'tofile',true,'pipeline',pipeline);
else
    print_results_lattice_svm(params_subject,params_name,'tofile',true);
end

%% check lattice filter performance
conds = {...
    'al-std',...
    'al-odd',...
    };
filters = {...
    'lf-MQRDLSL2-p10-l099',...
    'lf-MLOCCDTWL-p10-l099',...
    'lf-MLOCCDTWL-p10-l098',...
    'lf-MCMTQRDLSL1-mt5-p10-l099',...
    'lf-MCMTQRDLSL1-mt5-p10-l098',...
    'lf-MCMTQRDLSL1-mt5-p10-l09',...
    'lf-MCMTLOCCDTWL2-mt5-p10-l099',...
    'lf-MCMTLOCCDTWL2-mt5-p10-l098',...
    };

for i=1:length(conds)
    for j=1:length(filters)
        if exist('pipeline','var')
            data_path = fullfile(pipeline.outdir,...
                conds{i},filters{j});
        else
            data_path = fullfile(get_project_dir(),'analysis','lattice-svm','output',...
                'params_sd_tvar_p8_ch13',conds{i},filters{j});
        end
        lattice_filter_perf(data_path);
    end
end

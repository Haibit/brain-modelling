%% check_results.m

ft_options = {...
    'params_fv_20',...
    'params_fv_40',...
    'params_fv_60',...
    'params_fv_100',...
    ...'params_fv_1000',...
    ...'params_fv_2000',...
    ...'params_fv_10000',...
    };

for i=1:length(ft_options)
    
    fprintf('%s\n\t',ft_options{i});
    
    file_features = 'output/lattice-svm/P022-9913/st3fm-params-fm-1/features-matrix.mat';
    file_validated = ['output/lattice-svm/P022-9913/st4fv-'...
        strrep(ft_options{i},'_','-') '/features-validated.mat'];
    
    % load the data
    features = ftb.util.loadvar(file_features);
    validated = ftb.util.loadvar(file_validated);
    
    perf = svmmrmr_class_accuracy(features.class_labels, validated.predictions,...
        'verbosity',1);
    
    figure;
    plot_svmmrmr_confusion(features.class_labels, validated.predictions);
end
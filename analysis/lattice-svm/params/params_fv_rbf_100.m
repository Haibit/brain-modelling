function params = params_fv_rbf_100()

params = {...
    'KernelFunction', 'rbf',...
    'BoxConstraintParams', exp(-5:5),...
    'KernelScaleParams' ,exp(-5:5),...
    'nfeatures', 100,...
    'nbins', 20,...
    'verbosity', 1,...
    };

end
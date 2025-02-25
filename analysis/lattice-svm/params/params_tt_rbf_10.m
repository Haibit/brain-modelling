function params = params_tt_rbf_10()

params = {...
    'KernelFunction', 'rbf',...
    'BoxConstraintParams', exp(-5:5),...
    'KernelScaleParams' ,exp(-5:5),...
    'nfeatures_common', 10,...
    'verbosity', 1,...
    };

end
function plot_svmmrmr_confusion(file_features, file_validated)
%PLOT_SVMMRMR_CONFUSION plot confusion matrix for SVMMRMR output file
%   PLOT_SVMMRMR_CONFUSION plot confusion matrix for SVMMRMR output file
%   generated by bricks.lattice_feature_matrix and bricks.features_validate
%
%   Input
%   -----
%   file_features (string)
%       name of features data file
%   file_validated (string)
%       name of validated features data file

p = inputParser;
addRequired(p,'file_features',@ischar);
addRequired(p,'file_validated',@ischar);
parse(p,file_features,file_validated);

% load the data
features = ftb.util.loadvar(p.Results.file_features);
validated = ftb.util.loadvar(p.Results.file_validated);

% plot confusion matrix
[confusion_mat, confusion_order] = confusionmat(features.class_labels, validated.predictions);

heatmap(confusion_mat, confusion_order, confusion_order, 1,...
    'Colormap','red','ShowAllTicks',1,'UseLogColorMap',true,'Colorbar',true);

end

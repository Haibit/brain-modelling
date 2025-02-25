function plot_rc_feature_matrix(data,varargin)
%PLOT_RC_FEATURE_MATRIX plots reflection coefficients from feature mtrix
%   PLOT_RC_FEATURE_MATRIX(data,...) plots reflection coefficients from
%   feature mtrix
%
%   Input
%   -----
%   data (struct)
%       data struct from bricks.features_matrix step, requires the
%       following fields:
%
%       feature_labels (cell array) 
%           feature labels
%       samples (matrix)
%           feature matrix with size [samples features]
%       class_labels (vector)
%           class labels for each sample
%
%   Parameters
%   ----------
%   mode (string, default = 'mean')
%       plotting mode
%       raw
%           plots raw reflection coefficients feature matrix
%       mean
%           plots mean of all reflection coefficients vs time
%       std
%           plots std of all reflection coefficients vs time
%       boxplot
%           plots boxplot for all reflection coefficients at each time
%           point
%       diff-mean
%           plots the difference in the mean
%       diff-median
%           plots the difference in the median
%
%   clim (vector or 'none', default = [-1.5 1.5])
%       color limits for image plots
%
%   abs (logical, default = false)
%       plots absolute value of coefficients
%
%   threshold (numeric or 'none', default = 'none')
%       reflection coefficients outside of this range are set to NaNs

p = inputParser();
p.KeepUnmatched = true;
addRequired(p,'data',@isstruct);
addParameter(p,'mode','mean',@ischar);
% p.addParameter('clim',[-1.5 1.5],@(x) isvector(x) || isequal(x,'none'));
% p.addParameter('abs',false,@islogical);
% p.addParameter('threshold','none',@(x) isnumeric(x) || isequal(x,'none'));
p.parse(data,varargin{:});

switch p.Results.mode
    case 'raw'
        plot_rc_feature_matrix_raw(data);
    case 'boxplot'
        params = struct2namevalue(p.Unmatched);
        plot_rc_feature_matrix_boxplot(data,params{:});
    case {'mean','std','median'}
        plot_rc_feature_matrix_stat(data,'stat',p.Results.mode);
    case 'diff-mean'
        plot_rc_feature_matrix_diff(data,'measure','mean');
    case 'diff-median'
        plot_rc_feature_matrix_diff(data,'measure','median');
    otherwise
        error('unknwon plot mode %s',p.Results.mode);
end

end
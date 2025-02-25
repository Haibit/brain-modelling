function plot_mse_vs_iteration(varargin)
%PLOT_MSE_VS_ITERATION plot MSE vs iteration
%   PLOT_MSE_VS_ITERATION(estimate1,truth1 [,estimate2,truth2,...])
%
%   Input
%   -----
%   estimate (matrix/cell)
%       estimated values, size [iteration variables]
%
%       multiple simulations can also be included as a cell array, with
%       each cell containing the estimated values for one simulation
%
%   truth (matrix)
%       true values, size [iteration variables]
%
%   Parameters
%   ----------
%   mode (string, default = 'plot')
%       plotting mode
%       'plot' - plots data with plot function
%       'log' - plots data with semilogy function
%   labels (cell array)
%       labels for legend
%   normalized (boolean, default = false)
%       selects normalized or unnormalized MSE

% parse data inputs
ndata = 1;
while ndata <= nargin
    if ischar(varargin{ndata})
       break;
    else    
        ndata = ndata + 1;
    end
end
data = varargin(1:ndata-1);

% parse plot options
p = inputParser;
addParameter(p,'labels',{},@iscell);
addParameter(p,'normalized',false,@islogical);
params_mode = {'plot','log'};
addParameter(p,'mode','plot',@(x)any(validatestring(x,params_mode)));
parse(p,varargin{ndata:end});

ndata = ndata-1;
if iscell(data{1})
    nsims = length(data{1});
else
    nsims = 1;
end

nplots = ndata/2;
if nplots <= 5
    cc = [1 0 0;% red
        0 0 1; % blue
        0 1 0; % green
        1 0 1; % magenta
        1 0.5 0; % orange
        ];
else
    cc = jet(nplots);
end
line_types_default = {'-',':','-.','--'};
line_types = repmat(line_types_default,1,ceil(nplots/4));
j = 1;
h = [];
for i=1:2:ndata
    data_mse = mse_iteration(data{i},data{i+1},'normalized',p.Results.normalized);
    if nsims > 1
        % average over sims
        data_mse = mean(data_mse,2);
    end
    
    niter = size(data_mse,1);
    switch p.Results.mode
        case 'log'
            h(j) = semilogy(1:niter,data_mse,line_types{j},'Color',cc(j,:),'LineWidth',2);
        case 'plot'
            h(j) = plot(1:niter,data_mse,line_types{j},'Color',cc(j,:),'LineWidth',2);
    end
    hold on;
    
    j = j+1;
end

if p.Results.normalized
    ylabel('NMSE');
else
    ylabel('MSE');
end
xlabel('Iteration');

if ~isempty(p.Results.labels)
    legend(h,p.Results.labels);%,'Location','BestOutside');
end

end

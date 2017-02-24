function plot_criteria_vs_order_vs_time(obj,varargin)
%PLOT_ESTERROR_VS_ORDER_VS_TIME plots filter order vs estim. error vs time
%   PLOT_ESTERROR_VS_ORDER_VS_TIME(...) plots filter order vs estimation
%   error vs time
%
%   Parameters
%   -----
%   criteria (string, default = 'ewaic')
%       criteria to plot
%   orders (vector)
%       list of orders to use in plot
%   file_list (vector, default = 1)
%       indices of files whose data should be plotted

p = inputParser();
addParameter(p,'criteria','ewaic',...
    @(x) any(validatestring(x,{'ewaic','ewsc','normtime'})));
addParameter(p,'orders',[],@isvector);
addParameter(p,'file_list',[],@isvector);
parse(p,varargin{:});

params = struct2namevalue(p.Results);
data_crit = obj.get_criteria(params{:});

ndata = length(data_crit.legend_str);
nfiles = length(data_crit.f);
nsamples = size(data_crit.f{1},2);

% create figure name
[~,name,~] = fileparts(obj.datafiles{1});
name = strrep(name,'-',' ');
name = strrep(name,'_','-');
if nfiles > 1
    out = sprintf('%s-', obj.datafile_labels{:});
    name = [name '-' out(1:end-1)];
end

screen_size = get(0,'ScreenSize');
figure('Position',screen_size,'Name',name);
colors = get_colors(ndata,'jet');
markers = {'o','x','+','*','s','d','v','^','<','>','p','h'};
linetypes = {'-',':','-.','--'};

nrows = 2;
ncols = 2;
plot_idx = 0;
for i=1:nrows
    for j=1:ncols
        plot_idx = plot_idx + 1;
        subplot(nrows,ncols,plot_idx);
        hold on;
        
        title_str = {};
        switch i
            case 1
                data = data_crit.f;
                title_str{1} = sprintf('Forward IC - %s',upper(p.Results.criteria));
                ylabel_str = 'IC';
            case 2
                data = data_crit.b;
                title_str{1} = sprintf('Backward IC - %s',upper(p.Results.criteria));
                ylabel_str = 'IC';
        end
        
        if j==1
            % plot IC vs samples
            h = zeros(ndata,1);
            count = 1;
            ymax = zeros(nfiles,1);
            ymin = zeros(nfiles,1);
            for file_idx=1:nfiles
                norders = size(data{file_idx},1);
                for k=1:norders
                    h(count) = plot(1:nsamples,data{file_idx}(k,:),...
                        linetypes{file_idx},...
                        'Color',colors(count,:));
                    count = count + 1;
                end
                
                idx = ceil(nsamples*0.05);
                ymax(file_idx) = max(data{file_idx}(:,idx));
                ymin(file_idx) = min(data{file_idx});
            end
            
            % labels
            xlabel('Sample');
            legend(h,data_crit.legend_str);
            
            % adjust axes
            xlim([1 nsamples]);
            ylim([min(ymin) max(ymax)]*1.1);
        end
        
        if j==2
            % plot last IC vs order
            h = zeros(nfiles,1);
            for file_idx=1:nfiles
                h(file_idx) = plot(data_crit.order_lists{file_idx},data{file_idx}(:,nsamples),...
                    ['-' markers{file_idx}]);
            end
            
            xlabel('Order');
            title_str{2} = sprintf('sample %d',nsamples);
            if nfiles > 1
                legend(h,obj.datafile_labels);
            end
        end
        
        % add labels
        ylabel(ylabel_str);
        
        if ~isempty(title_str)
            title(title_str);
        end
        
    end
end

end
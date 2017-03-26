function plot_seed(obj,chseed,varargin)

p = inputParser();
addRequired(p,'chseed',@isnumeric);
addParameter(p,'direction','outgoing',@(x) any(validatestring(x,{'outgoing','incoming'})));
addParameter(p,'vertlines',[],@isvector);
addParameter(p,'threshold',0.05,@(x) x >= 0 && x <= 1);
addParameter(p,'threshold_mode','numeric',@(x) any(validatestring(x,{'numeric','significance','significance_alpha'})));
% addParameter(p,'save',false,@islogical);
% addParameter(p,'outdir','',@ischar);
parse(p,chseed,varargin{:});

obj.save_tag = [];
obj.load('pdc');
obj.check_info();

switch p.Results.threshold_mode
    case {'significance','significance_alpha'}
        obj.load('pdc_sig');
end

[nsamples,nchannels,~,nfreqs] = size(obj.pdc);
    
w = 0:nfreqs-1;
w = w/(2*nfreqs);

w_idx = (w >= obj.w(1)) & (w <= obj.w(2));
% nfreqs_selected = sum(w_idx);
% threshold = p.Results.threshold_pct*nfreqs_selected;
f = w(w_idx)*obj.fs;
freq_idx = 1:nfreqs;
freq_idx = freq_idx(w_idx);

label_seed = obj.info.label{p.Results.chseed};

data_plot = zeros(nchannels,nsamples);
yticklabel = cell(nchannels,1);
count = 1;
tag_threshold = '';
for i=1:nchannels
    if i == p.Results.chseed
        % skip the diagonals, not informative
        continue;
    end
    
    switch p.Results.direction
        case 'outgoing'
            data_temp = squeeze(obj.pdc(:,i,p.Results.chseed,freq_idx));
        case 'incoming'
            data_temp = squeeze(obj.pdc(:,p.Results.chseed,i,freq_idx));
    end
    
    % threshold data
    switch p.Results.threshold_mode
        case 'numeric'
            % zero out everything that doesn't meet the threshold
            data_temp(data_temp < p.Results.threshold) = 0;
            tag_threshold = sprintf('thresh%0.2f',p.Results.threshold);
        case 'significiance'
            % zero out everything that doesn't meet the threshold
            data_temp(data_temp < obj.pdc_sig) = 0;
            tag_threshold = 'threshsig';
        case 'significance_alpha'
            % plot all data, add significance as alpha layer
            alpha = obj.pdc_sig;
            tag_threshold = 'threshsigalpha';
            % do nothing to data_temp
        otherwise
            % do nothing
    end
    
    % only add to plot if the whole sum is not 0
    data_sum = sum(data_temp(:));
    if data_sum > 0
        % sum over frequencies
        data_plot(i,:) = sum(data_temp,2);
        yticklabel{i} = obj.info.label{i};
    end
end

idx_empty = cellfun(@isempty,yticklabel,'UniformOutput',true);

if sum(~idx_empty) == 0
    fprintf('%s: no connections for %s\n',mfilename,label_seed);
    return;
end

% sort by hemisphere, region, angle
idx_sort = obj.sort_channels();
idx_sort = idx_sort(:);

% sort the data
data_plot = data_plot(idx_sort,:);
yticklabel = yticklabel(idx_sort,:);
idx_empty = idx_empty(idx_sort,:);

% remove empty entries
data_plot(idx_empty,:) = [];
yticklabel(idx_empty,:) = [];

% set up figure
screen_size = get(0,'screensize');
labels_height = 200;
row_height = (screen_size(4)-labels_height)/length(yticklabel);
max_row_height = 100;
if row_height > max_row_height
    % limit row height
    fig_size = screen_size;
    fig_size(4) = ceil(max_row_height*length(yticklabel)) + labels_height;
    set(gcf,'Position',fig_size);
else
    % use full screen
    figure('Position', screen_size);
end

if ~isempty(obj.info.region)
    ax2 = gca;
    set(ax2,'Visible','off');
    ax1_pos = get(ax2,'Position');
    ax1_offset = 0.1;
    ax1_pos(1) = ax1_pos(1) + ax1_offset;
    ax1_pos(3) = ax1_pos(3) - ax1_offset;
    ax1 = axes('Position',ax1_pos);
else
    ax1 = gca;
end
axes(ax1);
set(ax1,'FontSize',12);

clim = [0 1];
im = imagesc(data_plot,clim);

% set colormap
cmap = colormap(hot);
cmap = flipdim(cmap,1);
colormap(cmap);
colorbar();

switch p.Results.threshold_mode
    case 'significance_alpha'
        set(im,'AlphaData',alpha);
end

% add left axis with channel labels
ytick = 1:length(yticklabel);
set(gca,...
    'YTick', ytick, ...
    'YTickLabel', yticklabel,...
    'FontSize',12);

% add time info
if ~isempty(obj.time)
    obj.add_time_ticks('x');
    
    if ~isempty(p.Results.vertlines)
        % add vertical lines
        vertlines = p.Results.vertlines;
        for i=1:length(vertlines)
            obj.add_vert_line(vertlines(i));
        end
    end
end

% set labels and save tag
switch p.Results.direction
    case 'outgoing'
        str_xlabel = 'from';
        xlabel_string{1} = sprintf('%s %s',str_xlabel,label_seed);
        if ~isempty(obj.info.region)
            xlabel_string{2} = obj.info.region{p.Results.chseed};
        end 
        ylabel('to');
        xlabel(xlabel_string);
        obj.save_tag = sprintf('-seed-out-j%d',p.Results.chseed);
    case 'incoming'
        str_xlabel = 'to';
        xlabel_string{1} = sprintf('%s %s',str_xlabel,label_seed);
        if ~isempty(obj.info.region)
            xlabel_string{2} = obj.info.region{p.Results.chseed};
        end
        ylabel('from');
        xlabel(xlabel_string);
        obj.save_tag = sprintf('-seed-in-i%d',p.Results.chseed);
end
if ~isempty(tag_threshold)
    % add threshold tag
    obj.save_tag = [obj.save_tag '-' tag_threshold];
end

% add region bar on left side
if ~isempty(obj.info.region)
    set(ax2,'FontSize',12);
    set(ax2,'YLim',get(ax1,'YLim'),'YDir',get(ax1,'YDir'));
    axes(ax2);
    xlim([0 1]);
    
    % set up colors
    colors = obj.get_region_cmap('jet');
    
    % sort and remove empty
    colors = colors(idx_sort,:);
    colors(idx_empty,:) = [];
        
    % add extra labels with region labels
    % sort and remove empty
    regions = obj.info.region(idx_sort);
    regions(idx_empty) = [];
    
    %ax_pos = axis(ax2);
    nregions = length(regions);
    region1 = 1;
    offset = 0.5;
    if length(ytick) > 1
        ytick_inc = ytick(2)-ytick(1);
    else
        yylim = ylim;
        ytick_inc = yylim(2) - yylim(1);
    end
    for i=1:nregions
        if i == nregions
            region2 = 1;
        else
            region2 = i+1;
        end
        % find the region boundary
        if i~=nregions && isequal(regions{region1},regions{region2})
            continue;
        end
        
        % found next region
        
        region_offset = ax1_offset/3;
        
        % add line
        x = region_offset*ones(2,1);
        y = [ytick(region1); ytick(region2)] - ytick_inc/2;
        if y(2) <= y(1)
            % fix rollover
            y(2) = max(ytick) + ytick_inc/2;
        end
        width = ax1_offset*0.1;
        xpatch = [x + width/2; x - width/2];
        ypatch = [y; flipdim(y,1)];
        patch(xpatch,ypatch,colors(i,:));
        
        % add text at midpoint of line
        ymid = (y(2)+y(1))/2;
        text(region_offset - width, ymid, regions{region1},...
            'HorizontalAlignment','Right','FontSize',12);
        region1 = region2;
    end
end

end
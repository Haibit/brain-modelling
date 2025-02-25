function plot_rc(data,varargin)
%PLOT_RC plots reflection coefficients
%   PLOT_RC(data,...) plots reflection coefficients
%
%   Input
%   -----
%   data (struct)
%       data struct from LatticeTrace object, requires at least the Kf
%       field
%
%   Parameters
%   ----------
%   mode (string, default = 'image-all')
%       plotting mode
%       image-all
%           plots all reflection coefficients vs time
%       image-order
%           plots reflection coefficients vs time, where each order is
%           plotted in its own subplot
%       image-order-summary
%           plots sum of reflection coefficients over time, where each
%           order is plotted in its own subplot
%       image-max
%           plots the max reflection coefficient from all orders vs time
%       movie-order
%           plots reflection coefficients at each time step, where each
%           order is plotted in its own subplot
%       movie-max
%           plots the max reflection coefficient at each time step
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
addRequired(p,'data',@isstruct);
addParameter(p,'mode','image-all',@ischar);
addParameter(p,'clim',[-1.5 1.5],@(x) isvector(x) || isequal(x,'none'));
addParameter(p,'abs',false,@islogical);
addParameter(p,'threshold','none',@(x) isnumeric(x) || isequal(x,'none'));
addParameter(p,'clear_diag',false,@islogical);
parse(p,data,varargin{:});

if p.Results.clear_diag
    [~,~,nchannels,~] = size(data.Kf);
    for i=1:nchannels
        data.Kf(:,:,i,i) = NaN;
    end
end

switch p.Results.mode
    case 'image-all'
        % plot all reflection coefs
        niters = size(data.Kf,1);
        ncoefs = numel(data.Kf)/niters;
        rc = reshape(data.Kf,niters,ncoefs);
        rc = rc';
        rc = transform_data(rc,p.Results);
        
        if isequal(p.Results.clim,'none')
            imagesc(rc);
        else
            imagesc(rc,p.Results.clim);
        end
        colorbar;
        xlabel('Time');
        ylabel('Reflection Coefficients');
        
    case 'image-order'
        norder = size(data.Kf,2);
        niters = size(data.Kf,1);
        
        nplots = norder;
        nrows = 2;
        ncols = ceil(nplots/nrows);
        for j=1:norder
            %subplot(nrows,ncols,j);
            subaxis(nrows, ncols, j,...
                'Spacing', 0.05, 'SpacingVert', 0.05, 'Padding', 0, 'Margin', 0.05);
            ncoefs = numel(squeeze(data.Kf(:,j,:,:)))/niters;
            rc = reshape(data.Kf(:,j,:,:),niters,ncoefs);
            rc = rc';
            rc = transform_data(rc,p.Results);
            
            if isequal(p.Results.clim,'none')
                imagesc(rc);
                colorbar;
            else
                imagesc(rc,p.Results.clim);
                if j==norder
                    colorbar;
                end
            end
            axis square;
            ylabel(sprintf('P=%d',j));
            set(gca,'yticklabel',[]);
            set(gca,'xticklabel',[]);
            
            if j==norder
                xlabel('Time');
            end
        end
        
    case 'image-order-summary'
        [~,norder,nchannels,~] = size(data.Kf);
        rc = squeeze(data.Kf);
        rc = transform_data(rc,p.Results);
        data_plot = squeeze(sum(rc,1));
        
        if ~isequal(p.Results.clim,'none')
            warning('ignoring clim');
        end
        clim = [min(data_plot(:)) max(data_plot(:))];
        
        ticks = 1:nchannels;
        tick_labels = cell(nchannels,1);
        for i=1:nchannels
            tick_labels{i} = num2str(i);
        end
        
        nplots = norder;
        nrows = 2;
        ncols = ceil(nplots/nrows);
        for j=1:norder
            subaxis(nrows, ncols, j,...
                'Spacing', 0.05, 'SpacingVert', 0.05, 'Padding', 0, 'Margin', 0.05);
            
            imagesc(squeeze(data_plot(j,:,:)),clim);
            if j == norder
                colorbar();
            end
            axis square
            xlabel('Channels');
            ylabel('Channels');
            
            title(sprintf('P=%d',j));
            set(gca,...
                'Xtick',ticks,...
                'XtickLabel',tick_labels,...
                'Ytick',ticks,...
                'YtickLabel',tick_labels);
        end
        
    case 'image-max'
        data_max = squeeze(max(data.Kf,[],2));
        niters = size(data_max,1);
        ncoefs = numel(data_max)/niters;
        rc = reshape(data_max,niters,ncoefs);
        rc = rc';
        rc = transform_data(rc,p.Results);

        if isequal(p.Results.clim,'none')
            imagesc(rc);
        else
            imagesc(rc,p.Results.clim);
        end
        axis square;
        colorbar;
        xlabel('Time');
        ylabel('Reflection Coefficients');
        
        
    case 'movie-order'
        norder = size(data.Kf,2);
        niters = size(data.Kf,1);
        
        nplots = norder;
        nrows = 2;
        ncols = ceil(nplots/nrows);
        for k=1:niters
            for j=1:norder
                %subplot(nrows,ncols,j);
                subaxis(nrows, ncols, j,...
                    'Spacing', 0.05, 'SpacingVert', 0.05, 'Padding', 0, 'Margin', 0.05);
                rc = squeeze(data.Kf(k,j,:,:));
                rc = transform_data(rc,p.Results);
                
                if isequal(p.Results.clim,'none')
                    imagesc(rc);
                    colorbar;
                else
                    imagesc(rc,p.Results.clim);
                    if j==norder
                        colorbar;
                    end
                end
                axis square;
                ylabel(sprintf('P=%d',j));
                set(gca,'yticklabel',[]);
                set(gca,'xticklabel',[]);
                
                if j==1
                    title(sprintf('Time = %d/%d',k,niters));
                end
            end
            drawnow();
            %pause(0.005);
        end
    case 'movie-max'
        niters = size(data.Kf,1);
        
        for k=1:niters
            data_k = squeeze(data.Kf(k,:,:,:));
            data_max = squeeze(max(data_k,[],1));
            data_max = transform_data(data_max,p.Results);

            if isequal(p.Results.clim,'none')
                imagesc(data_ma);
            else
                imagesc(data_max,p.Results.clim);
            end        
            axis square;
            
            colorbar;
            title({'Max Reflection Coefficient',...
                sprintf('Time = %d/%d',k,niters)});
            set(gca,'yticklabel',[]);
            set(gca,'xticklabel',[]);
            drawnow();
            %pause(0.005);
        end
    otherwise
        error('unknown mode %s',p.Results.mode);
end

end

function data = transform_data(data,params)
if params.abs
    data = abs(data);
end
if ~isequal(params.threshold,'none')
    data(data > params.threshold) = NaN;
    data(data < -params.threshold) = NaN;
end
end
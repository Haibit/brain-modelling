function result = rc2pdc_dynamic(Kf,Kb,Pf,lambda,varargin)
%RC2PDC_DYNAMIC converts dynamic RC to dynamic PDC
%   RC2PDC_DYNAMIC(Kf, Kb, Pf, lambda) converts dynamic RC to dynamic PDC
%
%   Input
%   -----
%   Kf
%       forward reflection coefficients, [samples order channels channels]
%   Kb
%       backward reflection coefficients, [samples order channels channels]
%   Pf  
%       forward prediction error covariance [samples channels channels]
%   lambda
%       exponential decay
%
%   Parameters
%   ----------
%   metric (string, default = 'euc')
%       metric for PDC
%   nfreqs (integer, default = 128)
%       number of frequency bins
%   nfreqscompute (integer, default = 128)
%       number of frequency points to actually compute, starts at the first
%       index, for example if nfreqscompute = 16, it computes the pdc for
%       the frequencies corresponding to the indices 1:16
%   specden (logical, default = false)
%       flag to compute spectral density
%   coherence (logical, default = false)
%       flag to compute spectrum
%   downsample (integer, default = 'none')
%       downsampling 
%   informat (string, default = '')
%       input format of coefs
%       'or-ch-ch'
%       'ch-ch-or'

p = inputParser();
addRequired(p,'Kf',@(x) length(size(x)) == 4);
addRequired(p,'Kb',@(x) length(size(x)) == 4);
addRequired(p,'Pf',@(x) length(size(x)) == 3);
addRequired(p,'lambda',@(x) isnumeric(x) && length(x) == 1);
addParameter(p,'specden',false,@islogical);
addParameter(p,'coherence',false,@islogical);
addParameter(p,'metric','euc',@ischar);
addParameter(p,'nfreqs',128,@isnumeric);
addParameter(p,'nfreqscompute',[],@isnumeric);
addParameter(p,'downsample',0,@(x) x >= 0);
addParameter(p,'informat','',@(x) any(validatestring(x,{'ch-ch-or','or-ch-ch'})));
parse(p,Kf,Kb,Pf,lambda,varargin{:});

if size(Kf) ~= size(Kb)
    error('mismatched dimensions for Kf and Kb');
end
dims = size(Kf);
nsamples = dims(1);
if dims(3) ~= dims(4)
    error('bad format, channels should be in last 2 dimensions');
end

options = copyfields(p.Results,[],...
    {'specden','coherence','metric','lambda','nfreqs','nfreqscompute','informat'});

%% downsample
if p.Results.downsample > 0
    fprintf('downsampling by %d\n',p.Results.downsample);
    % create index
    idx_mini = false(p.Results.downsample,1);
    idx_mini(1) = true;
    
    ntimes = floor(nsamples/p.Results.downsample);
    idx = repmat(idx_mini,ntimes,1);
    
    Kf = Kf(idx,:,:,:);
    Kb = Kb(idx,:,:,:);
    nsamples = size(Kf,1);
end 

%% get sizes for data strucs
%% pdc
fprintf('getting pdc data size\n');
Kftemp = squeeze(Kf(1,:,:,:));
Kbtemp = squeeze(Kb(1,:,:,:));
Pftemp = squeeze(Pf(1,:,:));
result = rc2pdc(Kftemp, Kbtemp, Pftemp,...
        'metric', options.metric,...
        'nfreqs', options.nfreqs,...
        'nfreqscompute', options.nfreqscompute,...
        'specden', options.specden,...
        'coherence', options.coherence,...
        'informat',options.informat,...
        'parfor', true);
result_pdc = zeros([nsamples size(result.pdc)]);

%% spectral density
if options.specden
    fprintf('getting ss data size\n');
    result_SS = zeros([nsamples size(result.SS)]);
else
    result_SS = zeros(nsamples,1);
end

%% coherence
if options.coherence
    fprintf('getting coherence data size\n');
    result_coh = zeros([nsamples size(result.coh)]);
else
    result_coh = zeros(nsamples,1);
end
clear result;

%% convert each sample
progbar = ProgressBar(nsamples);
parfor i=1:nsamples
    % update progress
    progbar.progress();
    
    Kftemp = squeeze(Kf(i,:,:,:));
    Kbtemp = squeeze(Kb(i,:,:,:));
    Pftemp = squeeze(Pf(i,:,:));
    weight = (1-options.lambda)/(1-options.lambda^i);
    pdc_sample = rc2pdc(Kftemp, Kbtemp, weight*Pftemp,...
        'metric', options.metric,...
        'nfreqs', options.nfreqs,...
        'nfreqscompute', options.nfreqscompute,...
        'specden', options.specden,...
        'coherence', options.coherence,...
        'informat',options.informat,...
        'parfor', false);
    
    if options.specden
        result_SS(i,:,:,:) = pdc_sample.SS;
    end
    if options.coherence
        result_coh(i,:,:,:) = pdc_sample.coh;
    end
    
    % convert struct to more efficient data struct
    result_pdc(i,:,:,:) = pdc_sample.pdc;
    
end
progbar.stop();

% save results
result = [];
result.nfreqs = options.nfreqs;
result.nfreqscompute = options.nfreqscompute;
result.pdc = result_pdc;
if options.specden
    result.SS = result_SS;
end
if options.coherence
    result.coh = result_coh;
end

end
function data = gen_process(obj, process, varargin)
%
%   Input
%   -----
%   process (VAR or VRC object)
%       VAR or VRC object
%   
%   Parameter
%   ---------
%   nsamples (integer, default = 500)
%       number of samples
%   ntrials (integer, default = 100)
%       number of trials
%   data (struct, default = [])
%       previous data generated by gen_process, this will add more trials
%       if there aren't enough using the specified process

p = inputParser();
addRequired(p,'process');
addParameter(p,'ntrials',100,@isnumeric);
addParameter(p,'nsamples',500,@isnumeric);
addParameter(p,'data',[],@isstruct);
p.parse(process,varargin{:});

if isempty(p.Results.data)
    % set up structs
    data = [];
    data.process = process;
    data.signal = zeros(obj.nchannels, p.Results.nsamples, p.Results.ntrials);
    data.signal_norm = zeros(obj.nchannels, p.Results.nsamples, p.Results.ntrials);

    % save true coefficients
    data.true.Kf = process.get_coefs_vs_time(p.Results.nsamples,'Kf');
    data.true.Kb = process.get_coefs_vs_time(p.Results.nsamples,'Kb');
    
    % start at the beginning
    idx_start = 1;
else
    data = p.Results.data;
    ntrials_data = size(data.signal,3);
    if ntrials_data < p.Results.ntrials
        fprintf('simulating some more\n');
        idx_start = ntrials_data+1;
    else
        idx_start = p.Results.ntrials;
    end
end

j = idx_start;
while j <= p.Results.ntrials
    fprintf('simulating\n')
    % simulate process
    [signal,signal_norm,~] = process.simulate(p.Results.nsamples);
    
    data.signal(:,:,j) = signal;
    data.signal_norm(:,:,j) = signal_norm;
    j = j+1;
end

end

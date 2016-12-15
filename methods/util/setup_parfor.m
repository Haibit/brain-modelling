function setup_parfor()
%SETUP_PARFOR sets up parallel pool for a given computer configuration
%   SETUP_PARFOR sets up parallel pool for a given computer configuration
%
%   Feel free to add a new configuration

comp_name = get_compname();
    

switch comp_name
    case sprintf('blade16.ece.mcmaster.ca\n')
        if verLessThan('matlab', '8.2.0.29') % R2013b
            if matlabpool('size') == 0 
                matlabpool('open', 12);
            end
        else
            % close the current pool
            if ~isempty(gcp)
                delete(gcp);
            end
            % set up a new one
            parpool('local', 20);
        end
    otherwise
        fprintf('%s: using default config\n', mfilename);
end

end
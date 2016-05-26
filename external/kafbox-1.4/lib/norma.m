% Naive Online regularized Risk Minimization Algorithm
%
% J. Kivinen, A.J. Smola, and R.C. Williamson, "Online learning with
% kernels," IEEE Transactions on Signal Processing, vol. 52, no. 8,
% pp. 2165-2176, Aug. 2004, http://dx.doi.org/10.1109/TSP.2004.830991   
%
% Comment: using squared loss function
%
% This file is part of the Kernel Adaptive Filtering Toolbox for Matlab.
% http://sourceforge.net/projects/kafbox/

classdef norma
    
    properties (GetAccess = 'public', SetAccess = 'private')
        tau = 500; % memory size (terms retained in truncation)
        lambda = 1E-2; % regularization parameter
        eta = .5; % learning rate
        tcoeff = 0; % learning rate coefficient: eta_t = eta * t^tcoeff
        kerneltype = 'gauss'; % kernel type
        kernelpar = 1; % kernel parameter
    end
    
    properties (GetAccess = 'public', SetAccess = 'private')
        t = 0; % time index
        mem = []; % memory
        alpha = []; % expansion coefficients
        % beta = []; % forgetting coefficients
    end
    
    methods
        
        function kaf = norma(parameters) % constructor
            if (nargin > 0) % copy valid parameters
                for fn = fieldnames(parameters)',
                    if strmatch(fn,fieldnames(kaf),'exact'),
                        kaf.(fn{1}) = parameters.(fn{1});
                    end
                end
            end
            % kaf.beta = (1-kaf.eta*kaf.lambda).^(0:kaf.tau-1)';
        end
        
        function y_est = evaluate(kaf,x) % evaluate the algorithm
            if size(kaf.mem,1)>0
                k = kernel(kaf.mem,x,kaf.kerneltype,kaf.kernelpar);
                y_est = k'*kaf.alpha;
            else
                y_est = zeros(size(x,1),1);
            end
        end
        
        function kaf = train(kaf,x,y) % train the algorithm
            y_est = kaf.evaluate(x);
            err = y - y_est;
            
            kaf.t = kaf.t + 1;
            kaf.alpha = (1-kaf.lambda*kaf.eta*kaf.t^kaf.tcoeff)*kaf.alpha;
            kaf.alpha = [kaf.alpha; kaf.eta*err]; % grow
            kaf.mem = [kaf.mem; x]; % grow
            if length(kaf.alpha)>kaf.tau
                kaf.alpha(1) = []; % prune
                kaf.mem(1,:) = []; % prune
            end
        end
        
    end    
end

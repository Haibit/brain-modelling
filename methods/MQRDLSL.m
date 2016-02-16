classdef MQRDLSL < handle
    %MQRDLSL Multichannel QR-Decomposition-based Least Squares Lattice
    %algorithm
    %   The implementation is as described in Lewis1990
    %   TODO add source
    
    properties
        % filter variables
        dfsq;       % squared diagonal of D forward (e)
        dbsq;       % squared diagonal of D backward squared (r)
        Rtildef;    % \tilde{R} forward (e)
        Rtildeb;    % \tilde{R} backward (r)
        Xtildef;    % \tilde{X} forward (e)
        Xtildeb;    % \tilde{X} backward (r)
        
        gammasqd;   % delayed gamma
        berrord;    % delayed backward prediction error
        
%         Berrord;
%         Bpowerdd;
%         Fpowerd;
%         pbd;
%         pfd;
%         
        % reflection coefficients
        Kb;
        Kf;
        
        % filter order
        order;
        
        % number of channels
        nchannels;
        
        % weighting factor
        lambda;
    end
    
    methods
        function obj = MQRDLSL(channels, order, lambda)
            %MQRDLSL constructor for MQRDLSL
            %   MQRDLSL(ORDER, LAMBDA) creates a MQRDLSL object
            %
            %   channels (integer)
            %       number of channels
            %   order (integer)
            %       filter order
            %   lambda (scalar)
            %       exponential weighting factor between 0 and 1
            
            obj.order = order;
            obj.nchannels = channels;
            obj.lambda = lambda;
            
            zeroMat = zeros(obj.order+1, obj.nchannels, obj.nchannels);
            zeroMat2 = zeros(obj.order+1, obj.nchannels);
            obj.dfsq = zeroMat2; % D forward squared (e)
            obj.dbsq = zeroMat2; % D backward squared (r)
            obj.Rtildef = zeroMat; % \tilde{R} forward squared (e)
            obj.Rtildeb = zeroMat; % \tilde{R} backward squared (r)
            obj.Xtildef = zeroMat; % \tilde{X} forward squared (e)
            obj.Xtildeb = zeroMat; % \tilde{X} backward squared (r)
            
            % init the diagonals of D to 1's
            onesMat = ones(obj.nchannels, obj.order+1);
            obj.dfsq = onesMat;
            obj.dbsq = onesMat;
            
            obj.berrord = zeros(obj.nchannels, obj.order+1);
            obj.gammasqd = ones(obj.order+1, 1);
            
%             obj.M = order;
%             obj.lambda = lambda;
%             
%             delta = 0.1; % small positive constant
%             obj.Bpowerdd = delta*ones(obj.M+1,1);
%             obj.Fpowerd = obj.Bpowerdd;
%             
%             zeroVec = zeros(obj.M,1);
%             obj.Berrord = zeroVec;
%             obj.pbd = zeroVec;
%             obj.pfd = zeroVec;

            obj.Kb = zeroMat;
            obj.Kf = zeroMat;
        end
        
        function obj = update(obj, x)
            %UPDATE updates reflection coefficients
            %   UPDATE(OBJ,X) updates the reflection coefficients using the
            %   measurement X
            %
            %   x (vector)
            %       new measurement
            
            debug_prints = false;
            
            alpha = 100;
            
            x = x(:);
            if ~isequal(size(x), [obj.nchannels 1])
                error('bad input size: %d %d', size(x,1), size(x,2));
            end
            
            % allocate mem
            zeroMat = zeros(obj.nchannels,obj.order+1); 
            ferror = zeroMat;
            berror = zeroMat;
            gammasq = zeros(obj.order+1,1);
            
            p = 1;
            % ferror is always updated from the previous order, so we don't
            % need to save anything between iterations
            % ferror at order 0 is initialized to the input
            ferror(:,p) = x;
            
            % berror turns into the delayed signal at the end
            % berror at order 0 is initialized to the input
            berror(:,p) = x;
            
            % gammasq is initialized to 1 for order 0
            gammasq(p) = 1;
            
            % get number of channels
            m = obj.nchannels;
            
            % loop through stages
            for p=2:obj.order+1
                % TODO gammasqd(0)
                
                % forward errors
                df = [...
                    obj.gammasqd(p-1);...
                    obj.lambda^(-2)*obj.dfsq(:,p)...
                    ];
                Yf = [...
                    ferror(:,p-1)' obj.berrord(:,p-1)' obj.gammasqd(p-1);...
                    squeeze(obj.Rtildef(p,:,:)) squeeze(obj.Xtildef(p,:,:)) zeros(m,1);...
                    ];
                if debug_prints
                    display(df)
                    display(Yf)
                end
                if ~isequal(size(Yf),[m+1,2*m+1])
                    error('check size of Yf');
                end
                [Yf,df] = givens_fast_lsl(Yf,df,m);
                if debug_prints
                    display(df)
                    display(Yf)
                end
                if ~isempty(find(isnan(Yf),1))
                    fprintf('got some nans\n');
                end
                
                % extract updated R,X,beta
                Rf = Yf(2:end,1:m);
                Xf = Yf(2:end,m+1:2*m);
                betaf = Yf(2:end,end);
                dfsq = df(2:end);
                if debug_prints
                    display(Rf)
                    display(Xf)
                    display(betaf)
                    display(dfsq)
                end
                
                % check if we need to rescale
                if ~isempty(find(dfsq > alpha^2,1))
                    % rescale
                    Rf = Rf/alpha;
                    Xf = Xf/alpha;
                    betaf = betaf/alpha;
                    dfsq = dfsq/alpha^2;
                end
                
                % backward errors
                db = [...
                    obj.gammasqd(p-1);...
                    obj.lambda^(-2)*obj.dbsq(:,p)...
                    ];
                Yb = [...
                    obj.berrord(:,p-1)' ferror(:,p-1)' obj.gammasqd(p-1);...
                    squeeze(obj.Rtildeb(p,:,:)) squeeze(obj.Xtildeb(p,:,:)) zeros(m,1);...
                    ];
                if debug_prints
                    display(db)
                    display(Yb)
                end
                if ~isequal(size(Yb),[m+1, 2*m+1])
                    error('check size of Yb');
                end
                [Yb,db] = givens_fast_lsl(Yb,db,m);
                if debug_prints
                    display(db)
                    display(Yb)
                end
                if ~isempty(find(isnan(Yb),1))
                    fprintf('got some nans\n');
                end
                
                % extract updated R,X,beta
                Rb = Yb(2:end,1:m);
                Xb = Yb(2:end,m+1:2*m);
                betab = Yb(2:end,end);
                dbsq = db(2:end);
                if debug_prints
                    display(Rb)
                    display(Xb)
                    display(betab)
                    display(dbsq)
                end
                
                % check if we need to rescale
                if ~isempty(find(dbsq > alpha^2,1))
                    % rescale
                    Rb = Rb/alpha;
                    Xb = Xb/alpha;
                    betab = betab/alpha;
                    dbsq = dbsq/alpha^2;
                end
                
                % update errors
                % TODO Check if Dbsq needs to be inverted
                Dbsq_inv = diag(1./dbsq);
                Dfsq_inv = diag(1./dfsq);
                ferror(:,p) = ferror(:,p-1) - Xb'*Dbsq_inv*betab;
                berror(:,p) = obj.berrord(:,p-1) - Xf'*Dfsq_inv*betaf;
                gammasq(p) = obj.gammasqd(p-1) - betaf'*Dfsq_inv*betaf;
                if debug_prints
                    display(ferror)
                    display(berror)
                    display(gammasq)
                end
                
                % calculate reflection coefficients
                obj.Kf(p,:,:) = Rf\Xf;
                obj.Kb(p,:,:) = (Rb\Xb)';
                % NOTE these are singular for the first few iterations
                % because there are not enough samples, so Rb isn't full
                % rank
                
                % save vars
                obj.Rtildef(p,:,:) = Rf;
                obj.Xtildef(p,:,:) = Xf;
                obj.dfsq(:,p) = dfsq;
                
                obj.Rtildeb(p,:,:) = Rb;
                obj.Xtildeb(p,:,:) = Xb;
                obj.dbsq(:,p) = dbsq;
                
            end
            
            obj.Kf(1,:,:) = [];
            obj.Kb(1,:,:) = [];
            
            % save current values as delayed versions for next iteration
            obj.berrord = berror;
            obj.gammasqd = gammasq;
            
        end
    end
    
end


function [ARF,RCF,PE,DC,varargout] = mvar(Y, Pmax, Mode);
% MVAR estimates parameters of the Multi-Variate AutoRegressive model 
%
%    Y(t) = Y(t-1) * A1 + ... + Y(t-p) * Ap + X(t);  
% whereas
%    Y(t) is a row vecter with M elements Y(t) = y(t,1:M) 
%
% Several estimation algorithms are implemented, all estimators 
% can handle data with missing values encoded as NaNs.  
%
% 	[AR,RC,PE] = mvar(Y, p);
% 	[AR,RC,PE] = mvar(Y, p, Mode);
% 
% with 
%       AR = [A1, ..., Ap];
%
% INPUT:
%  Y	 Multivariate data series 
%  p     Model order
%  Mode	 determines estimation algorithm 
%
% OUTPUT:
%  AR    multivariate autoregressive model parameter
%  RC    reflection coefficients (= -PARCOR coefficients)
%  PE    remaining error variances for increasing model order
%	   PE(:,p*M+[1:M]) is the residual variance for model order p
%
% All input and output parameters are organized in columns, one column 
% corresponds to the parameters of one channel.
%
% Mode determines estimation algorithm. 
%  1:  Correlation Function Estimation method using biased correlation function estimation method
%   		also called the 'multichannel Yule-Walker' [1,2] 
%  6:  Correlation Function Estimation method using unbiased correlation function estimation method
%
%  2:  Partial Correlation Estimation: Vieira-Morf [2] using unbiased covariance estimates.
%               In [1] this mode was used and (incorrectly) denominated as Nutall-Strand. 
%		Its the DEFAULT mode; according to [1] it provides the most accurate estimates.
%  5:  Partial Correlation Estimation: Vieira-Morf [2] using biased covariance estimates.
%		Yields similar results than Mode=2;
%
%  3:  buggy: Partial Correlation Estimation: Nutall-Strand [2] (biased correlation function)
%  9:  Partial Correlation Estimation: Nutall-Strand [2] (biased correlation function)
%  7:  Partial Correlation Estimation: Nutall-Strand [2] (unbiased correlation function)
%  8:  Least Squares w/o nans in Y(t):Y(t-p)
% 10:  ARFIT [3] 
% 11:  BURGV [4] 
% 13:  modified BURGV -  
% 14:  modified BURGV [4] 
% 15:  Least Squares based on correlation matrix
% 22: Modified Partial Correlation Estimation: Vieira-Morf [2,5] using unbiased covariance estimates.
% 25: Modified Partial Correlation Estimation: Vieira-Morf [2,5] using biased covariance estimates.
%
% 90,91,96: Experimental versions 
%
%    Imputation methods:
%  100+Mode: 
%  200+Mode: forward, past missing values are assumed zero
%  300+Mode: backward, past missing values are assumed zero
%  400+Mode: forward+backward, past missing values are assumed zero
% 1200+Mode: forward, past missing values are replaced with predicted value
% 1300+Mode: backward, 'past' missing values are replaced with predicted value
% 1400+Mode: forward+backward, 'past' missing values are replaced with predicted value
% 2200+Mode: forward, past missing values are replaced with predicted value + noise to prevent decaying
% 2300+Mode: backward, past missing values are replaced with predicted value + noise to prevent decaying
% 2400+Mode: forward+backward, past missing values are replaced with predicted value + noise to prevent decaying
%
%
%

% REFERENCES:
%  [1] A. Schloegl, Comparison of Multivariate Autoregressive Estimators.
%       Signal processing, Elsevier B.V. (in press). 
%       available at http://dx.doi.org/doi:10.1016/j.sigpro.2005.11.007
%  [2] S.L. Marple 'Digital Spectral Analysis with Applications' Prentice Hall, 1987.
%  [3] Schneider and Neumaier)
%  [4] Stijn de Waele, 2003
%  [5]  M. Morf, et al. Recursive Multichannel Maximum Entropy Spectral Estimation, 
%      IEEE trans. GeoSci. Elec., 1978, Vol.GE-16, No.2, pp85-94.
%
%
% A multivariate inverse filter can be realized with 
%   [AR,RC,PE] = mvar(Y,P);
%   e = mvfilter([eye(size(AR,1)),-AR],eye(size(AR,1)),Y);
%  
% see also: MVFILTER, MVFREQZ, COVM, SUMSKIPNAN, ARFIT2

%	$Id: mvar.m 11693 2013-03-04 06:40:14Z schloegl $
%	Copyright (C) 1996-2006,2011,2012 by Alois Schloegl <alois.schloegl@ist.ac.at>	
%       This is part of the TSA-toolbox. See also 
%       http://pub.ist.ac.at/~schloegl/matlab/tsa/
%       http://octave.sourceforge.net/
%       http://biosig.sourceforge.net/
%
%    This program is free software: you can redistribute it and/or modify
%    it under the terms of the GNU General Public License as published by
%    the Free Software Foundation, either version 3 of the License, or
%    (at your option) any later version.
%
%    This program is distributed in the hope that it will be useful,
%    but WITHOUT ANY WARRANTY; without even the implied warranty of
%    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%    GNU General Public License for more details.
%
%    You should have received a copy of the GNU General Public License
%    along with this program.  If not, see <http://www.gnu.org/licenses/>.

import tsa.*


% Inititialization
[N,M] = size(Y);

if nargin<2, 
        Pmax=max([N,M])-1;
end;

if iscell(Y)
        Pmax = min(max(N ,M ),Pmax);
        C    = Y;
end;
if nargin<3,
        % according to [1], and other internal validations this is in many cases the best algorithm 
        Mode=2;
end;

[C(:,1:M),n] = covm(Y,'M');
PE(:,1:M)  = C(:,1:M)./n;
if 0,
elseif Mode==0;  % this method is broken
        fprintf('Warning MVAR: Mode=0 is broken.\n')        
        C(:,1:M) = C(:,1:M)/N;
        F = Y;
        B = Y;
        PEF = C(:,1:M);  %?% PEF = PE(:,1:M);
        PEB = C(:,1:M);
        for K=1:Pmax,
                [D,n] = covm(Y(K+1:N,:),Y(1:N-K,:),'M');
	        D = D/N;
                ARF(:,K*M+(1-M:0)) = D/PEB;	
                ARB(:,K*M+(1-M:0)) = D'/PEF;	
                
                tmp        = F(K+1:N,:) - B(1:N-K,:)*ARF(:,K*M+(1-M:0))';
                B(1:N-K,:) = B(1:N-K,:) - F(K+1:N,:)*ARB(:,K*M+(1-M:0))';
                F(K+1:N,:) = tmp;
                
                for L = 1:K-1,
                        tmp      = ARF(:,L*M+(1-M:0))   - ARF(:,K*M+(1-M:0))*ARB(:,(K-L)*M+(1-M:0));
                        ARB(:,(K-L)*M+(1-M:0)) = ARB(:,(K-L)*M+(1-M:0)) - ARB(:,K*M+(1-M:0))*ARF(:,L*M+(1-M:0));
                        ARF(:,L*M+(1-M:0))   = tmp;
                end;
                
                RCF(:,K*M+(1-M:0)) = ARF(:,K*M+(1-M:0));
                RCB(:,K*M+(1-M:0)) = ARB(:,K*M+(1-M:0));
                
                PEF = [eye(M) - ARF(:,K*M+(1-M:0))*ARB(:,K*M+(1-M:0))]*PEF;
                PEB = [eye(M) - ARB(:,K*M+(1-M:0))*ARF(:,K*M+(1-M:0))]*PEB;
                PE(:,K*M+(1:M)) = PEF;        
        end;

        
elseif Mode==1, %%%%% Levinson-Wiggens-Robinson (LWR) algorithm using biased correlation function
	% ===== In [1,2] this algorithm is denoted 'Multichannel Yule-Walker' ===== %
        C(:,1:M) = C(:,1:M)/N;
        PEF = C(:,1:M);  
        PEB = C(:,1:M);
        
        for K=1:Pmax,
                [C(:,K*M+(1:M)),n] = covm(Y(K+1:N,:),Y(1:N-K,:),'M');
                C(:,K*M+(1:M)) = C(:,K*M+(1:M))/N;

                D = C(:,K*M+(1:M));
                for L = 1:K-1,
                        D = D - ARF(:,L*M+(1-M:0))*C(:,(K-L)*M+(1:M));
                end;
                ARF(:,K*M+(1-M:0)) = D / PEB;	
                ARB(:,K*M+(1-M:0)) = D'/ PEF;	
                for L = 1:K-1,
                        tmp                    = ARF(:,L*M+(1-M:0)) - ARF(:,K*M+(1-M:0))*ARB(:,(K-L)*M+(1-M:0));
                        ARB(:,(K-L)*M+(1-M:0)) = ARB(:,(K-L)*M+(1-M:0)) - ARB(:,K*M+(1-M:0))*ARF(:,L*M+(1-M:0));
                        ARF(:,L*M+(1-M:0))     = tmp;
                end;
                
                RCF(:,K*M+(1-M:0)) = ARF(:,K*M+(1-M:0));
                RCB(:,K*M+(1-M:0)) = ARB(:,K*M+(1-M:0));
                
                PEF = [eye(M) - ARF(:,K*M+(1-M:0))*ARB(:,K*M+(1-M:0))]*PEF;
                PEB = [eye(M) - ARB(:,K*M+(1-M:0))*ARF(:,K*M+(1-M:0))]*PEB;
                PE(:,K*M+(1:M)) = PEF;        
        end;

        
elseif Mode==6, %%%%% Levinson-Wiggens-Robinson (LWR) algorithm using unbiased correlation function
        C(:,1:M) = C(:,1:M)/N;
        PEF = C(:,1:M);  %?% PEF = PE(:,1:M);
        PEB = C(:,1:M);
        
        for K = 1:Pmax,
                [C(:,K*M+(1:M)),n] = covm(Y(K+1:N,:),Y(1:N-K,:),'M');
                C(:,K*M+(1:M)) = C(:,K*M+(1:M))./n;
		%C{K+1} = C{K+1}/N;

                D = C(:,K*M+(1:M));
                for L = 1:K-1,
                        D = D - ARF(:,L*M+(1-M:0))*C(:,(K-L)*M+(1:M));
                end;
                ARF(:,K*M+(1-M:0)) = D / PEB;	
                ARB(:,K*M+(1-M:0)) = D'/ PEF;	
                for L = 1:K-1,
                        tmp      = ARF(:,L*M+(1-M:0))   - ARF(:,K*M+(1-M:0))*ARB(:,(K-L)*M+(1-M:0));
                        ARB(:,(K-L)*M+(1-M:0)) = ARB(:,(K-L)*M+(1-M:0)) - ARB(:,K*M+(1-M:0))*ARF(:,L*M+(1-M:0));
                        ARF(:,L*M+(1-M:0))   = tmp;
                end;
                
                RCF(:,K*M+(1-M:0)) = ARF(:,K*M+(1-M:0));
                RCB(:,K*M+(1-M:0)) = ARB(:,K*M+(1-M:0));
                
                PEF = [eye(M) - ARF(:,K*M+(1-M:0))*ARB(:,K*M+(1-M:0))]*PEF;
                PEB = [eye(M) - ARB(:,K*M+(1-M:0))*ARF(:,K*M+(1-M:0))]*PEB;
                PE(:,K*M+(1:M)) = PEF;        
        end;
        

elseif Mode==2 %%%%% Partial Correlation Estimation: Vieira-Morf Method [2] with unbiased covariance estimation
	%===== In [1] this algorithm is denoted 'Nutall-Strand with unbiased covariance' =====%
        %C(:,1:M) = C(:,1:M)/N;
        F = Y;
        B = Y;
        %PEF = C(:,1:M);
        %PEB = C(:,1:M);
        PEF = PE(:,1:M);
        PEB = PE(:,1:M);
        for K = 1:Pmax,
                [D,n] = covm(F(K+1:N,:),B(1:N-K,:),'M');
                D = D./n;

		ARF(:,K*M+(1-M:0)) = D / PEB;	
                ARB(:,K*M+(1-M:0)) = D'/ PEF;	
                
                tmp        = F(K+1:N,:) - B(1:N-K,:)*ARF(:,K*M+(1-M:0)).';
                B(1:N-K,:) = B(1:N-K,:) - F(K+1:N,:)*ARB(:,K*M+(1-M:0)).';
                F(K+1:N,:) = tmp;
                
                for L = 1:K-1,
                        tmp      = ARF(:,L*M+(1-M:0))   - ARF(:,K*M+(1-M:0))*ARB(:,(K-L)*M+(1-M:0));
                        ARB(:,(K-L)*M+(1-M:0)) = ARB(:,(K-L)*M+(1-M:0)) - ARB(:,K*M+(1-M:0))*ARF(:,L*M+(1-M:0));
                        ARF(:,L*M+(1-M:0))   = tmp;
                end;
                
                RCF(:,K*M+(1-M:0)) = ARF(:,K*M+(1-M:0));
                RCB(:,K*M+(1-M:0)) = ARB(:,K*M+(1-M:0));
                
                [PEF,n] = covm(F(K+1:N,:),F(K+1:N,:),'M');
                PEF = PEF./n;

		[PEB,n] = covm(B(1:N-K,:),B(1:N-K,:),'M');
                PEB = PEB./n;

                PE(:,K*M+(1:M)) = PEF;        
        end;
        

elseif Mode==5 %%%%% Partial Correlation Estimation: Vieira-Morf Method [2] with biased covariance estimation
	%===== In [1] this algorithm is denoted 'Nutall-Strand with biased covariance' ===== %

        F = Y;
        B = Y;
        PEF = C(:,1:M);
        PEB = C(:,1:M);
        for K=1:Pmax,
                [D,n]  = covm(F(K+1:N,:),B(1:N-K,:),'M');
                %D=D/N;

                ARF(:,K*M+(1-M:0)) = D / PEB;	
                ARB(:,K*M+(1-M:0)) = D'/ PEF;	
                
                tmp        = F(K+1:N,:) - B(1:N-K,:)*ARF(:,K*M+(1-M:0)).';
                B(1:N-K,:) = B(1:N-K,:) - F(K+1:N,:)*ARB(:,K*M+(1-M:0)).';
                F(K+1:N,:) = tmp;
                
                for L = 1:K-1,
                        tmp = ARF(:,L*M+(1-M:0)) - ARF(:,K*M+(1-M:0))*ARB(:,(K-L)*M+(1-M:0));
                        ARB(:,(K-L)*M+(1-M:0)) = ARB(:,(K-L)*M+(1-M:0)) - ARB(:,K*M+(1-M:0))*ARF(:,L*M+(1-M:0));
                        ARF(:,L*M+(1-M:0))   = tmp;
                end;
                
                RCF(:,K*M+(1-M:0)) = ARF(:,K*M+(1-M:0));
                RCB(:,K*M+(1-M:0)) = ARB(:,K*M+(1-M:0));
                
                [PEB,n] = covm(B(1:N-K,:),B(1:N-K,:),'M');
                %PEB = D/N;

                [PEF,n] = covm(F(K+1:N,:),F(K+1:N,:),'M');
                %PEF = D/N;

                %PE(:,K*M+(1:M)) = PEF; 
                PE(:,K*M+(1:M)) = PEF./n;
        end;
        
      
elseif 0, Mode==3 %%%%% Partial Correlation Estimation: Nutall-Strand Method [2] with biased covariance estimation
        %%% OBSOLETE because its buggy, use Mode=9 instead.  
        % C(:,1:M) = C(:,1:M)/N; 
        F = Y;
        B = Y;
        PEF = C(:,1:M);
        PEB = C(:,1:M);
        for K=1:Pmax,
                [D, n]  = covm(F(K+1:N,:),B(1:N-K,:),'M');
                D = D./N;

                ARF(:,K*M+(1-M:0)) = 2*D / (PEB+PEF);	
                ARB(:,K*M+(1-M:0)) = 2*D'/ (PEF+PEB);	
                
                tmp        = F(K+1:N,:) - B(1:N-K,:)*ARF(:,K*M+(1-M:0)).';
                B(1:N-K,:) = B(1:N-K,:) - F(K+1:N,:)*ARB(:,K*M+(1-M:0)).';
                F(K+1:N,:) = tmp;
                
                for L = 1:K-1,
                        tmp      = ARF(:,L*M+(1-M:0))   - ARF(:,K*M+(1-M:0))*ARB(:,(K-L)*M+(1-M:0));
                        ARB(:,(K-L)*M+(1-M:0)) = ARB(:,(K-L)*M+(1-M:0)) - ARB(:,K*M+(1-M:0))*ARF(:,L*M+(1-M:0));
                        ARF(:,L*M+(1-M:0))   = tmp;
                end;
                
                %RCF{K} = ARF{K};
                RCF(:,K*M+(1-M:0)) = ARF(:,K*M+(1-M:0));
                
                [PEF,n] = covm(F(K+1:N,:),F(K+1:N,:),'M');
                PEF = PEF./N;

		[PEB,n] = covm(B(1:N-K,:),B(1:N-K,:),'M');
                PEB = PEB./N;

                %PE(:,K*M+(1:M)) = PEF;        
                PE(:,K*M+(1:M)) = PEF./n;
        end;

        
elseif Mode==7 %%%%% Partial Correlation Estimation: Nutall-Strand Method [2] with unbiased covariance estimation 

        F = Y;
        B = Y;
        PEF = PE(:,1:M);
        PEB = PE(:,1:M);
        for K = 1:Pmax,
                [D]  = covm(F(K+1:N,:),B(1:N-K,:),'M');
                %D = D./n;

                ARF(:,K*M+(1-M:0)) = 2*D / (PEB+PEF);	
                ARB(:,K*M+(1-M:0)) = 2*D'/ (PEF+PEB);	
                
                tmp        = F(K+1:N,:) - B(1:N-K,:)*ARF(:,K*M+(1-M:0)).';
                B(1:N-K,:) = B(1:N-K,:) - F(K+1:N,:)*ARB(:,K*M+(1-M:0)).';
                F(K+1:N,:) = tmp;
                
                for L = 1:K-1,
                        tmp      = ARF(:,L*M+(1-M:0))   - ARF(:,K*M+(1-M:0))*ARB(:,(K-L)*M+(1-M:0));
                        ARB(:,(K-L)*M+(1-M:0)) = ARB(:,(K-L)*M+(1-M:0)) - ARB(:,K*M+(1-M:0))*ARF(:,L*M+(1-M:0));
                        ARF(:,L*M+(1-M:0))   = tmp;
                end;
                
                %RCF{K} = ARF{K};
                RCF(:,K*M+(1-M:0)) = ARF(:,K*M+(1-M:0));
                
                [PEF] = covm(F(K+1:N,:),F(K+1:N,:),'M');
                %PEF = PEF./n;

                [PEB] = covm(B(1:N-K,:),B(1:N-K,:),'M');
                %PEB = PEB./n;

                %PE{K+1} = PEF;        
                PE(:,K*M+(1:M)) = PEF;        
        end;


elseif any(Mode==[3,9]) %%%%% Partial Correlation Estimation: Nutall-Strand Method [2] with biased covariance estimation
	%% same as 3 but with fixed normalization
        F = Y;
        B = Y;
        PEF = C(:,1:M);
        PEB = C(:,1:M);
        for K=1:Pmax,
                [D, n]  = covm(F(K+1:N,:),B(1:N-K,:),'M');

                ARF(:,K*M+(1-M:0)) = 2*D / (PEB+PEF);	
                ARB(:,K*M+(1-M:0)) = 2*D'/ (PEF+PEB);	
                
                tmp        = F(K+1:N,:) - B(1:N-K,:)*ARF(:,K*M+(1-M:0)).';
                B(1:N-K,:) = B(1:N-K,:) - F(K+1:N,:)*ARB(:,K*M+(1-M:0)).';
                F(K+1:N,:) = tmp;
                
                for L = 1:K-1,
                        tmp      = ARF(:,L*M+(1-M:0))   - ARF(:,K*M+(1-M:0))*ARB(:,(K-L)*M+(1-M:0));
                        ARB(:,(K-L)*M+(1-M:0)) = ARB(:,(K-L)*M+(1-M:0)) - ARB(:,K*M+(1-M:0))*ARF(:,L*M+(1-M:0));
                        ARF(:,L*M+(1-M:0))   = tmp;
                end;
                
                %RCF{K} = ARF{K};
                RCF(:,K*M+(1-M:0)) = ARF(:,K*M+(1-M:0));
                
                [PEF,nf] = covm(F(K+1:N,:),F(K+1:N,:),'M');
		[PEB,nb] = covm(B(1:N-K,:),B(1:N-K,:),'M');

                %PE(:,K*M+(1:M)) = PEF;        
                PE(:,K*M+(1:M)) = PEF./nf;
        end;
        
        
elseif Mode==4,  %%%%% Kay, not fixed yet. 
        fprintf('Warning MVAR: Mode=4 is broken.\n')        
        
        C(:,1:M) = C(:,1:M)/N;
        K = 1;
        [C(:,M+(1:M)),n] = covm(Y(2:N,:),Y(1:N-1,:));
        C(:,M+(1:M)) = C(:,M+(1:M))/N;  % biased estimate

        D = C(:,M+(1:M));
        ARF(:,1:M) = C(:,1:M)\D;
        ARB(:,1:M) = C(:,1:M)\D';
        RCF(:,1:M) = ARF(:,1:M);
        RCB(:,1:M) = ARB(:,1:M);
        PEF = C(:,1:M)*[eye(M) - ARB(:,1:M)*ARF(:,1:M)];
        PEB = C(:,1:M)*[eye(M) - ARF(:,1:M)*ARB(:,1:M)];
        
        for K=2:Pmax,
                [C(:,K*M+(1:M)),n] = covm(Y(K+1:N,:),Y(1:N-K,:),'M');
                C(:,K*M+(1:M)) = C(:,K*M+(1:M)) / N; % biased estimate

                D = C(:,K*M+(1:M));
                for L = 1:K-1,
                        D = D - C(:,(K-L)*M+(1:M))*ARF(:,L*M+(1-M:0));
                end;
                
                ARF(:,K*M+(1-M:0)) = PEB \ D;	
                ARB(:,K*M+(1-M:0)) = PEF \ D';	
                for L = 1:K-1,
                        tmp = ARF(:,L*M+(1-M:0)) - ARF(:,K*M+(1-M:0))*ARB(:,(K-L)*M+(1-M:0));
                        ARB(:,(K-L)*M+(1-M:0)) = ARB(:,(K-L)*M+(1-M:0)) - ARB(:,K*M+(1-M:0))*ARF(:,L*M+(1-M:0));
                        ARF(:,L*M+(1-M:0)) = tmp;
                end;
                RCF(:,K*M+(1-M:0)) = ARF(:,K*M+(1-M:0)) ;
                RCB(:,K*M+(1-M:0)) = ARB(:,K*M+(1-M:0)) ;
                
                PEF = PEF*[eye(M) - ARB(:,K*M+(1-M:0)) *ARF(:,K*M+(1-M:0)) ];
                PEB = PEB*[eye(M) - ARF(:,K*M+(1-M:0)) *ARB(:,K*M+(1-M:0)) ];
                PE(:,K*M+(1:M))  = PEF;        
        end;


elseif Mode==8,  %%%%% Least Squares
	ix  = Pmax+1:N;
	y   = repmat(NaN,N-Pmax,M*Pmax);
	for k = 1:Pmax,
		y(:,k*M+[1-M:0]) = Y(ix-k,:);
	end;
	ix2 = ~any(isnan([Y(ix,:),y]),2);	
	ARF = Y(ix(ix2),:)'/y(ix2,:)';
	PE  = covm(Y(ix,:) - y*ARF');
	RCF = zeros(M,M*Pmax);


elseif Mode==10,  %%%%% ARFIT
	try
		RCF = [];
		[w, ARF, PE] = arfit(Y, Pmax, Pmax, 'sbc', 'zero');
	catch
		ARF = zeros(M,M*Pmax); 
		RCF = ARF;
	end; 


elseif Mode==11,  %%%%% de Waele 2003
	%%% OBSOLETE 
	warning('MVAR: mode=11 is obsolete use Mode 13 or 14!'); 
	[pc,R0] = burgv(reshape(Y',[M,1,N]),Pmax);
        try,
                [ARF,ARB,Pf,Pb,RCF,RCB] = pc2parv(pc,R0);
        catch
                [RCF,RCB,Pf,Pb] = pc2rcv(pc,R0);
                [ARF,ARB,Pf,Pb] = pc2parv(pc,R0);
        end;
        ARF = -reshape(ARF(:,:,2:end),[M,M*Pmax]);
	RCF = -reshape(RCF(:,:,2:end),[M,M*Pmax]);
	PE = reshape(Pf,[M,M*(Pmax+1)]);


elseif Mode==12, 
	%%% OBSOLETE 
	warning('MVAR: mode=12 is obsolete use Mode 13 or 14!'); 
        % this is equivalent to Mode==11        
	[pc,R0] = burgv(reshape(Y',[M,1,N]),Pmax);
        [rcf,rcb,Pf,Pb] = pc2rcv(pc,R0);

        %%%%% Convert reflection coefficients RC to autoregressive parameters
        ARF = zeros(M,M*Pmax); 
        ARB = zeros(M,M*Pmax); 
        for K = 1:Pmax,
                ARF(:,K*M+(1-M:0)) = -rcf(:,:,K+1);	
                ARB(:,K*M+(1-M:0)) = -rcb(:,:,K+1);	
                for L = 1:K-1,
                        tmp                    = ARF(:,L*M+(1-M:0)) - ARF(:,K*M+(1-M:0))*ARB(:,(K-L)*M+(1-M:0));
                        ARB(:,(K-L)*M+(1-M:0)) = ARB(:,(K-L)*M+(1-M:0)) - ARB(:,K*M+(1-M:0))*ARF(:,L*M+(1-M:0));
                        ARF(:,L*M+(1-M:0))     = tmp;
                end;
        end;        
        RCF = -reshape(rcf(:,:,2:end),[M,M*Pmax]);
	PE  = reshape(Pf,[M,M*(Pmax+1)]);


elseif Mode==13, 
        % this is equivalent to Mode==11 but can deal with missing values         
	%%%%%%%%%%% [pc,R0] = burgv_nan(reshape(Y',[M,1,N]),Pmax,1);
	% Copyright S. de Waele, March 2003 - modified Alois Schloegl, 2009
	I = eye(M);
	
	sz = [M,M,Pmax+1]; 
	pc= zeros(sz); pc(:,:,1) =I;
	K = zeros(sz); K(:,:,1)  =I;
	Kb= zeros(sz); Kb(:,:,1) =I;
	P = zeros(sz);
	Pb= zeros(sz);

	%[P(:,:,1)]= covm(Y);	
	[P(:,:,1)]= PE(:,1:M);	% normalized 
	Pb(:,:,1)= P(:,:,1);
	f = Y;
	b = Y;

	%the recursive algorithm
	for i = 1:Pmax,
		v = f(2:end,:);
		w = b(1:end-1,:);
   
		%% normalized, unbiased
		Rvv = covm(v); %Pfhat
		Rww = covm(w); %Pbhat
		Rvw = covm(v,w); %Pfbhat
		Rwv = covm(w,v); % = Rvw', written out for symmetry
		delta = lyap(Rvv*inv(P(:,:,i)),inv(Pb(:,:,i))*Rww,-2*Rvw);
   
		TsqrtS = chol( P(:,:,i))'; %square root M defined by: M=Tsqrt(M)*Tsqrt(M)'
		TsqrtSb= chol(Pb(:,:,i))'; 
		pc(:,:,i+1) = inv(TsqrtS)*delta*inv(TsqrtSb)';
   
		%The forward and backward reflection coefficient
		K(:,:,i+1) = -TsqrtS *pc(:,:,i+1) *inv(TsqrtSb);
		Kb(:,:,i+1)= -TsqrtSb*pc(:,:,i+1)'*inv(TsqrtS);
   
		%filtering the reflection coefficient out:
		f = (v'+ K(:,:,i+1)*w')';
		b = (w'+Kb(:,:,i+1)*v')';
   
		%The new R and Rb:
		%residual matrices
		P(:,:,i+1)  = (I-TsqrtS *pc(:,:,i+1) *pc(:,:,i+1)'*inv(TsqrtS ))*P(:,:,i); 
		Pb(:,:,i+1) = (I-TsqrtSb*pc(:,:,i+1)'*pc(:,:,i+1) *inv(TsqrtSb))*Pb(:,:,i); 
	end %for i = 1:Pmax,
	R0 = PE(:,1:M); 

        %% [rcf,rcb,Pf,Pb] = pc2rcv(pc,R0);
	rcf  = zeros(sz); rcf(:,:,1)  = I; 
	Pf   = zeros(sz); Pf(:,:,1)   = R0;
	rcb  = zeros(sz); rcb(:,:,1) = I; 
	Pb   = zeros(sz); Pb(:,:,1)  = R0;

	for p = 1:Pmax,
		TsqrtPf = chol( Pf(:,:,p))'; %square root M defined by: M=Tsqrt(M)*Tsqrt(M)'
		TsqrtPb= chol(Pb(:,:,p))'; 
		%reflection coefficients
		rcf(:,:,p+1) = -TsqrtPf *pc(:,:,p+1) *inv(TsqrtPb);
		rcb(:,:,p+1)= -TsqrtPb*pc(:,:,p+1)'*inv(TsqrtPf );
		%residual matrices
		Pf(:,:,p+1)  = (I-TsqrtPf *pc(:,:,p+1) *pc(:,:,p+1)'*inv(TsqrtPf ))*Pf(:,:,p); 
		Pb(:,:,p+1) = (I-TsqrtPb*pc(:,:,p+1)'*pc(:,:,p+1) *inv(TsqrtPb))*Pb(:,:,p); 
	end %for p = 2:order,
	%%%%%%%%%%%%%% end %%%%%%


        %%%%% Convert reflection coefficients RC to autoregressive parameters
        ARF = zeros(M,M*Pmax); 
        ARB = zeros(M,M*Pmax); 
        for K = 1:Pmax,
                ARF(:,K*M+(1-M:0)) = -rcf(:,:,K+1);
                ARB(:,K*M+(1-M:0)) = -rcb(:,:,K+1);
                for L = 1:K-1,
                        tmp                    = ARF(:,L*M+(1-M:0)) - ARF(:,K*M+(1-M:0))*ARB(:,(K-L)*M+(1-M:0));
                        ARB(:,(K-L)*M+(1-M:0)) = ARB(:,(K-L)*M+(1-M:0)) - ARB(:,K*M+(1-M:0))*ARF(:,L*M+(1-M:0));
                        ARF(:,L*M+(1-M:0))     = tmp;
                end;
        end;
        RCF = -reshape(rcf(:,:,2:end),[M,M*Pmax]);
	PE  = reshape(Pf,[M,M*(Pmax+1)]);


elseif Mode==14,
        % this is equivalent to Mode==11 but can deal with missing values
	%%%%%%%%%%%%%% [pc,R0] = burgv_nan(reshape(Y',[M,1,N]),Pmax,2);
	% Copyright S. de Waele, March 2003 - modified Alois Schloegl, 2009
	I = eye(M);
	
	sz = [M,M,Pmax+1]; 
	pc= zeros(sz); pc(:,:,1) =I;
	K = zeros(sz); K(:,:,1)  =I;
	Kb= zeros(sz); Kb(:,:,1) =I;
	P = zeros(sz);
	Pb= zeros(sz);

	%[P(:,:,1),nn]= covm(Y);
	[P(:,:,1)]= C(:,1:M);	%% no normalization 
	Pb(:,:,1)= P(:,:,1);
	f = Y;
	b = Y;

	%the recursive algorithm
	for i = 1:Pmax,
		v = f(2:end,:);
		w = b(1:end-1,:);

		%% no normalization 
		[Rvv,nn] = covm(v); %Pfhat
		[Rww,nn] = covm(w); %Pbhat
		[Rvw,nn] = covm(v,w); %Pfbhat
		[Rwv,nn] = covm(w,v); % = Rvw', written out for symmetry
		delta = lyap(Rvv*inv(P(:,:,i)),inv(Pb(:,:,i))*Rww,-2*Rvw);

		TsqrtS = chol( P(:,:,i))'; %square root M defined by: M=Tsqrt(M)*Tsqrt(M)'
		TsqrtSb= chol(Pb(:,:,i))'; 
		pc(:,:,i+1) = inv(TsqrtS)*delta*inv(TsqrtSb)';

		%The forward and backward reflection coefficient
		K(:,:,i+1) = -TsqrtS *pc(:,:,i+1) *inv(TsqrtSb);
		Kb(:,:,i+1)= -TsqrtSb*pc(:,:,i+1)'*inv(TsqrtS);

		%filtering the reflection coefficient out:
		f = (v'+ K(:,:,i+1)*w')';
		b = (w'+Kb(:,:,i+1)*v')';

		%The new R and Rb:
		%residual matrices
		P(:,:,i+1)  = (I-TsqrtS *pc(:,:,i+1) *pc(:,:,i+1)'*inv(TsqrtS ))*P(:,:,i); 
		Pb(:,:,i+1) = (I-TsqrtSb*pc(:,:,i+1)'*pc(:,:,i+1) *inv(TsqrtSb))*Pb(:,:,i); 
	end %for i = 1:Pmax,
	R0 = PE(:,1:M); 

        %%%%%%%%%% [rcf,rcb,Pf,Pb] = pc2rcv(pc,R0);
	sz = [M,M,Pmax+1]; 
	rcf  = zeros(sz); rcf(:,:,1)  = I; 
	Pf   = zeros(sz); Pf(:,:,1)   = R0;
	rcb  = zeros(sz); rcb(:,:,1) = I; 
	Pb   = zeros(sz); Pb(:,:,1)  = R0;
	for p = 1:Pmax,
		TsqrtPf = chol( Pf(:,:,p))'; %square root M defined by: M=Tsqrt(M)*Tsqrt(M)'
		TsqrtPb = chol(Pb(:,:,p))'; 
		%reflection coefficients
		rcf(:,:,p+1)= -TsqrtPf *pc(:,:,p+1) *inv(TsqrtPb);	
		rcb(:,:,p+1)= -TsqrtPb *pc(:,:,p+1)'*inv(TsqrtPf );   
		%residual matrices
		Pf(:,:,p+1) = (I-TsqrtPf *pc(:,:,p+1) *pc(:,:,p+1)'*inv(TsqrtPf))*Pf(:,:,p); 
		Pb(:,:,p+1) = (I-TsqrtPb *pc(:,:,p+1)'*pc(:,:,p+1) *inv(TsqrtPb))*Pb(:,:,p); 
	end %for p = 2:order,
	%%%%%%%%%%%%%% end %%%%%%

        %%%%% Convert reflection coefficients RC to autoregressive parameters
        ARF = zeros(M,M*Pmax); 
        ARB = zeros(M,M*Pmax); 
        for K = 1:Pmax,
                ARF(:,K*M+(1-M:0)) = -rcf(:,:,K+1);	
                ARB(:,K*M+(1-M:0)) = -rcb(:,:,K+1);	
                for L = 1:K-1,
                        tmp                    = ARF(:,L*M+(1-M:0)) - ARF(:,K*M+(1-M:0))*ARB(:,(K-L)*M+(1-M:0));
                        ARB(:,(K-L)*M+(1-M:0)) = ARB(:,(K-L)*M+(1-M:0)) - ARB(:,K*M+(1-M:0))*ARF(:,L*M+(1-M:0));
                        ARF(:,L*M+(1-M:0))     = tmp;
                end;
        end;        
        RCF = -reshape(rcf(:,:,2:end),[M,M*Pmax]);
	PE  = reshape(Pf,[M,M*(Pmax+1)]);


elseif Mode==15,  %%%%% Least Squares
	%% FIXME
        for K=1:Pmax,
                [C(:,K*M+(1:M)),n] = covm(Y(K+1:N,:),Y(1:N-K,:),'M');
%                C(K*M+(1:M),:) = C(K*M+(1:M),:)/N;
	end; 
	ARF = C(:,1:M)'/C(:,M+1:end)';
	PE  = covm(C(:,1:M)' - ARF * C(:,M+1:end)');
	RCF = zeros(M, M*Pmax);


elseif 0, 
	%%%%% ARFIT and handling missing values 
	% compute QR factorization for model of order pmax
	[R, scale]   = arqr(Y, Pmax, 0);
	 % select order of model
  	popt         = Pmax; % estimated optimum order 
  	np           = M*Pmax; % number of parameter vectors of length m
  	% decompose R for the optimal model order popt according to 
  	%
  	%   | R11  R12 |
  	% R=|          |
  	%   | 0    R22 |
  	%
  	R11   = R(1:np, 1:np);
  	R12   = R(1:np, Pmax+1:Pmax+M);    
  	R22   = R(M*Pmax+1:Pmax+M, Pmax+1:Pmax+M);
	A     = (R11\R12)';
  	% return covariance matrix
  	dof   = N-Pmax-M*Pmax;                % number of block degrees of freedom
  	PE    = R22'*R22./dof;        % bias-corrected estimate of covariance matrix

	try
		RCF = [];
		[w, ARF, PE] = arfit(Y, Pmax, Pmax, 'sbc', 'zero');
	catch
		ARF = zeros(M,M*Pmax); 
		RCF = ARF;
	end; 


elseif Mode==22 %%%%% Modified Partial Correlation Estimation: Vieira-Morf [2,5] using unbiased covariance estimates.
        %--------Initialization----------
        F = Y;
        B = Y;
        [PEF, n] = covm(Y(2:N,:),'M');
        PEF = PEF./n;
        [PEB, n] = covm(Y(1:N-1,:),'M');
        PEB = PEB./n;
        %---------------------------------
        for K = 1:Pmax,
            %---Update the estimated error covariances(15.89) in [2]---
            [PEFhat,n] = covm(F(K+1:N,:),'M');
            PEFhat = PEFhat./n;
                
            [PEBhat,n] = covm(B(1:N-K,:),'M');
            PEBhat = PEBhat./n;
        
            [PEFBhat,n] = covm(F(K+1:N,:),B(1:N-K,:),'M');
            PEFBhat = PEFBhat./n;
            
            %---Compute estimated normalized partial correlation matrix(15.88)in [2]---
            Rho = inv(chol(PEFhat)')*PEFBhat*inv(chol(PEBhat));
            
            %---Update forward and backward reflection coefficients (15.82) and (15.83) in [2]---
            ARF(:,K*M+(1-M:0)) = chol(PEF)'*Rho*inv(chol(PEB)');
            ARB(:,K*M+(1-M:0)) = chol(PEB)'*Rho'*inv(chol(PEF)');
            
            %---------------------------------
            tmp        = F(K+1:N,:) - B(1:N-K,:)*ARF(:,K*M+(1-M:0)).';
            B(1:N-K,:) = B(1:N-K,:) - F(K+1:N,:)*ARB(:,K*M+(1-M:0)).';
            F(K+1:N,:) = tmp;

            for L = 1:K-1,
                    tmp      = ARF(:,L*M+(1-M:0))   - ARF(:,K*M+(1-M:0))*ARB(:,(K-L)*M+(1-M:0));
                    ARB(:,(K-L)*M+(1-M:0)) = ARB(:,(K-L)*M+(1-M:0)) - ARB(:,K*M+(1-M:0))*ARF(:,L*M+(1-M:0));
                    ARF(:,L*M+(1-M:0))   = tmp;
            end;

            RCF(:,K*M+(1-M:0)) = ARF(:,K*M+(1-M:0));
            RCB(:,K*M+(1-M:0)) = ARB(:,K*M+(1-M:0));
            
            %---Update forward and backward error covariances (15.75) and (15.76) in [2]---
            PEF = (eye(M)-ARF(:,K*M+(1-M:0))*ARB(:,K*M+(1-M:0)))*PEF;
            PEB = (eye(M)-ARB(:,K*M+(1-M:0))*ARF(:,K*M+(1-M:0)))*PEB;
            
            PE(:,K*M+(1:M)) = PEF;
        end
        

elseif Mode==25 %%%%Modified Partial Correlation Estimation: Vieira-Morf [2,5] using biased covariance estimates.
        %--------Initialization----------
        F = Y;
        B = Y;
        [PEF, n] = covm(Y(2:N,:),'M');
        PEF = PEF./N;
        [PEB, n] = covm(Y(1:N-1,:),'M');
        PEB = PEB./N;
        %---------------------------------
        for K = 1:Pmax,
            %---Update the estimated error covariances(15.89) in [2]---
            [PEFhat,n] = covm(F(K+1:N,:),'M');
            PEFhat = PEFhat./N;
                
            [PEBhat,n] = covm(B(1:N-K,:),'M');
            PEBhat = PEBhat./N;
        
            [PEFBhat,n] = covm(F(K+1:N,:),B(1:N-K,:),'M');
            PEFBhat = PEFBhat./N;
            
            %---Compute estimated normalized partial correlation matrix(15.88)in [2]---
            Rho = inv(chol(PEFhat)')*PEFBhat*inv(chol(PEBhat));
            
            %---Update forward and backward reflection coefficients (15.82) and (15.83) in [2]---
            ARF(:,K*M+(1-M:0)) = chol(PEF)'*Rho*inv(chol(PEB)');
            ARB(:,K*M+(1-M:0)) = chol(PEB)'*Rho'*inv(chol(PEF)');
            
            %---------------------------------
            tmp        = F(K+1:N,:) - B(1:N-K,:)*ARF(:,K*M+(1-M:0)).';
            B(1:N-K,:) = B(1:N-K,:) - F(K+1:N,:)*ARB(:,K*M+(1-M:0)).';
            F(K+1:N,:) = tmp;

            for L = 1:K-1,
                    tmp      = ARF(:,L*M+(1-M:0))   - ARF(:,K*M+(1-M:0))*ARB(:,(K-L)*M+(1-M:0));
                    ARB(:,(K-L)*M+(1-M:0)) = ARB(:,(K-L)*M+(1-M:0)) - ARB(:,K*M+(1-M:0))*ARF(:,L*M+(1-M:0));
                    ARF(:,L*M+(1-M:0))   = tmp;
            end;

            RCF(:,K*M+(1-M:0)) = ARF(:,K*M+(1-M:0));
            RCB(:,K*M+(1-M:0)) = ARB(:,K*M+(1-M:0));
            
            %---Update forward and backward error covariances (15.75) and (15.76) in [2]---
            PEF = (eye(M)-ARF(:,K*M+(1-M:0))*ARB(:,K*M+(1-M:0)))*PEF;
            PEB = (eye(M)-ARB(:,K*M+(1-M:0))*ARF(:,K*M+(1-M:0)))*PEB;
            
            PE(:,K*M+(1:M)) = PEF;
        end



        
%%%%% EXPERIMENTAL VERSIONS %%%%%

elseif Mode==90;  
	% similar to MODE=0
	%% not recommended
        C(:,1:M) = C(:,1:M)/N;
        F = Y;
        B = Y;
        PEF = PE(:,1:M);	%CHANGED%
        PEB = PE(:,1:M);	%CHANGED%
        for K=1:Pmax,
                [D,n] = covm(Y(K+1:N,:),Y(1:N-K,:),'M');
	        D = D/N;
                ARF(:,K*M+(1-M:0)) = D/PEB;
                ARB(:,K*M+(1-M:0)) = D'/PEF;

                tmp        = F(K+1:N,:) - B(1:N-K,:)*ARF(:,K*M+(1-M:0))';
                B(1:N-K,:) = B(1:N-K,:) - F(K+1:N,:)*ARB(:,K*M+(1-M:0))';
                F(K+1:N,:) = tmp;

                for L = 1:K-1,
                        tmp      = ARF(:,L*M+(1-M:0))   - ARF(:,K*M+(1-M:0))*ARB(:,(K-L)*M+(1-M:0));
                        ARB(:,(K-L)*M+(1-M:0)) = ARB(:,(K-L)*M+(1-M:0)) - ARB(:,K*M+(1-M:0))*ARF(:,L*M+(1-M:0));
                        ARF(:,L*M+(1-M:0))   = tmp;
                end;

                RCF(:,K*M+(1-M:0)) = ARF(:,K*M+(1-M:0));
                RCB(:,K*M+(1-M:0)) = ARB(:,K*M+(1-M:0));

                PEF = [eye(M) - ARF(:,K*M+(1-M:0))*ARB(:,K*M+(1-M:0))]*PEF;
                PEB = [eye(M) - ARB(:,K*M+(1-M:0))*ARF(:,K*M+(1-M:0))]*PEB;
                PE(:,K*M+(1:M)) = PEF;        
        end;

        
elseif Mode==91, %%%%% Levinson-Wiggens-Robinson (LWR) algorithm using biased correlation function
	% ===== In [1,2] this algorithm is denoted 'Multichannel Yule-Walker' ===== %
	% similar to MODE=1
	%% not recommended
        C(:,1:M) = C(:,1:M)/N;
        PEF = PE(:,1:M);	%CHANGED%
        PEB = PE(:,1:M);	%CHANGED%

        for K=1:Pmax,
                [C(:,K*M+(1:M)),n] = covm(Y(K+1:N,:),Y(1:N-K,:),'M');
                C(:,K*M+(1:M)) = C(:,K*M+(1:M))/N;

                D = C(:,K*M+(1:M));
                for L = 1:K-1,
                        D = D - ARF(:,L*M+(1-M:0))*C(:,(K-L)*M+(1:M));
                end;
                ARF(:,K*M+(1-M:0)) = D / PEB;	
                ARB(:,K*M+(1-M:0)) = D'/ PEF;	
                for L = 1:K-1,
                        tmp                    = ARF(:,L*M+(1-M:0)) - ARF(:,K*M+(1-M:0))*ARB(:,(K-L)*M+(1-M:0));
                        ARB(:,(K-L)*M+(1-M:0)) = ARB(:,(K-L)*M+(1-M:0)) - ARB(:,K*M+(1-M:0))*ARF(:,L*M+(1-M:0));
                        ARF(:,L*M+(1-M:0))     = tmp;
                end;

                RCF(:,K*M+(1-M:0)) = ARF(:,K*M+(1-M:0));
                RCB(:,K*M+(1-M:0)) = ARB(:,K*M+(1-M:0));

                PEF = [eye(M) - ARF(:,K*M+(1-M:0))*ARB(:,K*M+(1-M:0))]*PEF;
                PEB = [eye(M) - ARB(:,K*M+(1-M:0))*ARF(:,K*M+(1-M:0))]*PEB;
                PE(:,K*M+(1:M)) = PEF;
        end;


elseif Mode==96, %%%%% Levinson-Wiggens-Robinson (LWR) algorithm using unbiased correlation function
	% similar to MODE=6
	%% not recommended
        C(:,1:M) = C(:,1:M)/N;
        PEF = PE(:,1:M);	%CHANGED%
        PEB = PE(:,1:M);	%CHANGED%

        for K = 1:Pmax,
                [C(:,K*M+(1:M)),n] = covm(Y(K+1:N,:),Y(1:N-K,:),'M');
                C(:,K*M+(1:M)) = C(:,K*M+(1:M))./n;

                D = C(:,K*M+(1:M));
                for L = 1:K-1,
                        D = D - ARF(:,L*M+(1-M:0))*C(:,(K-L)*M+(1:M));
                end;
                ARF(:,K*M+(1-M:0)) = D / PEB;	
                ARB(:,K*M+(1-M:0)) = D'/ PEF;	
                for L = 1:K-1,
                        tmp      = ARF(:,L*M+(1-M:0))   - ARF(:,K*M+(1-M:0))*ARB(:,(K-L)*M+(1-M:0));
                        ARB(:,(K-L)*M+(1-M:0)) = ARB(:,(K-L)*M+(1-M:0)) - ARB(:,K*M+(1-M:0))*ARF(:,L*M+(1-M:0));
                        ARF(:,L*M+(1-M:0))   = tmp;
                end;

                RCF(:,K*M+(1-M:0)) = ARF(:,K*M+(1-M:0));
                RCB(:,K*M+(1-M:0)) = ARB(:,K*M+(1-M:0));

                PEF = [eye(M) - ARF(:,K*M+(1-M:0))*ARB(:,K*M+(1-M:0))]*PEF;
                PEB = [eye(M) - ARB(:,K*M+(1-M:0))*ARF(:,K*M+(1-M:0))]*PEB;
                PE(:,K*M+(1:M)) = PEF;
        end;

elseif Mode<100,
       fprintf('Warning MVAR: Mode=%i not supported\n',Mode);

%%%%% IMPUTATION METHODS %%%%%
else

	Mode0 = rem(Mode,100); 	
	if ((Mode0 >= 10) && (Mode0 < 20)), 
		Mode0 = 1; 
	end;

if 0, 


elseif Mode>=2400,  % forward and backward
% assuming that past missing values are already IMPUTED with the prediction value + innovation process
% no decaying 

 	[ARF,RCF,PE2] = mvar(Y, Pmax, Mode0);	
 	c = chol( PE2 (:, M*Pmax+(1:M)));

	Y1 = Y; 
	Y1(1,isnan(Y1(1,:))) = 0; 
	z  = [];
	for k = 2:size(Y,1)
		[z1,z] = mvfilter(ARF,eye(M),Y1(k-1,:)',z);
		ix = isnan(Y1(k,:)); 
		z1 = z1 + (randn(1,M)*c)'; 
		Y1(k,ix) = z1(ix); 
	end; 

	Y2 = flipud(Y); 
 	[ARB,RCF,PE] = mvar(Y2, Pmax, Mode0);	
	Y2(1,isnan(Y2(1,:))) = 0; 
	z  = [];
	for k = 2:size(Y2,1)
		[z2,z] = mvfilter(ARB,eye(M),Y2(k-1,:)',z);
		ix = isnan(Y(size(Y,1)-k+1,:)); 
		z2 = z2 + (randn(1,M)*c)'; 
		Y2(k,ix) = (z2(ix)' + Y2(k,ix))/2; 
	end; 
	Y2 = flipud(Y2); 
	
	Z = (Y2+Y1)/2;
	Y(isnan(Y)) = Z(isnan(Y));
	
 	[ARF,RCF,PE] = mvar(Y, Pmax, rem(Mode,100));	


elseif Mode>=2300,  % backward prediction
% assuming that past missing values are already IMPUTED with the prediction value + innovation process
% no decaying 

	Y  = flipud(Y);
 	[ARB,RCF,PE] = mvar(Y, Pmax, Mode0);	
 	c = chol(PE(:,M*Pmax+(1:M))); 
	Y1 = Y; 
	Y1(1,isnan(Y1(1,:))) = 0; 
	z  = [];
	for k = 2:size(Y,1)
		[z1,z] = mvfilter(ARB,eye(M),Y1(k-1,:)',z);
		ix = isnan(Y1(k,:)); 
		z1 = z1 + (randn(1,M)*c)'; 
		Y1(k,ix) = z1(ix); 
	end; 	
	Y1 = flipud(Y1);
 	[ARF,RCF,PE] = mvar(Y1, Pmax, rem(Mode,100));	


elseif Mode>=2200,  % forward predictions, 
% assuming that past missing values are already IMPUTED with the prediction value + innovation process
% no decaying 
 	[ARF,RCF,PE] = mvar(Y, Pmax, Mode0);	
 	c = chol(PE(:,M*Pmax+(1:M))); 
	Y1 = Y; 
	Y1(1,isnan(Y1(1,:))) = 0; 
	z  = [];
	for k = 2:size(Y,1)
		[z1,z] = mvfilter(ARF,eye(M),Y1(k-1,:)',z);
		ix = isnan(Y1(k,:)); 
		z1 = z1 + (randn(1,M)*c)'; 
		Y1(k,ix) = z1(ix); 
	end; 	
 	[ARF,RCF,PE] = mvar(Y1, Pmax, rem(Mode,100));	


elseif Mode>=1400,  % forward and backward
%assuming that past missing values are already IMPUTED with the prediction value
 	[ARF,RCF,PE] = mvar(Y, Pmax, Mode0);	
	Y1 = Y; 
	Y1(1,isnan(Y1(1,:))) = 0; 
	z  = [];
	for k = 2:size(Y,1)
		[z1,z] = mvfilter(ARF,eye(M),Y1(k-1,:)',z);
		ix = isnan(Y1(k,:)); 
		Y1(k,ix) = z1(ix); 
	end; 

	Y2 = flipud(Y); 
 	[ARB,RCF,PE] = mvar(Y2, Pmax, Mode0);	
	Y2(1,isnan(Y2(1,:))) = 0; 
	z  = [];
	for k = 2:size(Y2,1)
		[z2,z] = mvfilter(ARB,eye(M),Y2(k-1,:)',z);
		ix = isnan(Y2(k,:)); 
		Y2(k,ix) = z2(ix)'; 
	end; 
	Y2 = flipud(Y2); 
	
	Z = (Y2+Y1)/2;
	Y(isnan(Y)) = Z(isnan(Y));
	
 	[ARF,RCF,PE] = mvar(Y, Pmax, rem(Mode,100));	


elseif Mode>=1300,  % backward prediction
	Y  = flipud(Y);
 	[ARB,RCF,PE] = mvar(Y, Pmax, Mode0);	
	Y2 = Y; 
	Y2(1,isnan(Y2(1,:))) = 0; 
	z  = [];
	for k = 2:size(Y,1)
		[z2,z] = mvfilter(ARB,eye(M),Y2(k-1,:)',z);
		ix = isnan(Y2(k,:)); 
		Y2(k,ix) = z2(ix); 
	end; 	
	Y2 = flipud(Y2);
 	[ARF,RCF,PE] = mvar(Y2, Pmax, rem(Mode,100));	


elseif Mode>=1200,  % forward predictions, 
%assuming that past missing values are already IMPUTED with the prediction value
 	[ARF,RCF,PE] = mvar(Y, Pmax, Mode0);	
	Y1 = Y; 
	Y1(1,isnan(Y1(1,:))) = 0; 
	z  = [];
	for k = 2:size(Y,1)
		[z1,z] = mvfilter(ARF,eye(M),Y1(k-1,:)',z);
		ix = isnan(Y1(k,:)); 
		Y1(k,ix) = z1(ix); 
	end; 	
 	[ARF,RCF,PE] = mvar(Y1, Pmax, rem(Mode,100));	


elseif Mode>=400,  % forward and backward
% assuming that 'past' missing values are ZERO
 	[ARF,RCF,PE] = mvar(Y, Pmax, Mode0);	
	Y1 = Y; 
	Y1(isnan(Y)) = 0; 
	Z1 = mvfilter([zeros(M),ARF],eye(M),Y1')';
	Y1(isnan(Y)) = Z1(isnan(Y));

	Y  = flipud(Y);
 	[ARB,RCF,PE] = mvar(Y, Pmax, Mode0);	
	Y2 = Y; 
	Y2(isnan(Y)) = 0; 
	Z2 = mvfilter([zeros(M),ARB],eye(M),Y2')';
	Y2(isnan(Y)) = Z2(isnan(Y));
	Y2 = flipud(Y2);

 	[ARF,RCF,PE] = mvar((Y1+Y2)/2, Pmax, rem(Mode,100));	


elseif Mode>=300,  % backward prediction
% assuming that 'past' missing values are ZERO
	Y  = flipud(Y);
 	[ARB,RCF,PE] = mvar(Y, Pmax, Mode0);	
	Y2 = Y; 
	Y2(isnan(Y)) = 0; 
	Z2 = mvfilter([zeros(M),ARB],eye(M),Y2')';
	Y2(isnan(Y)) = Z2(isnan(Y));
	Y2 = flipud(Y2);

 	[ARF,RCF,PE] = mvar(Y2, Pmax, rem(Mode,100));	


elseif Mode>=200,  
% forward predictions, assuming that past missing values are ZERO
 	[ARF,RCF,PE] = mvar(Y, Pmax, Mode0);	
	Y1 = Y; 
	Y1(isnan(Y)) = 0; 
	Z1 = mvfilter([zeros(M),ARF],eye(M),Y1')';
	Y1(isnan(Y)) = Z1(isnan(Y));

 	[ARF,RCF,PE] = mvar(Y1, Pmax, rem(Mode,100));	


elseif Mode>=100,  
 	[ARF,RCF,PE] = mvar(Y, Pmax, Mode0);	
	Z1 = mvfilter(ARF,eye(M),Y')';
	Z1 = [zeros(1,M); Z1(1:end-1,:)];
	Y(isnan(Y)) = Z1(isnan(Y)); 
 	[ARF,RCF,PE] = mvar(Y, Pmax, rem(Mode,100));	


end;
end;


if any(ARF(:)==inf),
% Test for matrix division bug. 
% This bug was observed in LNX86-ML5.3, 6.1 and 6.5, but not in SGI-ML6.5, LNX86-ML6.5, Octave 2.1.35-40; Other platforms unknown.
p = 3;
FLAG_MATRIX_DIVISION_ERROR = ~all(all(isnan(repmat(0,p)/repmat(0,p)))) | ~all(all(isnan(repmat(nan,p)/repmat(nan,p))));

if FLAG_MATRIX_DIVISION_ERROR, 
	%fprintf(2,'%%% Warning MVAR: Bug in Matrix-Division 0/0 and NaN/NaN yields INF instead of NAN.  Workaround is applied.\n');
	warning('MVAR: bug in Matrix-Division 0/0 and NaN/NaN yields INF instead of NAN.  Workaround is applied.');

	%%%%% Workaround 
	ARF(ARF==inf)=NaN;
	RCF(RCF==inf)=NaN;
end;
end;	

%MAR   = zeros(M,M*Pmax);
DC     = zeros(M);
for K  = 1:Pmax,
%       VAR{K+1} = -ARF(:,K*M+(1-M:0))';
        DC  = DC + ARF(:,K*M+(1-M:0))'.^2; %DC meausure [3]
end;


function [Tr_gct, pValue_gct, Tr_igct, pValue_igct] = gct_alg(u,A,pf, ...
                                    gct_signif,igct_signif,flgPrintResults)
% function [Tr_gct, pValue_gct, Tr_igct, pValue_igct] = gct_alg(u,A,pf, ...
%                                    gct_signif,igct_signif,flgPrintResults)


if nargin < 4,
   error('GCT_ALG.M requires at least 4 input parameters.');
elseif nargin == 4,
   igct_signif = gct_signif;
   flgPrintResults = 0;
elseif nargin == 5
   if igct_signif == 0 || igct_signif == 1
      flgPrintResults = igct_signif;
      igct_signif = gct_signif;
   else
      flgPrintResults = 0;
   end;
end;
                                            
[nChannels nChannels IP] = size(A);
nSegLength = length(u);
Z=zmatrm(u,IP); gamma=Z*Z';

idx = eye(nChannels)==1;

%==========================================================================
%            Granger causality test routine
%==========================================================================
b=reshape(A,nChannels*nChannels*IP,1);
[Tr_gct,Va_gct,v_gct,th_gct,pValue_gct]=granmatx(b,gamma,pf,(1-gct_signif));
%==========================================================================
%          Main diagonal elements are filled with -1.
%==========================================================================
Tr_gct(idx)=-1;
pValue_gct(idx)=-1;

if flgPrintResults,
   format compact
%   disp('Granger causality test:')
   disp('----------------------------------------------------------------------');
   disp('                         GRANGER CAUSALITY TEST')
   disp('======================================================================');
   disp('Connectivity matrix:')
   Tr_gct
   disp('Granger causality test p-values:')
   pValue_gct
%    disp('Causality value:')
%    Va_gct
end;
%==========================================================================
% Instantaneous Granger causality test routine
%==========================================================================
[Tr_igct,Va_igct,v_igct,th_igct,pValue_igct]=granmaty(pf,nSegLength, ...
                                                          (1-igct_signif));
%==========================================================================
%        Main diagonal elements are filled with -1.
%==========================================================================
Tr_igct(idx)=-1;
pValue_igct(idx)=-1;

if flgPrintResults,
%   disp('=Instantaneous Granger causality:')
   disp('----------------------------------------------------------------------');
   disp('                  INSTANTANEOUS GRANGER CAUSALITY TEST')
   disp('======================================================================');
   disp('Instantaneous connectivity matrix:')
   Tr_igct
   disp('Instantaneous Granger causality test p-values:')
   pValue_igct
   nPairsIGC = (sum(sum(Tr_igct==1)))/2;
   if nPairsIGC == 0,
      disp('>>>> Instantaneous Granger causality NOT detected.')
   elseif nPairsIGC == 1,
      disp('>>>> There is a pair of channels with significant instantaneous ')
      disp('     Granger causality.')
   else
      disp(['>>>> There are ' int2str(nPairsIGC) ' pairs of channels with'])
      disp('      significant Instantaneous Causality.')
   end;
   disp(' ');
end;

%==========================================================================

% function [Tr,Va,v,th,pValue]=granmatx(b,G,SU);
% Program to test granger causality struture
%
% input: b - reshaped A matrix (A,1,Numch times p)
%        G - data covariance of vector times N (number of points)
%        SU - covariance of modelling errors
%        significance - statistical significance level
%
% output: Tr -test result matrix (i,j) entry=1 j->i causality cannot
%             be rejected
%         Va - test value matrix
%         v  - degrees of freedom
%         th - threshold value
%         pValue - p-values
% % 01/30/1998 - L.A.B.
%
function [Tr,Va,v,th,pValue]=granmatx(b,G,SU,significance)
[n m]=size(SU);
Va=zeros(n,m);
Tr=zeros(n,m);
CO=zeros(n,m);
pValue=zeros(n,m);

for i=1:n
  for j=1:n
    if i~=j
      CO(i,j)=1;
      [Tr(i,j),Va(i,j),v,th,pValue(i,j)]=grangt(CO,b,G,SU,significance);
      CO(i,j)=0;
    end
  end
end

%==========================================================================

% Causality test
%
% input: CO - matrix describing the structure for testing - 1 position to test.
%        b - parameter vector
%        G - Gamma*T - data covariance matriz times T record length
%        SU - residual covariance
%        significance - statistical significance level
%
% output: y - test result - 0 granger causality rejected - 1 not rejected
%         value - test value
%         v - degrees o freedom # oconstraints.
%         th -threschold
%
% Test for Granger Causality
%
% % 01/30/1998 - L.A.B.
%
function [y,value,v,th,pValue]=grangt(CO,b,G,SU,significance);
[n,m]=size(CO);
lb=length(b);
p0=lb/(m*n);
Ct=reshape(CO,1,m*n);
Ct1=[ ];
for i=1:p0
  Ct1=[Ct1 Ct];
end
Ct=Ct1;
l=sum(Ct);
K=zeros(l,m*n*p0);
for i=1:l
  [p q]=max(Ct);
  K(i,q)=1;
  Ct(q)=0;
end
C=K;

value=(C*b)'*inv(C*kron(inv(G),SU)*C')*C*b;
v=l;
th=chi2inv(significance,v);

y=value>=th;
pValue=1-chi2cdf(value,v);

%==========================================================================

function [Tr,Va,v,th,pValue]=granmaty(pf,N,significance)
% Test Granger causality structure
%
%[Tr,Va,v,th,pValue]=granmaty(SU,N,significance);
% Program to test granger causality structure
%
% input: N (number of points)
%        pf - covariance of modelling errors
%        significance - test significance level
%
% output: Tr -test result matrix (i,j) entry=1 j->i causality cannot
%             be rejected
%         Va - test value matrix
%         v  - degrees of freedom
%         th - threshold value
%         pValue - test p-value
%
% % 01/30/1998 - L.A.B.
% % 27/10/2009 - Stein - changed to v=1.
%
% disp('Instantaneous Granger causality test: ');
% significance
[n m]=size(pf);
Va=zeros(n,m);
Tr=zeros(n,m);
CO=zeros(n,m);
pValue=zeros(n,m);
for i=1:n
   for j=1:n
      if i>j
         CO(i,j)=1;
         [Tr(i,j),Va(i,j),v,th,pValue(i,j)]=instata(CO,pf,N,significance);
         Tr(j,i)=Tr(i,j);
         Va(j,i)=Va(i,j);
         CO(i,j)=0;
         pValue(j,i)=pValue(i,j);
      end
   end
end

%==========================================================================
function [y,value,v,th,pValue]=instata(CO,pf,N,significance)
% Test for instataneous causality
% input: CO - matrix describing the structure for testing - 1 position to test.
%        pf - residual covariance
%        N - number of poinst
%
% output: y - test result - 0 instantaneous causality rejected - 1 not rejected
%         value - test value
%         v - degrees of freedom # constraints.
%         th -threschold
si=vech(pf);
CO=tril(CO);
[m n]=size(CO);
lb=length(si);
Ct=vech(CO);
Ct1=zeros(size(Ct'));
Ctf=[ ];
l=sum(Ct');
for i=1:length(Ct)
   if Ct(i)==1
      Ct1(i)=1;
      Ctf=[Ctf; Ct1];
      Ct1=zeros(size(Ct'));
   end
end
C=Ctf;
ln=length(pf);
D=pinv(dmatrix(ln));
value=N*(C*si)'*inv(2*C*D*kron(pf,pf)*D'*C')*C*si;
v=1; %2; % Chi-square distribution degree of freedom. Stein - Mudou para v=1.
th=chi2inv(significance,v);
y=value>=th;
pValue=1-chi2cdf(value,v); % p-value of instantaneous Granger causality test

%==========================================================================
%
%  01/30/1998 - L.A.B.
%
function D=dmatrix(m)
D=zeros(m*m,m*(m+1)/2);
u=[ ];
v=[];
for j=1:m
   for i=1:m
      u=[u ;[i j]];
      if j<=i
         v=[v ;[i j]];
      end
   end
end
w=fliplr(v);
for i=1:m*m
   for j=1:m*(m+1)/2
      if sum(u(i,:)==v(j,:))==2
         D(i,j)=1;
      end
   end
   for j=1:m*(m+1)/2
      if sum(u(i,:)==w(j,:))==2
         D(i,j)=1;
      end
   end
end

%==========================================================================
% Vech or vec is matrix column stacking operator function
%
%function y=vech(Y);
% 
% input:  Y - matrix
% output: y - Stacked column vector
%
% % 01/30/1998 - L.A.B.

function y=vech(Y)
y=[ ];
[m n]=size(Y);
for i=1:m
   y=[y ;Y(i:n,i)];
end

%==========================================================================
% Computation of Z - data structure (no estimation of the mean)
%
% function Z=zmatr(Y,p);
%
% input:  Y - data in row vectors 
%         p - model covariance order
%
% output: Z
%
% 01/30/1998 - L.A.B.
%
function Z=zmatrm(Y,p)
[K T] = size(Y);
y1 = [zeros(K*p,1);reshape(flipud(Y),K*T,1)];
Z =  zeros(K*p,T);
for i=0:T-1
   Z(:,i+1)=flipud(y1(1+K*i:K*i+K*p));
end
%Z=[ones(1,T);Z];

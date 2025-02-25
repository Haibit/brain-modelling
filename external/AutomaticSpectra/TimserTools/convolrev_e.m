function [z,ASAcontrol] = convolrev_e(varargin)
%CONVOLREV_E Convolution sum with one vector reversed
%   Z = CONVOLREV_E(X,Y) is the convolution sum of a flipped version of 
%   vector X with vector Y. With all vectors given as columns, this is 
%   the same as CONVOL_E(FLIPUD(X),Y).
%   
%   CONVOLREV_E(X) is the same as CONVOLREV_E(X,X).
%   
%   CONVOLREV_E(X,Y,SHIFT1,SHIFT2) or CONVOLREV_E(X,SHIFT1,SHIFT2)
%   returns only the elements from SHIFT1 up to SHIFT2.
%   
%   C = CONVOLREV_E(X,N_LAG) can be used for computing (biased) 
%   autocovariance estimates of a series. The raw (unscaled) 
%   autocovariance sequence Z = CONVOLREV_E(X) is symmetric.
%   C = CONVOLREV_E(X,N_LAG) returns the central element of Z and N_LAG 
%   additional elements in C.
%   
%   CONVOLREV_E is an ARMASA main function.
%   
%   See also: CONVOL_E, DECONVOL_E, CONV.

%Header
%=====================================================================

%Declaration of variables
%------------------------

%Declare and assign values to local variables
%according to the input argument pattern
[x,y,shift1,shift2,ASAcontrol] = ASAarg(varargin, ...
{'x'        ,'y'        ,'shift1'     ,'shift2'     ,'ASAcontrol'},...
{'isnumeric','isnumeric','isintscalar','isintscalar','isstruct'  },...
{'x'                                                             },...
{'x'        ,'shift1'                                            },...
{'x'        ,'y'                                                 },...
{'x'        ,'shift1'   ,'shift2'                                },...
{'x'        ,'y'        ,'shift1'     ,'shift2'                  });

if isequal(nargin,1) & ~isempty(ASAcontrol)
      %ASAcontrol is the only input argument
   ASAcontrol.error_chk = 0;
   ASAcontrol.run = 0;
end

%ARMASA-function version information
%-----------------------------------

%This ARMASA-function is characterized by
%its current version,
ASAcontrol.is_version = [2000 12 13 21 0 0];
%and its compatability with versions down to,
ASAcontrol.comp_version = [2000 11 1 12 0 0];

%Checks
%------

if ~isfield(ASAcontrol,'error_chk') | ASAcontrol.error_chk
   %Perform standard error checks
   %Input argument format checks
   ASAcontrol.error_chk = 1;
   if ~isnum(x)
      error(ASAerr(11,'x'))
   end
   if ~isempty(y) & ~isnum(y)
      error(ASAerr(11,'y'))
   end
   if ~isempty(shift1) & (~isnum(shift1) | ...
         ~isintscalar(shift1) | shift1<0)
      error(ASAerr(17,'shift1'))
   end
   if ~isempty(shift2) & (~isnum(shift2) | ...
         ~isintscalar(shift2) | shift2<0)
      error(ASAerr(17,'shift2'))
   end
   
   %Input argument value checks
   if ~isvector(x)
      error([ASAerr(14) ASAerr(15,'x')])
   else
      l_x = length(x);
      l_y = length(x);
   end
   if ~isempty(y)
      if ~isvector(y)
         error([ASAerr(14) ASAerr(15,'y')])
      end
      l_y = length(y);
   end
   if ~isempty(shift1) & isempty(shift2) & shift1 >= l_y
      error(ASAerr(19,num2str(l_x-1)))
   elseif ~(isempty(shift1) & isempty(shift2)) & ...
         (shift1 > shift2 | shift2 > l_x+l_y-1 | ...
         shift1==0)
      error(ASAerr(20,{'shift1','shift2'}))
   end
end

if ~isfield(ASAcontrol,'version_chk') | ASAcontrol.version_chk
      %Perform version check
   ASAcontrol.version_chk = 1;
      
   %Make sure the requested version of this function
   %complies with its actual version
   ASAversionchk(ASAcontrol);
end

if ~isfield(ASAcontrol,'run') | ASAcontrol.run
   ASAcontrol.run = 1;
end

if ASAcontrol.run %Run the computational kernel   

%Main   
%=====================================================
   
%Initialization of variables
%---------------------------

%Duplicate the first input vector if only one has been
%provided
if isempty(y)
   y = x;
end

%Asess the original vector sizes
s_x = size(x);
s_y = size(y);
l_x = length(x);
l_y = length(y);

%Make sure both vectors are columns
x = x(:);
y = y(:);

%Determine the range of output elements
if isempty(shift1)&isempty(shift2) %The maximum number
      %of elements will be returned 
   shift1 = 1;
   shift2 = l_x+l_y-1;
elseif isempty(shift2) %The vectors are equal and a
      %specific number of shifts are requested
   %Asess the offset from the central element of the
   %output signal
   shift2 = l_y+shift1;
      
   %Asess the central element of the output signal
   shift1 = l_y;
end

%Reversed convolution
%--------------------

z = conv(flipud(x),y);

%Arranging output arguments
%--------------------------

%Return the requested range of the output signal 
z = z(shift1:shift2);

%Return rows if the original vectors were formatted
%like that
if s_x(1)==1 & s_y(1)==1
   z = z';
end

%Footer
%=====================================================

else %Skip the computational kernel
   %Return ASAcontrol as the first output argument
   if nargout>1
      warning(ASAwarn(9,mfilename,ASAcontrol))
   end
   z = ASAcontrol;
   ASAcontrol = [];
end

%Program history
%======================================================================
%
% Version                Programmer(s)          E-mail address
% -------                -------------          --------------
% [2000 11  1 12 0 0]    W. Wunderink           wwunderink01@freeler.nl
% [2000 12 13 21 0 0]         ,,                          ,,
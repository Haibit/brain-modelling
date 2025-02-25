function peerreset

% PEERRESET clears all jobs on the local peer server and switches to
% zombie mode. If you also want to erase the settings for group, allowuser,
% allowgroup and allowhost, then you should execute "clear peer".
%
% Use as
%   peerreset
%
% See also PEERMASTER, PEERSLAVE, PEERZOMBIE

% -----------------------------------------------------------------------
% Copyright (C) 2010, Robert Oostenveld
%
% This program is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
%
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
%
% You should have received a copy of the GNU General Public License
% along with this program.  If not, see <http://www.gnu.org/licenses/
%
% $Id: peerreset.m 7123 2012-12-06 21:21:38Z roboos $
% -----------------------------------------------------------------------

peer('status', 0);

joblist = peer('joblist');
for i=1:length(joblist)
  peer('clear', joblist(i).jobid);
end


function val = bigendian;

% BIGENDIAN returns 1 (true) on a big endian machine, e.g. with a SUN Sparc
% or Apple G4 processor, or 0 (false) otherwise
%
% Example
%   if (bigendian)
%     % do something, e.g. swap some bytes
%    end
%
% See also LITTLEENDIAN, SWAPBYTES, TYPECAST

% Copyrigth (C) 2007, Robert Oostenveld
%
% This file is part of FieldTrip, see http://www.ru.nl/neuroimaging/fieldtrip
% for the documentation and details.
%
%    FieldTrip is free software: you can redistribute it and/or modify
%    it under the terms of the GNU General Public License as published by
%    the Free Software Foundation, either version 3 of the License, or
%    (at your option) any later version.
%
%    FieldTrip is distributed in the hope that it will be useful,
%    but WITHOUT ANY WARRANTY; without even the implied warranty of
%    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%    GNU General Public License for more details.
%
%    You should have received a copy of the GNU General Public License
%    along with FieldTrip. If not, see <http://www.gnu.org/licenses/>.
%
% $Id: bigendian.m 11096 2016-01-22 09:22:33Z roboos $

val = (typecast(uint8([0 1]), 'uint16')==1);

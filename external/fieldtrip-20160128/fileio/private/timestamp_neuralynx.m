function [ts] = timestamp_neuralynx(tsl, tsh)

% TIMESTAMP_NEURALYNX merge the low and high part of Neuralynx timestamps
% into a single uint64 value

% Copyright (C) 2007, Robert Oostenveld
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
% $Id: timestamp_neuralynx.m 11096 2016-01-22 09:22:33Z roboos $

if ~isa(tsl, 'uint32') && ~isa(tsl, 'int32')
  error('invalid input');
elseif ~isa(tsh, 'uint32') && ~isa(tsl, 'int32')
  error('invalid input');
end

% convert the 32 bit low and 32 bit high timestamp into a 64 bit integer
dum = zeros(2, length(tsh), 'uint32');
if littleendian
  dum(1,:) = tsl;
  dum(2,:) = tsh;
else
  dum(1,:) = tsh;
  dum(2,:) = tsl;
end

ts = typecast(dum(:), 'uint64');

function [simulated] = ft_dipolesimulation(cfg)

% FT_DIPOLESIMULATION computes the field or potential of a simulated dipole
% and returns a datastructure identical to the FT_PREPROCESSING function.
%
% Use as
%   data = ft_dipolesimulation(cfg)
%
% The dipoles position and orientation have to be specified with
%   cfg.dip.pos     = [Rx Ry Rz] (size Nx3)
%   cfg.dip.mom     = [Qx Qy Qz] (size 3xN)
%
% The timecourse of the dipole activity is given as a single vector or as a
% cell-array with one vectors per trial
%   cfg.dip.signal
% or by specifying a sine-wave signal
%   cfg.dip.frequency    in Hz
%   cfg.dip.phase        in radians
%   cfg.dip.amplitude    per dipole
%   cfg.ntrials          number of trials
%   cfg.triallength      time in seconds
%   cfg.fsample          sampling frequency in Hz
%
% Random white noise can be added to the data in each trial, either by
% specifying an absolute or a relative noise level
%   cfg.relnoise    = add noise with level relative to simulated signal
%   cfg.absnoise    = add noise with absolute level
%   cfg.randomseed  = 'yes' or a number or vector with the seed value (default = 'yes')
%
% Optional input arguments are
%   cfg.channel    = Nx1 cell-array with selection of channels (default = 'all'),
%                    see FT_CHANNELSELECTION for details
%   cfg.dipoleunit = units for dipole amplitude (default nA*m)
%   cfg.chanunit   = units for the channel data
%
% The volume conduction model of the head should be specified as
%   cfg.headmodel     = structure with volume conduction model, see FT_PREPARE_HEADMODEL
%
% The EEG or MEG sensor positions should be specified as
%   cfg.elec          = structure with electrode positions, see FT_DATATYPE_SENS
%   cfg.grad          = structure with gradiometer definition, see FT_DATATYPE_SENS
%   cfg.elecfile      = name of file containing the electrode positions, see FT_READ_SENS
%   cfg.gradfile      = name of file containing the gradiometer definition, see FT_READ_SENS
%
% See also FT_SOURCEANALYSIS, FT_SOURCESTATISTICS, FT_SOURCEPLOT, FT_FREQSIMULATION, 
% FT_CONNECTIVITYSIMULATION

% Undocumented local options
% cfg.feedback
% cfg.previous
% cfg.version

% Copyright (C) 2004, Robert Oostenveld
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
% $Id: ft_dipolesimulation.m 11080 2016-01-19 08:39:26Z roboos $

revision = '$Id: ft_dipolesimulation.m 11080 2016-01-19 08:39:26Z roboos $';

% do the general setup of the function
ft_defaults
ft_preamble init
ft_preamble debug
ft_preamble provenance
ft_preamble randomseed
ft_preamble trackconfig

% the abort variable is set to true or false in ft_preamble_init
if abort
  return
end

cfg = ft_checkconfig(cfg, 'renamed', {'hdmfile', 'headmodel'});
cfg = ft_checkconfig(cfg, 'renamed', {'vol',     'headmodel'});

% set the defaults
if ~isfield(cfg, 'dip'),        cfg.dip = [];             end
if ~isfield(cfg.dip, 'pos'),    cfg.dip.pos = [-5 0 15];  end
if ~isfield(cfg.dip, 'mom'),    cfg.dip.mom = [1 0 0]';   end
if ~isfield(cfg, 'fsample'),    cfg.fsample = 250;        end
if ~isfield(cfg, 'relnoise'),   cfg.relnoise = 0;         end
if ~isfield(cfg, 'absnoise'),   cfg.absnoise = 0;         end
if ~isfield(cfg, 'feedback'),   cfg.feedback = 'text';    end
if ~isfield(cfg, 'channel'),    cfg.channel = 'all';      end
if ~isfield(cfg, 'dipoleunit'), cfg.dipoleunit = 'nA*m';  end
if ~isfield(cfg, 'chanunit'),   cfg.chanunit = {};        end

cfg.dip = fixdipole(cfg.dip);
Ndipoles = size(cfg.dip.pos,1);

% prepare the volume conductor and the sensor array
[headmodel, sens, cfg] = prepare_headmodel(cfg, []);

if ~isfield(cfg, 'ntrials')
  if isfield(cfg.dip, 'signal')
    cfg.ntrials = length(cfg.dip.signal);
  else
    cfg.ntrials = 20;
  end
end
Ntrials  = cfg.ntrials;

if isfield(cfg.dip, 'frequency')
  % this should be a column vector
  cfg.dip.frequency = cfg.dip.frequency(:);
end

if isfield(cfg.dip, 'phase')
  % this should be a column vector
  cfg.dip.phase = cfg.dip.phase(:);
end

% no signal was given, compute a cosine-wave signal as timcourse for the dipole
if ~isfield(cfg.dip, 'signal')
  % set some additional defaults if neccessary
  if ~isfield(cfg.dip, 'frequency')
    cfg.dip.frequency = ones(Ndipoles,1)*10;
  end
  if ~isfield(cfg.dip, 'phase')
    cfg.dip.phase = zeros(Ndipoles,1);
  end
  if ~isfield(cfg.dip, 'amplitude')
    cfg.dip.amplitude = ones(Ndipoles,1);
  end
  if ~isfield(cfg, 'triallength')
    cfg.triallength = 1;
  end
  % compute a cosine-wave signal wit the desired frequency, phase and amplitude for each dipole
  nsamples = round(cfg.triallength*cfg.fsample);
  time     = (0:(nsamples-1))/cfg.fsample;
  for i=1:Ndipoles
    cfg.dip.signal(i,:) = cos(cfg.dip.frequency(i)*time*2*pi + cfg.dip.phase(i)) * cfg.dip.amplitude(i);
  end
end

% construct the timecourse of the dipole activity for each individual trial
if ~iscell(cfg.dip.signal)
  dipsignal = {};
  time      = {};
  nsamples  = length(cfg.dip.signal);
  for trial=1:Ntrials
    % each trial has the same dipole signal
    dipsignal{trial} = cfg.dip.signal;
    time{trial} = (0:(nsamples-1))/cfg.fsample;
  end
else
  dipsignal = {};
  time      = {};
  for trial=1:Ntrials
    % each trial has a different dipole signal
    dipsignal{trial} = cfg.dip.signal{trial};
    time{trial} = (0:(length(dipsignal{trial})-1))/cfg.fsample;
  end
end

dippos    = cfg.dip.pos;
dipmom    = cfg.dip.mom;

if ~iscell(dipmom)
  dipmom = {dipmom};
end

if ~iscell(dippos)
  dippos = {dippos};
end

if length(dippos)==1
  dippos = repmat(dippos, 1, Ntrials);
elseif length(dippos)~=Ntrials
  error('incorrect number of trials specified in the dipole position');
end

if length(dipmom)==1
  dipmom = repmat(dipmom, 1, Ntrials);
elseif length(dipmom)~=Ntrials
  error('incorrect number of trials specified in the dipole moment');
end

simulated.trial  = {};
simulated.time   = {};
ft_progress('init', cfg.feedback, 'computing simulated data');
for trial=1:Ntrials
  ft_progress(trial/Ntrials, 'computing simulated data for trial %d\n', trial);
  if numel(cfg.chanunit) == numel(cfg.channel)
      lf = ft_compute_leadfield(dippos{trial}, sens, headmodel, 'dipoleunit', cfg.dipoleunit, 'chanunit', cfg.chanunit);
  else
      lf = ft_compute_leadfield(dippos{trial}, sens, headmodel);
  end
  nsamples = size(dipsignal{trial},2);
  nchannels = size(lf,1);
  simulated.trial{trial} = zeros(nchannels,nsamples);
  for i = 1:3,
    simulated.trial{trial}  = simulated.trial{trial} + lf(:,i:3:end) * ...
      (repmat(dipmom{trial}(i:3:end),1,nsamples) .* dipsignal{trial});
  end
  simulated.time{trial}   = time{trial};
end
ft_progress('close');

if ft_senstype(sens, 'meg')
  simulated.grad = sens;
elseif ft_senstype(sens, 'meg')
  simulated.elec = sens;
end

% determine RMS value of simulated data
ss = 0;
sc = 0;
for trial=1:Ntrials
  ss = ss + sum(simulated.trial{trial}(:).^2);
  sc = sc + length(simulated.trial{trial}(:));
end
rms = sqrt(ss/sc);
fprintf('RMS value of simulated data is %g\n', rms);

% add noise to the simulated data
for trial=1:Ntrials
  relnoise = randn(size(simulated.trial{trial})) * cfg.relnoise * rms;
  absnoise = randn(size(simulated.trial{trial})) * cfg.absnoise;
  simulated.trial{trial} = simulated.trial{trial} + relnoise + absnoise;
end

simulated.fsample = cfg.fsample;
simulated.label   = sens.label;

% do the general cleanup and bookkeeping at the end of the function
ft_postamble debug
ft_postamble trackconfig
ft_postamble randomseed
ft_postamble provenance simulated
ft_postamble history    simulated
ft_postamble savevar    simulated


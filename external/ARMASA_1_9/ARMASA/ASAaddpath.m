function ASAaddpath

release = '1.2 / 05 April 2001';

ARMASA_path = fileparts(which('ASAaddpath.m'));

directory = {ARMASA_path;...
      fullfile(ARMASA_path,'ASA','');...
      fullfile(ARMASA_path,'ASA','check','');...
      fullfile(ARMASA_path,'ASA','message','');...
      fullfile(ARMASA_path,'ASA','ASAcontrol','');...
      fullfile(ARMASA_path,'ASA','ASAglob_subtr_mean','');...
      fullfile(ARMASA_path,'ASA','ASAglob_mean_adj','');...
      fullfile(ARMASA_path,'ASA','ASAglob_ar_cond','');...
      fullfile(ARMASA_path,'fast','');...
      fullfile(ARMASA_path,'fast','par_convert','');...
      fullfile(ARMASA_path,'fast','sig_processing','');...
      fullfile(ARMASA_path,'fast','estimation','');...
      fullfile(ARMASA_path,'fast','estimation','estimator_tools','');...
  };

answer = 0;
while isempty(answer)
   disp(' ')
   answer = input('Do you want to prepend (0) or append (1) the ARMASA paths? 0/1 [0]:');
   if isempty(answer)
      answer = 0;
   elseif ~(isequal(answer,0) | isequal(answer,1))
      answer = [];
      disp([13 '??? Invalid user entry'])
   end
end

directory=flipud(directory);
for i=1:length(directory)
   addpath(directory{i},answer);
end

%path2rc;
% disp([13 'The ARMASA paths have successfully been added.'])
% save(fullfile(matlabroot,'ASApath'),'release','directory');
% disp(ASAerr(42));
% disp([13 'Type ''help ARMASA'' to get started.' 13])
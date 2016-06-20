function partition_files(files_in,files_out,opt)
%PARTITION_FILES partitions files into cross validation and test sets
%   PARTITION_FILES partitions files into cross validation and test sets.
%   formatted for use with PSOM pipeline
%
%   files_in (string)
%       file name of sourceanalysis file processed by ftb.BeamformerPatchTrial
%   files_out (struct)
%   files_out.train
%       file name of files selected for training set
%   files_out.test
%       file name of files selected for test set
%   opt (cell array)
%       function options specified as name value pairs
%
%       Example:
%           opt = {'train', 100, 'test', 20};
%   
%   Parameters
%   ----------
%   trials (integer, default = 100)
%       number of trials to select randomly
%   label (string)
%       label for data

p = inputParser;
p.StructExpand = false;
addRequired(p,'files_in',@(x) iscell(x) | ischar(x));
addRequired(p,'files_out',@(x) isfield(x,'train') & isfield(x,'test'));
addParameter(p,'label','',@ischar);
addParameter(p,'train',100,@isnumeric);
addParameter(p,'test',20,@isnumeric);
parse(p,files_in,files_out,opt{:});

nfiles = p.Results.train + p.Results.test;
if iscell(p.Results.files_in)
    nsets = length(p.Results.files_in);
else
    nsets = 1;
end

test_files = {};
train_files = {};

for i=1:nsets
    file_list = ftb.util.loadvar(p.Results.files_in{i});
    nfiles_in = length(file_list);
    
    if nfiles_in < nfiles
        error('not enough files');
    end
    
    % randomly select nfiles from all input files
    idx_rand = randsample(nfiles_in, nfiles);
    files_sel = files_list(idx_rand);
    
    % partition the files
    c = cvpartition(nfiles,'HoldOut',p.Results.test/nfiles);
    
    % save test and train files
    test_files = [test_files files_sel(c.test)];
    train_files = [train_files files_sel(c.train)];
    
end

save(files_out.test,'test_files');
save(files_out.train,'train_files');

end
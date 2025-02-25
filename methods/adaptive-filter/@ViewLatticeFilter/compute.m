function compute(obj,criteria)

p = inputParser();
addRequired(p,'criteria',@iscell);
parse(p,criteria);

% init criteria files
obj.init_criteria();

% loop over data files
for file_idx=1:length(obj.datafiles)
    [~,filename,~] = fileparts(obj.datafiles{file_idx});
    fprintf('computing criteria for %s\n',filename);
    % unload criteria data
    obj.unload('criteria');
    
    % check if data is fresher than criteria
    fresh = obj.check_data_freshness(file_idx);
    if ~fresh
        % criteria data is still current
        % load criteria data 
        obj.load('criteria',file_idx);
    end
    
    % flag for any new criteria that needs saving
    crit_new = false;
    
    % loop over criteria
    for k=1:length(p.Results.criteria);
        criteria = p.Results.criteria{k};
        
        % check if it exists already
        if isfield(obj.criteria,criteria)
            fprintf('already computed %s\n',criteria);
        else
            fprintf('computing %s\n',criteria);
            
            % load data
            obj.load('data',file_idx);
            
            % get dimensions
            dims = size(obj.data.estimate.ferror);
            norderp1 = dims(end);
            nsamples = dims(1);
            
            % set default orders
            order_list = 1:norderp1-1;
            norders = length(order_list);
            
            % allocate mem
            cb = zeros(norders,nsamples);
            cf = zeros(norders,nsamples);
            
            % compute criteria for each order
            order_str = cell(norders,1);
            for i=1:norders
                
                order = order_list(i);
                
                [cftemp,cbtemp] = obj.compute_criteria(criteria,order);
                if length(cftemp) > 1
                    cf(i,:) = cftemp;
                    cb(i,:) = cbtemp;
                else
                    cf(i,1) = cftemp;
                    cb(i,1) = cbtemp;
                end
                
                order_str{i} = sprintf('%d',order);
            end
            
            % check number of results
            if sum(cf(1,2:end)) == 0
                cf(:,2:end) = [];
                cb(:,2:end) = [];
            end
            
            % save to object
            obj.criteria.(criteria).f = cf;
            obj.criteria.(criteria).b = cb;
            obj.criteria.(criteria).orders = order_list;
            obj.criteria.(criteria).order_str = order_str;
            
            crit_new = true;
        end
        
    end
    
    if crit_new
        % save obj.criteria to file
        save_parfor(obj.criteriafiles{file_idx},obj.criteria);
    end
end

end
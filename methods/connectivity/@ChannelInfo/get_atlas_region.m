function regions = get_atlas_region(obj,atlas)

nlabels = length(obj.label);
regions = struct('name','','order',num2cell(zeros(nlabels,1)));
for i=1:nlabels
    switch atlas
        case 'aal'
            [regions(i).name, regions(i).order] =...
                ChannelInfo.get_atlas_region_aal(obj.label{i});
        case 'aal-coarse-13'
            [regions(i).name, regions(i).order] =...
                ChannelInfo.get_atlas_region_aal_coarse_13(obj.label{i});
        otherwise
            error('unknown atlas %s',atlas);
    end
end

end
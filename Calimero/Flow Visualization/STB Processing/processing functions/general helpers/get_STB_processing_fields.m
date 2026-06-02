function fields = get_STB_processing_fields()
%GET_STB_PROCESSING_FIELDS Field order returned by import_STB_data.

fields = {'u', 'v', 'w', 'Utot', 'vortX', 'vortY', 'vortZ', 'vortTot', 'uncU', 'uncV', 'uncW', 'uncTot', 'hel', 'numP',...
        'dudx', 'dudy', 'dudz', 'dvdx', 'dvdy', 'dvdz', 'dwdx', 'dwdy', 'dwdz', 'Utot_diff'};
end

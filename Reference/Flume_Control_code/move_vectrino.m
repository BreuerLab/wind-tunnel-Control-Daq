function move_vectrino(dist)
% dist in mm, positive to the further away; negative moving toward the user
initialize_traverse();
global sT

move_traverse(sT,dist);
fclose(sT);
end
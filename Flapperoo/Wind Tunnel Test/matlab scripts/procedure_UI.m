fig = uifigure;
fig.Position = [600 500 430 160];
movegui(fig,'center')
message = ["1. All connections fully fastened?"...
           "2. MPS Pitch motor enabled via Kollmorgen Workbench?"];
title = "Experiment Setup Reminder";
uiconfirm(fig,message,title,'CloseFcn',@(h,e) close(fig));
uiwait(fig);
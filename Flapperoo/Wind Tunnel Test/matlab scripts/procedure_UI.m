function procedure_UI()
fig = uifigure;
fig.Position = [600 500 430 160];
movegui(fig,'center')
message = ["1. All connections fully fastened?"...
           "2. Force transducer CLICKED into place?"
           "3. MPS Pitch motor enabled via Kollmorgen Workbench?"
           "4. Wings at top of upstroke?"];
title = "Experiment Setup Reminder";
uiconfirm(fig,message,title,'CloseFcn',@(h,e) close(fig));
uiwait(fig);
end
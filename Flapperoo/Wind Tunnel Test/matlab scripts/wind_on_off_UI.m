function wind_on_off_UI(state)
fig = uifigure;
fig.Position = [600 500 300 160];
movegui(fig,'center')
message = ["Turn " + state + " the wind tunnel motor."];
title = "Experiment Setup Reminder";
uiconfirm(fig,message,title,'CloseFcn',@(h,e) close(fig));
uiwait(fig);
end
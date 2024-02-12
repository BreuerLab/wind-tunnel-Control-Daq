function wind_on_off_UI(state)
    fig = uifigure;
    fig.Position = [600 500 300 160];
    movegui(fig,'center')
    disp(state == "on")
    message = ["invalid state"];
    if (state == "on")
        message = "Enable the MPS motor on Kollmorgen Workbench. When complete, press ok.";
    elseif (state == "off")
        message = "Disable the MPS motor on Kollmorgen Workbench. When complete, press ok.";
    end
    title = "Experiment Setup Reminder";
    uiconfirm(fig,message,title,'CloseFcn',@(h,e) close(fig));
    uiwait(fig);
end
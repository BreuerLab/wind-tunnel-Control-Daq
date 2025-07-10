function wind_on_off_UI(state)
    fig = uifigure;
    fig.Position = [600 500 300 160];
    movegui(fig,'center')
    disp(state == "on")
    message = ["invalid state"];
    if (state == "on")
        message = "Turn on the wind tunnel motor. When the wind speed returns to the prescribed speed, press ok.";
    elseif (state == "off")
        message = "Turn off the wind tunnel motor. When the wind speed is roughly zero, press ok.";
    end
    title = "Experiment Setup Reminder";
    uiconfirm(fig,message,title,'CloseFcn',@(h,e) close(fig));
    uiwait(fig);
end
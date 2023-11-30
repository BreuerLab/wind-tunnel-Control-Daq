function tare_complete()
    fig = uifigure;
    fig.Position = [600 500 300 160];
    movegui(fig,'center')
    message = ["Have you mounted flapperoo back on?"];
    title = "Experiment Setup Reminder";
    uiconfirm(fig,message,title,'CloseFcn',@(h,e) close(fig));
    uiwait(fig);
end
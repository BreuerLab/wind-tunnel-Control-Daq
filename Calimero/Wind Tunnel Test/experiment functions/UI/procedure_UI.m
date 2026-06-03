function procedure_UI()
    fig = uifigure;
    fig.Position = [600 500 350 160];
    movegui(fig,'center')
    message = ["All connections fully fastened?"...
               "After pressing ok, you will have 10"...
               "seconds to position the wings at midstroke."];
    title = "Experiment Setup Reminder";
    uiconfirm(fig,message,title,'CloseFcn',@(h,e) close(fig));
    uiwait(fig);
end
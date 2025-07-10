function procedure_UI()
    fig = uifigure;
    fig.Position = [600 500 440 200];
    movegui(fig,'center')
    message = ["1. All connections fully fastened?"...
               "2. Force transducer CLICKED into place?"...
               "3. Wings at midstroke?"];
    title = "Experiment Setup Reminder";
    uiconfirm(fig,message,title,'CloseFcn',@(h,e) close(fig));
    uiwait(fig);
end
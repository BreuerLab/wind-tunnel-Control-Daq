function new_ID = DAQ_select(msg)
    msg_parts = split(msg);
    Dev_IDs = msg_parts(contains(msg_parts, "'Dev"));
    Dev_IDs = string(regexp(Dev_IDs, "'([^']*)'", 'tokens'));
    new_ID = Dev_IDs(end);

    new_msg = [msg; "Switching to " + new_ID];
    disp(new_msg)

    UI_bool = false;
    if (UI_bool)
        fig = uifigure;
        fig.Position = [600 500 300 160];
        movegui(fig,'center')
        title = "Select DAQ ID";
        uiconfirm(fig,new_msg,title,'CloseFcn',@(h,e) close(fig));
        uiwait(fig);
    end
end
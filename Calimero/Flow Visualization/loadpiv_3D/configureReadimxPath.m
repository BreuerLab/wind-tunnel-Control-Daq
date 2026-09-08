function configureReadimxPath()
    if exist('readimx', 'file') == 3
        return
    end
    
    if ismac
        cd('readimx_MAC');
    elseif ispc
        cd('readimx_WIN');
    else
        error('System not identified (if using LINUX I do not know what to do).')
    end
end
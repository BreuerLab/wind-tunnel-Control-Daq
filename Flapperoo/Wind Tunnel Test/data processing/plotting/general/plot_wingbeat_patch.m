function plot_wingbeat_patch()
    xl = xlim;
    yl = ylim;
    qx = [xl(1) xl(2)/2 xl(2)/2 xl(1)];
    qy = [yl(1) yl(1) yl(2) yl(2)];
    xlim(xl);
    ylim(yl);
    h = patch(qx, qy, [0.8, 0.8, 0.8],'LineStyle','none','HandleVisibility','off');
    uistack(h,'bottom')
    set(gca, 'Layer', 'top')
    xdist = xl(2) - xl(1);
    ydist = yl(2) - yl(1);
    text(xl(1) + xdist*(1/4), yl(1) + ydist*(1/10), "Downstroke",'HorizontalAlignment','center','FontSize',14)
    text(xl(2) - xdist*(1/4), yl(1) + ydist*(1/10), "Upstroke",'HorizontalAlignment','center','FontSize',14)
end
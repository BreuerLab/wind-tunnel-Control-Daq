function plot_single_foil_data(foil)
% plots position, lift, drag and torque given data structure
if numel(fieldnames(foil)) == 5
    plot_single_foil_data(foil.foil1)
    plot_single_foil_data(foil.foil2)
    plot_single_foil_data(foil.foil3)
else

% Fig = figure;
% set(Fig,'OuterPosition',[100 100 800 1000]);


 subplot(3,1,1)
    hold off
    smooth_factor = 1;
    y= smooth(foil.drag_N(:,1),smooth_factor);
    plot1 = plot(foil.t_sec,y,'r-');
    hold on
%     plot(foil.t_sec,lowlow_pass_filtfilt(y),'k-','LineWidth',2)
    
    y= smooth(foil.lift_N(:,1),smooth_factor);
    % y= smooth(Drag,300);
    plot2 = plot(foil.t_sec,y,'b-');
% plot(foil.t_sec,lowlow_pass_filtfilt(y),'k-','LineWidth',2)
    % y= smooth(out(1:end,5),smooth_factor);
    % plot(t(1000:end),y(1000:end))


    % plot(t,smooth(out(:,ii),300))
    xlabel('Time (s)')
    ylabel('Force (N)')
    legend([plot1 plot2],'Drag', 'Lift')
    title(['eff = ',num2str(foil.eta_mean),', eff std = ',num2str(foil.eta_std)])
    set(gca,'XTick',[foil.t_sec(foil.Cycle_start_inds)])
    grid
%     ylim([-35 35])
%         for ii = 2:numel(foil.Cycle_start_inds)
%         plot([foil.t_sec(foil.Cycle_start_inds(ii)),foil.t_sec(foil.Cycle_start_inds(ii))],[-100 100],'k--','LineWidth',.5)
%     end
%     ylim([-3 3])

    

    hold off
subplot(3,1,2)
    % figure(2)
    hold off


    % for ii = 6:8
    y= smooth(foil.torque_Nm(1:end,1),smooth_factor);
    % y= smooth(Torque(1:end),600);
    plot(foil.t_sec,y,'g-')
hold on
plot(foil.t_sec,low_pass_filtfilt(y),'k-','LineWidth',2)
    % hold on
    % plot(t,smooth(out(:,ii),300))
    % end
    set(gca,'XTick',[foil.t_sec(foil.Cycle_start_inds)])
    grid
    xlabel('Time (s)');
    ylabel('Torque (Nm)')
    % legend('X','Y','Z')
%     for ii = 2:numel(foil.Cycle_start_inds)
%         plot([foil.t_sec(foil.Cycle_start_inds(ii)),foil.t_sec(foil.Cycle_start_inds(ii))],[-100 100],'k--','LineWidth',.5)
%     end
%     ylim([-.3 .3])
    hold off
    
subplot(3,1,3)
    % figure(3)
    [P,h1,h2] = plotyy(foil.t_sec,foil.heave_pos,foil.t_sec,foil.pitch_pos*180/pi);
    xlabel('Time (s)');
    ylabel(P(1),'Heave Position (m)')
    ylabel(P(2),'Pitch Position (degrees)')
    set(P(1),'XTick',[],'ylim',[0,3],'YTick',[0:.5:3])
    set(P(1),'XTick',[foil.t_sec(foil.Cycle_start_inds)],'XMinorTick','on')
    set(P(2),'ylim',[-90, 90],'YTick',[-90:30:90])
    grid
end
end

%     hold on
%     for ii = 2:numel(foil.Cycle_start_inds)
%         plot([foil.t(foil.Cycle_start_inds(ii)),foil.t(foil.Cycle_start_inds(ii))],[-100 100],'k--','LineWidth',.5)
%     end
    
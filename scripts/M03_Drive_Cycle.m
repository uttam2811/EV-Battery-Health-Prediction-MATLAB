%% ============================================================
%  MODULE 03 — DRIVE CYCLE SIMULATION (UDDS)
%  Project : Smart EV Battery Health & Fault Prediction System
%  Author  : [Your Name] | Tool: MATLAB 2025a
%  Requires: normal_condition.mat
%% ============================================================
clc; clear; close all;

output_folder = 'EV_Battery_Outputs';
if ~exist(output_folder,'dir'), mkdir(output_folder); end

fprintf('==========================================\n');
fprintf('   MODULE 03: DRIVE CYCLE SIMULATION      \n');
fprintf('==========================================\n\n');

load('normal_condition.mat');
t=t_normal; V=V_normal; I=I_normal;
Q_pack=20; % Ah (4P x 5Ah)

t_dc=0:1:3600;
speed_wp=[0,0,5,10,20,35,40,35,20,10,0,0,15,30,...
          45,50,45,30,15,0,0,10,25,40,50,55,50,...
          40,25,10,0,0,20,40,50,40,20,0,0,30,50,...
          60,50,30,0,0,10,20,30,20,10,0];
t_wp=linspace(0,1369,length(speed_wp));
spd_1369=max(interp1(t_wp,speed_wp,0:1:1369,'pchip'),0);
speed_full=repmat(spd_1369,1,3); speed_full=speed_full(1:3601);

accel=gradient(speed_full);
I_drive=0.3+(speed_full/100)*0.6+max(accel,0)*0.05;
I_regen=min(accel,0)*0.03;
I_net=max(I_drive+I_regen,0.05);

V_drive=V-(I_net'-mean(I))*0.05;
V_drive=max(V_drive,3.5);

SOC_dc=zeros(3601,1); SOC_dc(1)=1.0;
for k=2:3601
    SOC_dc(k)=max(SOC_dc(k-1)-(abs(I_net(k))*1)/(Q_pack*3600),0);
end

E_consumed=trapz(t_dc,max(I_net,0))/3600;
E_regen_Ah=trapz(t_dc,abs(min(I_net,0)))/3600;

fprintf('Peak speed      : %.1f km/h\n', max(speed_full));
fprintf('Average speed   : %.1f km/h\n', mean(speed_full));
fprintf('Peak current    : %.4f A\n', max(I_net));
fprintf('Energy consumed : %.4f Ah\n', E_consumed);
fprintf('Regen recovered : %.4f Ah\n', E_regen_Ah);
fprintf('Final SOC       : %.2f%%\n\n', SOC_dc(end)*100);

figure('Name','M03: Drive Cycle Analysis',...
    'Color','white','Position',[50 50 1200 650]);

subplot(2,3,1);
plot(t_dc,speed_full,'b-','LineWidth',1.5);
xlabel('Time (s)'); ylabel('Speed (km/h)');
title('UDDS Drive Cycle Speed Profile'); grid on; set(gca,'FontSize',10);

subplot(2,3,2);
plot(t_dc,I_net,'r-','LineWidth',1.2); hold on;
yline(0,'k-','LineWidth',1);
fill([t_dc,fliplr(t_dc)],[max(I_net,0),zeros(1,3601)],...
    'red','FaceAlpha',0.2,'EdgeColor','none');
fill([t_dc,fliplr(t_dc)],[min(I_net,0),zeros(1,3601)],...
    'green','FaceAlpha',0.3,'EdgeColor','none');
xlabel('Time (s)'); ylabel('Current (A)');
title('Current + Regenerative Braking');
legend('Current','','Discharge','Regen'); grid on; set(gca,'FontSize',10);

subplot(2,3,3);
plot(t_dc,V_drive,'b-','LineWidth',1.5);
xlabel('Time (s)'); ylabel('Voltage (V)');
title('Pack Voltage under Drive Cycle'); grid on; set(gca,'FontSize',10);

subplot(2,3,4);
plot(t_dc,SOC_dc*100,'g-','LineWidth',1.5);
yline(20,'r--','Low SOC','LineWidth',1.5);
xlabel('Time (s)'); ylabel('SOC (%)');
title('SOC under Drive Cycle'); grid on; set(gca,'FontSize',10);

subplot(2,3,5);
P_drive=V_drive.*I_net';
plot(t_dc,P_drive,'m-','LineWidth',1.2);
yline(0,'k-'); xlabel('Time (s)'); ylabel('Power (W)');
title('Power Profile (+discharge/-regen)'); grid on; set(gca,'FontSize',10);

subplot(2,3,6);
E_cum=cumtrapz(t_dc,max(I_net,0))/3600;
E_reg=cumtrapz(t_dc,abs(min(I_net,0)))/3600;
plot(t_dc,E_cum,'r-','LineWidth',1.5,'DisplayName','Consumed'); hold on;
plot(t_dc,E_reg,'g-','LineWidth',1.5,'DisplayName','Recovered');
xlabel('Time (s)'); ylabel('Energy (Ah)');
title('Cumulative Energy: Consumed vs Recovered');
legend('Location','northwest'); grid on; set(gca,'FontSize',10);

saveas(gcf,fullfile(output_folder,'M03_Drive_Cycle.png'));
save(fullfile(output_folder,'drive_cycle_data.mat'),...
    't_dc','speed_full','I_net','V_drive','SOC_dc');
fprintf('✔ Saved: M03_Drive_Cycle.png\n');
fprintf('✔ Saved: drive_cycle_data.mat\n');
fprintf('MODULE 03 COMPLETE!\n');

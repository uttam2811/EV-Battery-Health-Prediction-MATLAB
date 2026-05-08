%% ============================================================
%  MODULE 02 — NORMAL SIMULATION DATA
%  Project : Smart EV Battery Health & Fault Prediction System
%  Author  : [Your Name] | Tool: MATLAB 2025a
%  Requires: normal_condition.mat (from Simulink simulation)
%% ============================================================
clc; clear; close all;

output_folder = 'EV_Battery_Outputs';
if ~exist(output_folder,'dir'), mkdir(output_folder); end

fprintf('==========================================\n');
fprintf('   MODULE 02: NORMAL SIMULATION DATA      \n');
fprintf('==========================================\n\n');

if ~exist('normal_condition.mat','file')
    error('normal_condition.mat not found! Run Simulink first.');
end
load('normal_condition.mat');
t=t_normal; V=V_normal; I=I_normal; SOC=SOC_normal;

fprintf('Duration       : %.0f seconds\n', t(end));
fprintf('Data points    : %d\n', length(t));
fprintf('Initial Voltage: %.4f V\n', V(1));
fprintf('Final Voltage  : %.4f V\n', V(end));
fprintf('Voltage Drop   : %.4f V\n', V(1)-V(end));
fprintf('Initial SOC    : %.2f%%\n', SOC(1)*100);
fprintf('Final SOC      : %.2f%%\n', SOC(end)*100);
fprintf('SOC Consumed   : %.2f%%\n', (SOC(1)-SOC(end))*100);
fprintf('Avg Current    : %.4f A\n\n', mean(abs(I)));

figure('Name','M02: Normal Condition Dashboard',...
    'Color','white','Position',[50 50 1200 600]);

subplot(2,2,1);
plot(t,V,'b-','LineWidth',2);
xlabel('Time (s)'); ylabel('Voltage (V)');
title('Pack Terminal Voltage - Normal');
grid on; set(gca,'FontSize',11);

subplot(2,2,2);
plot(t,abs(I),'r-','LineWidth',2);
xlabel('Time (s)'); ylabel('Current (A)');
title('Discharge Current - Normal');
grid on; set(gca,'FontSize',11);

subplot(2,2,3);
plot(t,SOC*100,'g-','LineWidth',2);
yline(20,'r--','Low SOC Warning (20%)','LineWidth',1.5);
xlabel('Time (s)'); ylabel('SOC (%)');
title('State of Charge - Adaptive Kalman Filter');
grid on; set(gca,'FontSize',11);

subplot(2,2,4);
remaining=SOC(end)*100; consumed=(SOC(1)-SOC(end))*100;
b=bar([remaining,consumed],'FaceColor','flat');
b.CData=[0.2 0.7 0.3;0.9 0.2 0.2];
set(gca,'XTickLabel',{'Remaining SOC','Consumed SOC'});
ylabel('%'); title('SOC Summary after 1 Hour');
grid on; set(gca,'FontSize',11);

saveas(gcf,fullfile(output_folder,'M02_Normal_Simulation.png'));
fprintf('✔ Saved: M02_Normal_Simulation.png\n');
fprintf('MODULE 02 COMPLETE!\n');

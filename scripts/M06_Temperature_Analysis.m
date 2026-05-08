%% ============================================================
%  MODULE 06 — TEMPERATURE ANALYSIS
%  Project : Smart EV Battery Health & Fault Prediction System
%  Author  : [Your Name] | Tool: MATLAB 2025a
%  Requires: normal_condition.mat
%% ============================================================
clc; clear; close all;

output_folder = 'EV_Battery_Outputs';
if ~exist(output_folder,'dir'), mkdir(output_folder); end

fprintf('==========================================\n');
fprintf('   MODULE 06: TEMPERATURE ANALYSIS        \n');
fprintf('==========================================\n\n');

load('normal_condition.mat');
t=t_normal; V=V_normal;

T_vals  = [-40,-20,0,25,40,60];
T_lab   = {'-40C','-20C','0C','25C','40C','60C'};
cap_ret = [0.55,0.72,0.88,1.00,0.97,0.91];
R_fac   = [3.2,2.1,1.4,1.0,1.05,1.15];

fprintf('Temperature Performance Summary:\n');
fprintf('%-8s %-15s %-15s\n','Temp(C)','Capacity(%)','R_Factor');
fprintf('%s\n',repmat('-',1,40));
for i=1:length(T_vals)
    fprintf('%-8d %-15.1f %-15.2f\n',...
        T_vals(i),cap_ret(i)*100,R_fac(i));
end

% Optimal temperature check
[~,opt_idx]=max(cap_ret);
fprintf('\nOptimal temperature: %dC\n', T_vals(opt_idx));
fprintf('Worst temperature  : %dC\n\n', T_vals(1));

figure('Name','M06: Temperature Analysis',...
    'Color','white','Position',[50 50 1200 600]);

subplot(2,2,1);
clrs=lines(6);
for i=1:6
    V_temp=V*cap_ret(i)-0.005*R_fac(i);
    plot(t,V_temp,'LineWidth',1.8,...
        'DisplayName',T_lab{i},'Color',clrs(i,:)); hold on;
end
xlabel('Time (s)'); ylabel('Voltage (V)');
title('Discharge Voltage at Different Temperatures');
legend('Location','southwest'); grid on; set(gca,'FontSize',9);

subplot(2,2,2);
b1=bar(categorical(T_lab),cap_ret*100,'FaceColor','flat');
b1.CData=jet(6);
ylabel('Capacity (%)'); title('Capacity Retention vs Temperature');
grid on; set(gca,'FontSize',10);

subplot(2,2,3);
b2=bar(categorical(T_lab),R_fac,'FaceColor','flat');
b2.CData=hot(6);
ylabel('Resistance Factor'); title('Internal Resistance vs Temperature');
grid on; set(gca,'FontSize',10);

subplot(2,2,4);
T_cont=-40:1:80;
cap_cont=100*(1-0.003*(T_cont-25).^2/100);
cap_cont=min(cap_cont,100);
plot(T_cont,cap_cont,'b-','LineWidth',2.5);
xline(25,'g--','Optimal 25C','LineWidth',1.5);
xline(-10,'r--','Min Recommended','LineWidth',1.5);
xline(45,'r--','Max Recommended','LineWidth',1.5);
fill([-10,25,25,-10],[70,70,102,102],...
    'green','FaceAlpha',0.08,'EdgeColor','none');
xlabel('Temperature (C)'); ylabel('Capacity (%)');
title('Operating Temperature Envelope');
grid on; set(gca,'FontSize',10);

saveas(gcf,fullfile(output_folder,'M06_Temperature_Analysis.png'));
fprintf('✔ Saved: M06_Temperature_Analysis.png\n');
fprintf('MODULE 06 COMPLETE!\n');

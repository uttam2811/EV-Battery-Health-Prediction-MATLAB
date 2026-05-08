%% ============================================================
%  MODULE 04 — FAULT INJECTION & DETECTION
%  Project : Smart EV Battery Health & Fault Prediction System
%  Author  : [Your Name] | Tool: MATLAB 2025a
%  Requires: normal_condition.mat
%% ============================================================
clc; clear; close all;

output_folder = 'EV_Battery_Outputs';
if ~exist(output_folder,'dir'), mkdir(output_folder); end

fprintf('==========================================\n');
fprintf('   MODULE 04: FAULT INJECTION & DETECTION \n');
fprintf('==========================================\n\n');

load('normal_condition.mat');
t=t_normal; V=V_normal; I=I_normal; SOC=SOC_normal;

%% --- INJECT 3 FAULT TYPES ---
% Fault 1: Voltage drop at t=1800s (cell short circuit)
V_fault=V; V_fault(t>=1800)=V_fault(t>=1800)-0.15;

% Fault 2: Overcurrent at t=2200-2400s (sudden acceleration)
I_fault=I; I_fault(t>=2200&t<=2400)=I_fault(t>=2200&t<=2400)*3.5;

% Fault 3: SOC drop at t=2500s (sensor fault)
SOC_fault=SOC; SOC_fault(t>=2500)=SOC_fault(t>=2500)-0.08;

%% --- FAULT DETECTION ---
V_min_th=3.90; I_max_th=1.5; SOC_min_th=0.20;
flag_V=V_fault<V_min_th;
flag_I=I_fault>I_max_th;
flag_SOC=SOC_fault<SOC_min_th;

fprintf('--- Fault Detection ---\n');
if any(flag_V)
    fprintf('VOLTAGE FAULT    : t=%.0fs | V=%.4fV\n',...
        t(find(flag_V,1)),V_fault(find(flag_V,1)));
else
    fprintf('Voltage          : NORMAL throughout\n');
end
if any(flag_I)
    fprintf('OVERCURRENT FAULT: t=%.0fs | I=%.4fA\n',...
        t(find(flag_I,1)),max(I_fault));
else
    fprintf('Current          : NORMAL throughout\n');
end
if any(flag_SOC)
    fprintf('SOC FAULT        : t=%.0fs\n',t(find(flag_SOC,1)));
else
    fprintf('SOC              : NORMAL throughout\n');
end

%% --- SOH ---
V_mx=4.2; V_mn=3.0;
SOH_n=(mean(V)-V_mn)/(V_mx-V_mn)*100;
SOH_f=(mean(V_fault)-V_mn)/(V_mx-V_mn)*100;
SOH_drop=SOH_n-SOH_f;
RUL_hours=max(0,(SOH_f-80)/SOH_drop);

fprintf('\n--- State of Health ---\n');
fprintf('SOH Normal   : %.2f%%\n', SOH_n);
fprintf('SOH Fault    : %.2f%%\n', SOH_f);
fprintf('SOH Drop     : %.2f%%\n', SOH_drop);
fprintf('RUL          : %.1f hours\n', RUL_hours);

fprintf('\n--- Smart Alert ---\n');
if SOH_f>=90, fprintf('Status: HEALTHY\n\n');
elseif SOH_f>=80, fprintf('Status: MODERATE — Schedule maintenance\n\n');
elseif SOH_f>=60, fprintf('Status: LOW — Plan replacement\n\n');
else, fprintf('Status: CRITICAL — Replace immediately\n\n'); end

%% --- PLOT ---
figure('Name','M04: Fault Detection Dashboard',...
    'Color','white','Position',[50 50 1200 700]);

subplot(2,3,1);
plot(t,V,'b-','LineWidth',2,'DisplayName','Normal'); hold on;
plot(t,V_fault,'r--','LineWidth',2,'DisplayName','Fault');
xline(1800,'k:','Fault Start','LineWidth',1.5);
xlabel('Time (s)'); ylabel('Voltage (V)');
title('Voltage: Normal vs Fault');
legend('Location','southwest'); grid on; set(gca,'FontSize',10);

subplot(2,3,2);
plot(t,I,'b-','LineWidth',2,'DisplayName','Normal'); hold on;
plot(t,I_fault,'r--','LineWidth',2,'DisplayName','Fault');
xline(2200,'k:','Fault Start','LineWidth',1.5);
xlabel('Time (s)'); ylabel('Current (A)');
title('Current: Normal vs Fault');
legend('Location','northeast'); grid on; set(gca,'FontSize',10);

subplot(2,3,3);
plot(t,SOC*100,'b-','LineWidth',2,'DisplayName','Normal'); hold on;
plot(t,SOC_fault*100,'r--','LineWidth',2,'DisplayName','Fault');
yline(20,'k:','Min Safe','LineWidth',1.5);
xline(2500,'k:','Fault Start','LineWidth',1.5);
xlabel('Time (s)'); ylabel('SOC (%)');
title('SOC: Normal vs Fault');
legend('Location','southwest'); grid on; set(gca,'FontSize',10);

subplot(2,3,4);
area(t,double(flag_V)*100,'FaceColor','red','FaceAlpha',0.5); hold on;
area(t,double(flag_I)*80,'FaceColor',[1 0.5 0],'FaceAlpha',0.5);
area(t,double(flag_SOC)*60,'FaceColor','yellow','FaceAlpha',0.5);
xlabel('Time (s)'); ylabel('Fault Active');
title('Fault Detection Timeline');
legend('Voltage Fault','Current Fault','SOC Fault');
grid on; set(gca,'FontSize',10);

subplot(2,3,5);
b=bar([SOH_n,SOH_f],'FaceColor','flat');
b.CData=[0.2 0.7 0.3;0.9 0.2 0.2];
yline(80,'k--','EOL Threshold (80%)','LineWidth',2);
set(gca,'XTickLabel',{'Normal SOH','Fault SOH'});
ylabel('SOH (%)'); title('State of Health Comparison');
ylim([0 110]); grid on; set(gca,'FontSize',10);

subplot(2,3,6);
soh_r=100:-0.1:79;
rul_c=max(0,(soh_r-80)/SOH_drop);
plot(soh_r,rul_c,'b-','LineWidth',2);
xline(SOH_f,'r--',sprintf('Current=%.1f%%',SOH_f),'LineWidth',1.5);
xlabel('SOH (%)'); ylabel('Remaining Hours');
title('Remaining Useful Life Prediction'); grid on; set(gca,'FontSize',10);

saveas(gcf,fullfile(output_folder,'M04_Fault_Detection.png'));

%% --- EXPORT CSV ---
T_csv=table(t,V,V_fault,I,I_fault,SOC*100,SOC_fault*100,...
    double(flag_V),double(flag_I),double(flag_SOC),...
    'VariableNames',{'Time_s','V_Normal','V_Fault',...
    'I_Normal','I_Fault','SOC_Normal_pct','SOC_Fault_pct',...
    'Flag_Voltage','Flag_Current','Flag_SOC'});
writetable(T_csv,fullfile(output_folder,'M04_Fault_Report.csv'));

fprintf('✔ Saved: M04_Fault_Detection.png\n');
fprintf('✔ Saved: M04_Fault_Report.csv\n');
fprintf('MODULE 04 COMPLETE!\n');

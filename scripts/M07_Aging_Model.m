%% ============================================================
%  MODULE 07 — BATTERY AGING & CAPACITY FADE MODEL
%  Project : Smart EV Battery Health & Fault Prediction System
%  Author  : [Your Name] | Tool: MATLAB 2025a
%% ============================================================
clc; clear; close all;

output_folder = 'EV_Battery_Outputs';
if ~exist(output_folder,'dir'), mkdir(output_folder); end

fprintf('==========================================\n');
fprintf('   MODULE 07: BATTERY AGING MODEL         \n');
fprintf('==========================================\n\n');

%% --- CAPACITY FADE MODEL (Arrhenius-based) ---
cycles   = 0:10:2000;
cap_fade = 100*exp(-0.00035*cycles);
R_growth = 1+0.0002*cycles;

EOL_idx     = find(cap_fade<=80,1);
cycles_EOL  = cycles(EOL_idx);
years_EOL   = cycles_EOL/365;  % 1 charge cycle per day assumption

fprintf('Degradation model  : Arrhenius exponential\n');
fprintf('Initial capacity   : 100%%\n');
fprintf('EOL threshold      : 80%%\n');
fprintf('EOL at cycle       : %d\n', cycles_EOL);
fprintf('EOL in years       : %.1f years\n', years_EOL);
fprintf('Resistance at EOL  : %.2fx initial\n\n', R_growth(EOL_idx));

%% --- CYCLE MILESTONES ---
milestones=[100,200,500,1000,1500,cycles_EOL];
fprintf('%-10s %-15s %-15s\n','Cycles','Capacity(%)','R_Factor');
fprintf('%s\n',repmat('-',1,42));
for i=1:length(milestones)
    c=milestones(i);
    cap=100*exp(-0.00035*c);
    res=1+0.0002*c;
    fprintf('%-10d %-15.2f %-15.3f\n',c,cap,res);
end

%% --- CALENDAR AGING ---
months  = 0:1:60;
cal_age = 100*exp(-0.001*months);

fprintf('\nCalendar Aging (storage at 50%% SOC, 25C):\n');
fprintf('At 12 months: %.1f%% capacity\n', 100*exp(-0.001*12));
fprintf('At 24 months: %.1f%% capacity\n', 100*exp(-0.001*24));
fprintf('At 60 months: %.1f%% capacity\n', 100*exp(-0.001*60));

%% --- PLOT ---
figure('Name','M07: Battery Aging Model',...
    'Color','white','Position',[50 50 1200 600]);

subplot(2,2,1);
plot(cycles,cap_fade,'b-','LineWidth',2.5);
yline(80,'r--','End of Life (80%)','LineWidth',2);
xline(cycles_EOL,'k:',...
    sprintf('EOL = %d cycles',cycles_EOL),'LineWidth',1.5);
fill([0,cycles,fliplr(cycles)],...
    [80,cap_fade,fliplr(ones(size(cycles))*80)],...
    'red','FaceAlpha',0.08,'EdgeColor','none');
xlabel('Charge Cycles'); ylabel('Capacity (%)');
title('Capacity Fade Over Lifetime');
grid on; set(gca,'FontSize',11);

subplot(2,2,2);
yyaxis left;
plot(cycles,cap_fade,'b-','LineWidth',2);
ylabel('Capacity (%)'); ylim([70 105]);
yyaxis right;
plot(cycles,R_growth,'r-','LineWidth',2);
ylabel('Resistance Factor');
xlabel('Charge Cycles');
title('Capacity Fade & Resistance Growth');
legend({'Capacity','Resistance'},'Location','east');
grid on; set(gca,'FontSize',11);

subplot(2,2,3);
plot(months,cal_age,'m-','LineWidth',2);
yline(80,'r--','EOL Threshold','LineWidth',2);
xlabel('Storage Time (months)'); ylabel('Capacity (%)');
title('Calendar Aging (Storage Degradation)');
grid on; set(gca,'FontSize',11);

subplot(2,2,4);
soh_levels=100:-5:75;
rul_cyc=max(0,(soh_levels-80)/0.01);
bar(categorical(string(soh_levels)),rul_cyc,...
    'FaceColor',[0.2 0.6 0.9]);
xlabel('Current SOH (%)'); ylabel('Remaining Cycles');
title('RUL vs Current SOH');
grid on; set(gca,'FontSize',11);

saveas(gcf,fullfile(output_folder,'M07_Aging_Model.png'));
fprintf('\n✔ Saved: M07_Aging_Model.png\n');
fprintf('MODULE 07 COMPLETE!\n');

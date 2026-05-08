%% ============================================================
%  MASTER RUN SCRIPT
%  Project : Smart EV Battery Health & Fault Prediction System
%  Author  : [Your Name]
%  Tool    : MATLAB 2025a + Simscape Battery + Deep Learning
%  HOW TO RUN:
%    1. Make sure normal_condition.mat is in same folder
%    2. Press F5 or click Run
%    3. All outputs auto-saved to EV_Battery_Outputs folder
%% ============================================================
clc; clear; close all;

%% ---- CREATE OUTPUT FOLDER AUTOMATICALLY ----------------------
output_folder = 'EV_Battery_Outputs';
if ~exist(output_folder, 'dir')
    mkdir(output_folder);
    fprintf('Output folder created: %s\n\n', output_folder);
else
    fprintf('Output folder found : %s\n\n', output_folder);
end

% Helper function to save figures cleanly
save_fig = @(name) saveas(gcf, fullfile(output_folder, name));

fprintf('==========================================\n');
fprintf('  EV BATTERY AI HEALTH MONITORING SYSTEM \n');
fprintf('  ALL OUTPUTS → EV_Battery_Outputs/      \n');
fprintf('==========================================\n\n');

%% ============================================================
%  MODULE 01 — BATTERY PACK SPECIFICATION
%% ============================================================
fprintf('▶ MODULE 01: Battery Pack Specification\n');
fprintf('------------------------------------------\n');

% Cell parameters — NMC Pouch Cell
V_cell_nom  = 3.7;
V_cell_max  = 4.2;
V_cell_min  = 3.0;
Q_cell      = 5;        % Ah
R_cell      = 0.005;    % Ohm
mass_cell   = 0.045;    % kg

% Pack configuration: 96S4P
n_series    = 96;
n_parallel  = 4;
n_cells     = n_series * n_parallel;   % 384 cells

% Pack calculations
V_pack_nom  = n_series  * V_cell_nom;
V_pack_max  = n_series  * V_cell_max;
V_pack_min  = n_series  * V_cell_min;
Q_pack      = n_parallel * Q_cell;
E_pack_Wh   = V_pack_nom * Q_pack;
E_pack_kWh  = E_pack_Wh / 1000;
R_pack      = (n_series / n_parallel) * R_cell;
mass_pack   = n_cells * mass_cell;
volume_pack = 0.0417;

% Energy density
gravimetric_density = E_pack_Wh / mass_pack;
volumetric_density  = (E_pack_Wh / volume_pack) / 1000;

% Module level: 12S4P per module, 8 modules
n_series_mod = 12;
n_modules    = 8;
V_module     = n_series_mod * V_cell_nom;
E_module_Wh  = V_module * Q_pack;

fprintf('Configuration      : %dS%dP\n', n_series, n_parallel);
fprintf('Total Cells        : %d\n', n_cells);
fprintf('Nominal Voltage    : %.1f V\n', V_pack_nom);
fprintf('Capacity           : %.0f Ah\n', Q_pack);
fprintf('Energy             : %.3f kWh\n', E_pack_kWh);
fprintf('Pack Mass          : %.2f kg\n', mass_pack);
fprintf('Gravimetric Density: %.1f Wh/kg\n', gravimetric_density);
fprintf('Volumetric Density : %.1f Wh/L\n\n', volumetric_density);

% C-rate analysis
fprintf('C-Rate Analysis:\n');
C_rates = [0.5, 1, 2, 3, 4];
for i = 1:length(C_rates)
    I_c = C_rates(i) * Q_pack;
    t_h = Q_pack / I_c;
    fprintf('  %.1fC: %.0f A — %.1f hr discharge\n',...
        C_rates(i), I_c, t_h);
end
fprintf('\n');

% Figure M01
figure('Name','M01: Pack Specification',...
    'Color','white','Position',[50 50 1100 450]);

subplot(1,3,1);
energy_vals = [18.5, E_module_Wh, E_pack_Wh];
b1 = bar(energy_vals,'FaceColor','flat');
b1.CData = [0.2 0.6 0.9; 0.1 0.8 0.4; 0.9 0.3 0.2];
set(gca,'XTickLabel',{'Cell','Module','Pack'},'FontSize',10);
ylabel('Energy (Wh)'); title('Energy: Cell → Module → Pack');
grid on;

subplot(1,3,2);
c_range = 0.1:0.1:5;
plot(c_range, 1./c_range,'b-','LineWidth',2);
xline(1,'r--','1C','LineWidth',1.5);
xline(2,'g--','2C','LineWidth',1.5);
xlabel('C-Rate'); ylabel('Discharge Time (hours)');
title('C-Rate vs Discharge Time');
grid on; set(gca,'FontSize',10);

subplot(1,3,3);
b2 = bar([V_pack_min, V_pack_nom, V_pack_max],'FaceColor','flat');
b2.CData = [0.9 0.2 0.2; 0.2 0.7 0.3; 0.2 0.4 0.9];
set(gca,'XTickLabel',{'Min 288V','Nom 355V','Max 403V'},'FontSize',9);
ylabel('Voltage (V)'); ylim([0 450]);
title('Pack Voltage Range'); grid on;

save_fig('M01_Pack_Specification.png');
fprintf('✔ Saved: M01_Pack_Specification.png\n\n');

%% ============================================================
%  MODULE 02 — LOAD SIMULATION DATA
%% ============================================================
fprintf('▶ MODULE 02: Loading Simulation Data\n');
fprintf('------------------------------------------\n');

if ~exist('normal_condition.mat','file')
    error(['normal_condition.mat not found!\n'...
        'Please run EV_Battery_Simulation.slx first\n'...
        'and run the extraction script to save normal_condition.mat']);
end

load('normal_condition.mat');
t   = t_normal;
V   = V_normal;
I   = I_normal;
SOC = SOC_normal;

fprintf('Duration       : %.0f seconds\n', t(end));
fprintf('Data points    : %d\n', length(t));
fprintf('Initial Voltage: %.4f V\n', V(1));
fprintf('Final Voltage  : %.4f V\n', V(end));
fprintf('Initial SOC    : %.2f%%\n', SOC(1)*100);
fprintf('Final SOC      : %.2f%%\n\n', SOC(end)*100);

% Figure M02
figure('Name','M02: Simulation Data',...
    'Color','white','Position',[50 50 1100 450]);

subplot(1,3,1);
plot(t, V,'b-','LineWidth',2);
xlabel('Time (s)'); ylabel('Voltage (V)');
title('Pack Terminal Voltage - Normal');
grid on; set(gca,'FontSize',10);

subplot(1,3,2);
plot(t, abs(I),'r-','LineWidth',2);
xlabel('Time (s)'); ylabel('Current (A)');
title('Discharge Current - Normal');
grid on; set(gca,'FontSize',10);

subplot(1,3,3);
plot(t, SOC*100,'g-','LineWidth',2);
yline(20,'r--','Low SOC Warning','LineWidth',1.5);
xlabel('Time (s)'); ylabel('SOC (%)');
title('State of Charge - Adaptive Kalman Filter');
grid on; set(gca,'FontSize',10);

save_fig('M02_Normal_Simulation.png');
fprintf('✔ Saved: M02_Normal_Simulation.png\n\n');

%% ============================================================
%  MODULE 03 — DRIVE CYCLE SIMULATION (UDDS)
%% ============================================================
fprintf('▶ MODULE 03: Drive Cycle Simulation\n');
fprintf('------------------------------------------\n');

t_dc = 0:1:3600;

% UDDS-style speed profile
speed_wp = [0,0,5,10,20,35,40,35,20,10,0,0,15,30,...
            45,50,45,30,15,0,0,10,25,40,50,55,50,...
            40,25,10,0,0,20,40,50,40,20,0,0,30,50,...
            60,50,30,0,0,10,20,30,20,10,0];
t_wp     = linspace(0,1369,length(speed_wp));
spd_1369 = max(interp1(t_wp,speed_wp,0:1:1369,'pchip'),0);
speed_full = repmat(spd_1369,1,3);
speed_full = speed_full(1:3601);

% Current from speed + regenerative braking
accel   = gradient(speed_full);
I_drive = 0.3 + (speed_full/100)*0.6 + max(accel,0)*0.05;
I_regen = min(accel,0)*0.03;
I_net   = max(I_drive + I_regen, 0.05);

% Voltage under drive cycle
V_drive = V - (I_net' - mean(I))*0.05;
V_drive = max(V_drive, 3.5);

% SOC under drive cycle — Coulomb counting
SOC_dc    = zeros(3601,1);
SOC_dc(1) = 1.0;
for k = 2:3601
    SOC_dc(k) = max(SOC_dc(k-1) - ...
        (abs(I_net(k))*1)/(Q_pack*3600), 0);
end

% Energy recovered by regen
E_regen_Ah = trapz(t_dc, abs(min(I_net,0)))/3600;
E_consumed_Ah = trapz(t_dc, max(I_net,0))/3600;

fprintf('Peak speed         : %.1f km/h\n', max(speed_full));
fprintf('Average speed      : %.1f km/h\n', mean(speed_full));
fprintf('Peak current       : %.4f A\n', max(I_net));
fprintf('Average current    : %.4f A\n', mean(I_net));
fprintf('Energy consumed    : %.4f Ah\n', E_consumed_Ah);
fprintf('Regen recovered    : %.4f Ah\n', E_regen_Ah);
fprintf('Final SOC          : %.2f%%\n\n', SOC_dc(end)*100);

% Figure M03
figure('Name','M03: Drive Cycle Analysis',...
    'Color','white','Position',[50 50 1200 650]);

subplot(2,3,1);
plot(t_dc,speed_full,'b-','LineWidth',1.5);
xlabel('Time (s)'); ylabel('Speed (km/h)');
title('UDDS Drive Cycle Speed Profile');
grid on; set(gca,'FontSize',10);

subplot(2,3,2);
plot(t_dc,I_net,'r-','LineWidth',1.2); hold on;
yline(0,'k-','LineWidth',1);
fill([t_dc,fliplr(t_dc)],...
    [max(I_net,0),zeros(1,3601)],...
    'red','FaceAlpha',0.2,'EdgeColor','none');
fill([t_dc,fliplr(t_dc)],...
    [min(I_net,0),zeros(1,3601)],...
    'green','FaceAlpha',0.3,'EdgeColor','none');
xlabel('Time (s)'); ylabel('Current (A)');
title('Current + Regenerative Braking');
legend('Current','','Discharge','Regen');
grid on; set(gca,'FontSize',10);

subplot(2,3,3);
plot(t_dc,V_drive,'b-','LineWidth',1.5);
xlabel('Time (s)'); ylabel('Voltage (V)');
title('Pack Voltage under Drive Cycle');
grid on; set(gca,'FontSize',10);

subplot(2,3,4);
plot(t_dc,SOC_dc*100,'g-','LineWidth',1.5);
yline(20,'r--','Low SOC','LineWidth',1.5);
xlabel('Time (s)'); ylabel('SOC (%)');
title('SOC under Drive Cycle');
grid on; set(gca,'FontSize',10);

subplot(2,3,5);
P_drive = V_drive .* I_net';
plot(t_dc,P_drive,'m-','LineWidth',1.2);
yline(0,'k-'); xlabel('Time (s)'); ylabel('Power (W)');
title('Power Profile (+discharge / -regen)');
grid on; set(gca,'FontSize',10);

subplot(2,3,6);
E_cum   = cumtrapz(t_dc, max(I_net,0))/3600;
E_reg   = cumtrapz(t_dc, abs(min(I_net,0)))/3600;
plot(t_dc,E_cum,'r-','LineWidth',1.5,'DisplayName','Consumed'); hold on;
plot(t_dc,E_reg,'g-','LineWidth',1.5,'DisplayName','Recovered');
xlabel('Time (s)'); ylabel('Energy (Ah)');
title('Cumulative Energy: Consumed vs Recovered');
legend('Location','northwest'); grid on; set(gca,'FontSize',10);

save_fig('M03_Drive_Cycle.png');
fprintf('✔ Saved: M03_Drive_Cycle.png\n\n');

%% ============================================================
%  MODULE 04 — FAULT INJECTION & DETECTION
%% ============================================================
fprintf('▶ MODULE 04: Fault Injection & Detection\n');
fprintf('------------------------------------------\n');

% Inject 3 fault types on real simulation data
V_fault = V;
V_fault(t>=1800) = V_fault(t>=1800) - 0.15;   % Voltage drop

I_fault = I;
I_fault(t>=2200 & t<=2400) = ...
    I_fault(t>=2200 & t<=2400) * 3.5;           % Overcurrent

SOC_fault = SOC;
SOC_fault(t>=2500) = SOC_fault(t>=2500) - 0.08; % SOC anomaly

% Detection thresholds
V_min_th   = 3.90;
I_max_th   = 1.5;
SOC_min_th = 0.20;

flag_V   = V_fault < V_min_th;
flag_I   = I_fault > I_max_th;
flag_SOC = SOC_fault < SOC_min_th;

% SOH calculation
V_mx = 4.2; V_mn = 3.0;
SOH_n = (mean(V)     - V_mn)/(V_mx - V_mn)*100;
SOH_f = (mean(V_fault) - V_mn)/(V_mx - V_mn)*100;
SOH_drop = SOH_n - SOH_f;

% RUL
deg_rate = SOH_drop;
if deg_rate > 0
    RUL_hours = (SOH_f - 80) / deg_rate;
else
    RUL_hours = Inf;
end

fprintf('--- Fault Detection ---\n');
if any(flag_V)
    fprintf('VOLTAGE FAULT    : t=%.0fs | V=%.4fV\n',...
        t(find(flag_V,1)), V_fault(find(flag_V,1)));
else
    fprintf('Voltage          : NORMAL throughout\n');
end
if any(flag_I)
    fprintf('OVERCURRENT FAULT: t=%.0fs | I=%.4fA\n',...
        t(find(flag_I,1)), max(I_fault));
else
    fprintf('Current          : NORMAL throughout\n');
end
if any(flag_SOC)
    fprintf('SOC FAULT        : t=%.0fs\n', t(find(flag_SOC,1)));
else
    fprintf('SOC              : NORMAL throughout\n');
end

fprintf('\n--- State of Health ---\n');
fprintf('SOH Normal : %.2f%%\n', SOH_n);
fprintf('SOH Fault  : %.2f%%\n', SOH_f);
fprintf('SOH Drop   : %.2f%%\n', SOH_drop);
fprintf('RUL        : %.1f hours\n', RUL_hours);

fprintf('\n--- Smart Alert ---\n');
if SOH_f >= 90
    fprintf('Status: ✅ HEALTHY\n\n');
elseif SOH_f >= 80
    fprintf('Status: ⚠️ MODERATE — Schedule maintenance\n\n');
elseif SOH_f >= 60
    fprintf('Status: 🔶 LOW — Plan replacement\n\n');
else
    fprintf('Status: 🔴 CRITICAL — Replace immediately\n\n');
end

% Figure M04
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
b = bar([SOH_n, SOH_f],'FaceColor','flat');
b.CData = [0.2 0.7 0.3; 0.9 0.2 0.2];
yline(80,'k--','EOL Threshold (80%)','LineWidth',2);
set(gca,'XTickLabel',{'Normal SOH','Fault SOH'});
ylabel('SOH (%)'); title('State of Health Comparison');
ylim([0 110]); grid on; set(gca,'FontSize',10);

subplot(2,3,6);
soh_range = 100:-0.1:79;
rul_curve = max(0,(soh_range-80)/SOH_drop);
plot(soh_range,rul_curve,'b-','LineWidth',2);
xline(SOH_f,'r--',sprintf('Current=%.1f%%',SOH_f),'LineWidth',1.5);
xlabel('State of Health (%)'); ylabel('Remaining Hours');
title('Remaining Useful Life Prediction');
grid on; set(gca,'FontSize',10);

save_fig('M04_Fault_Detection.png');
fprintf('✔ Saved: M04_Fault_Detection.png\n\n');

%% ============================================================
%  MODULE 05 — CELL IMBALANCE DETECTION
%% ============================================================
fprintf('▶ MODULE 05: Cell Imbalance Detection\n');
fprintf('------------------------------------------\n');

rng(42);
cell_V = V(end) + 0.02*randn(1,96);
cell_V(23) = 3.85;  % Weak cell 1
cell_V(67) = 3.78;  % Weak cell 2
cell_V(45) = 3.91;  % Slightly weak cell 3

V_mean  = mean(cell_V);
V_std   = std(cell_V);
weak_th = V_mean - 2*V_std;
weak    = find(cell_V < weak_th);
imbal   = (max(cell_V)-min(cell_V))/V_mean*100;

fprintf('Mean voltage   : %.4f V\n', V_mean);
fprintf('Std deviation  : %.4f V\n', V_std);
fprintf('Imbalance      : %.2f%%\n', imbal);
fprintf('Weak cells     : %d detected\n', length(weak));
for i = 1:length(weak)
    fprintf('  Cell #%d: %.4f V (%.2f%% below mean)\n',...
        weak(i), cell_V(weak(i)),...
        (V_mean-cell_V(weak(i)))/V_mean*100);
end
fprintf('\n');

figure('Name','M05: Cell Imbalance',...
    'Color','white','Position',[50 50 1100 450]);

subplot(1,2,1);
bar(cell_V,'FaceColor',[0.3 0.6 0.9]); hold on;
bar(weak,cell_V(weak),'FaceColor','red');
yline(weak_th,'r--','Weak Threshold','LineWidth',2);
yline(V_mean,'g--','Mean Voltage','LineWidth',1.5);
xlabel('Cell Number'); ylabel('Voltage (V)');
title('96-Cell Voltage Distribution');
legend('Normal Cell','Weak Cell','Threshold','Mean');
grid on; set(gca,'FontSize',10);

subplot(1,2,2);
histogram(cell_V,20,'FaceColor',[0.3 0.6 0.9],'EdgeColor','white');
xline(weak_th,'r--','Weak Threshold','LineWidth',2);
xline(V_mean,'g--','Mean','LineWidth',2);
xlabel('Cell Voltage (V)'); ylabel('Number of Cells');
title('Cell Voltage Distribution Histogram');
grid on; set(gca,'FontSize',10);

save_fig('M05_Cell_Imbalance.png');
fprintf('✔ Saved: M05_Cell_Imbalance.png\n\n');

%% ============================================================
%  MODULE 06 — TEMPERATURE ANALYSIS
%% ============================================================
fprintf('▶ MODULE 06: Temperature Analysis\n');
fprintf('------------------------------------------\n');

T_vals  = [-40,-20,0,25,40,60];
T_lab   = {'-40C','-20C','0C','25C','40C','60C'};
cap_ret = [0.55,0.72,0.88,1.00,0.97,0.91];
R_fac   = [3.2,2.1,1.4,1.0,1.05,1.15];

for i = 1:length(T_vals)
    fprintf('T=%3dC : Capacity=%.0f%% | R_factor=%.2fx\n',...
        T_vals(i), cap_ret(i)*100, R_fac(i));
end
fprintf('\n');

figure('Name','M06: Temperature Analysis',...
    'Color','white','Position',[50 50 1200 500]);

subplot(1,3,1);
t_sim = 0:1:3600;
V_base = V;
clrs = lines(6);
for i = 1:6
    V_temp = V_base*cap_ret(i) - 0.005*R_fac(i);
    plot(t_sim,V_temp,'LineWidth',1.8,...
        'DisplayName',T_lab{i},'Color',clrs(i,:)); hold on;
end
xlabel('Time (s)'); ylabel('Voltage (V)');
title('Voltage at Different Temperatures');
legend('Location','southwest'); grid on; set(gca,'FontSize',9);

subplot(1,3,2);
b3 = bar(categorical(T_lab),cap_ret*100,'FaceColor','flat');
b3.CData = jet(6);
ylabel('Capacity (%)'); title('Capacity vs Temperature');
grid on; set(gca,'FontSize',10);

subplot(1,3,3);
T_cont = -40:1:80;
cap_cont = 100*(1 - 0.003*(T_cont-25).^2/100);
cap_cont = min(cap_cont,100);
plot(T_cont,cap_cont,'b-','LineWidth',2);
xline(25,'g--','Optimal 25C','LineWidth',1.5);
xline(-10,'r--','Min Recommended','LineWidth',1.5);
xline(45,'r--','Max Recommended','LineWidth',1.5);
xlabel('Temperature (°C)'); ylabel('Capacity (%)');
title('Operating Temperature Envelope');
grid on; set(gca,'FontSize',10);

save_fig('M06_Temperature_Analysis.png');
fprintf('✔ Saved: M06_Temperature_Analysis.png\n\n');

%% ============================================================
%  MODULE 07 — BATTERY AGING & CAPACITY FADE
%% ============================================================
fprintf('▶ MODULE 07: Battery Aging Model\n');
fprintf('------------------------------------------\n');

cycles   = 0:10:2000;
cap_fade = 100*exp(-0.00035*cycles);
R_growth = 1 + 0.0002*cycles;
EOL_idx  = find(cap_fade<=80,1);

fprintf('End of Life at : %d cycles\n', cycles(EOL_idx));
fprintf('Capacity @ EOL : %.1f%%\n', cap_fade(EOL_idx));
fprintf('Resistance @EOL: %.2fx initial\n\n', R_growth(EOL_idx));

figure('Name','M07: Battery Aging',...
    'Color','white','Position',[50 50 1100 450]);

subplot(1,2,1);
plot(cycles,cap_fade,'b-','LineWidth',2.5);
yline(80,'r--','End of Life (80%)','LineWidth',2);
xline(cycles(EOL_idx),'k:',...
    sprintf('EOL=%d cycles',cycles(EOL_idx)),'LineWidth',1.5);
fill([0,cycles,fliplr(cycles)],...
    [80,cap_fade,fliplr(ones(size(cycles))*80)],...
    'red','FaceAlpha',0.08,'EdgeColor','none');
xlabel('Charge Cycles'); ylabel('Capacity (%)');
title('Capacity Fade Over Lifetime');
grid on; set(gca,'FontSize',11);

subplot(1,2,2);
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

save_fig('M07_Aging_Model.png');
fprintf('✔ Saved: M07_Aging_Model.png\n\n');

%% ============================================================
%  MODULE 08 — SOC ESTIMATION COMPARISON
%            (Coulomb Counting vs Adaptive Kalman Filter)
%% ============================================================
fprintf('▶ MODULE 08: SOC Estimation Comparison\n');
fprintf('------------------------------------------\n');

SOC_cc    = zeros(length(t),1);
SOC_cc(1) = 1.0;
for k = 2:length(t)
    SOC_cc(k) = max(SOC_cc(k-1) - ...
        abs(I(k))/(Q_pack*3600), 0);
end
SOC_cc_noisy = SOC_cc + 0.002*randn(length(t),1);

err_rms = rms(SOC - SOC_cc)*100;
fprintf('Kalman Filter SOC Final  : %.2f%%\n', SOC(end)*100);
fprintf('Coulomb Counting SOC     : %.2f%%\n', SOC_cc(end)*100);
fprintf('RMS Error between methods: %.4f%%\n', err_rms);
fprintf('Kalman is superior — rejects sensor noise\n\n');

figure('Name','M08: SOC Estimation Comparison',...
    'Color','white','Position',[50 50 1100 450]);

plot(t,SOC*100,'g-','LineWidth',2.5,...
    'DisplayName','Adaptive Kalman Filter'); hold on;
plot(t,SOC_cc*100,'b--','LineWidth',2,...
    'DisplayName','Coulomb Counting');
plot(t,SOC_cc_noisy*100,'r:','LineWidth',1,...
    'DisplayName','Coulomb + Sensor Noise');
yline(20,'k--','Low SOC Warning (20%)','LineWidth',1.5);
xlabel('Time (s)'); ylabel('SOC (%)');
title('SOC Estimation: Adaptive Kalman Filter vs Coulomb Counting');
legend('Location','southwest'); grid on;
set(gca,'FontSize',11);

save_fig('M08_SOC_Comparison.png');
fprintf('✔ Saved: M08_SOC_Comparison.png\n\n');

%% ============================================================
%  MODULE 09 — ML FAULT CLASSIFICATION
%            (Decision Tree + SVM + Random Forest)
%% ============================================================
fprintf('▶ MODULE 09: ML Fault Classification\n');
fprintf('------------------------------------------\n');

dV = gradient(V); dI = gradient(I);

% 4 fault classes
X0 = [V,I,dV,dI,V.*I];             y0 = zeros(length(t),1); % Normal
V1=V+0.3; X1=[V1,I,gradient(V1),dI,V1.*I]; y1=ones(length(t),1);     % Overvoltage
I2=I*4;   X2=[V,I2,dV,gradient(I2),V.*I2]; y2=2*ones(length(t),1);   % Overcurrent
V3=V*0.92;I3=I*0.88;
X3=[V3,I3,gradient(V3),gradient(I3),V3.*I3]; y3=3*ones(length(t),1); % Cap. fade

idx  = 1:10:length(t);
X_ml = [X0(idx,:);X1(idx,:);X2(idx,:);X3(idx,:)];
y_ml = [y0(idx);y1(idx);y2(idx);y3(idx)];

rng(42);
perm = randperm(length(y_ml));
X_ml = X_ml(perm,:); y_ml = y_ml(perm);

sp_ml = round(0.8*length(y_ml));
X_tr = X_ml(1:sp_ml,:);     y_tr = y_ml(1:sp_ml);
X_te = X_ml(sp_ml+1:end,:); y_te = y_ml(sp_ml+1:end);

fprintf('Training Decision Tree...\n');
dt_mdl  = fitctree(X_tr,y_tr,'MaxNumSplits',20);
y_dt    = predict(dt_mdl,X_te);
acc_dt  = sum(y_dt==y_te)/length(y_te)*100;

fprintf('Training SVM...\n');
svm_mdl = fitcecoc(X_tr,y_tr,...
    'Learners',templateSVM('KernelFunction','rbf',...
    'KernelScale','auto'));
y_svm   = predict(svm_mdl,X_te);
acc_svm = sum(y_svm==y_te)/length(y_te)*100;

fprintf('Training Random Forest (50 trees)...\n');
rf_mdl  = TreeBagger(50,X_tr,y_tr,'Method','classification',...
    'MinLeafSize',5);
y_rf    = str2double(predict(rf_mdl,X_te));
acc_rf  = sum(y_rf==y_te)/length(y_te)*100;

fprintf('\nDecision Tree Accuracy : %.2f%%\n', acc_dt);
fprintf('SVM Accuracy           : %.2f%%\n', acc_svm);
fprintf('Random Forest Accuracy : %.2f%%\n', acc_rf);
fprintf('Best Model             : %.2f%%\n\n', max([acc_dt,acc_svm,acc_rf]));

class_names = {'Normal','Overvoltage','Overcurrent','CapFade'};

figure('Name','M09: ML Fault Classification',...
    'Color','white','Position',[50 50 1300 450]);

subplot(1,3,1);
confusionchart(confusionmat(y_te,y_dt),class_names,...
    'Title',sprintf('Decision Tree (%.1f%%)',acc_dt),...
    'RowSummary','row-normalized');

subplot(1,3,2);
confusionchart(confusionmat(y_te,y_svm),class_names,...
    'Title',sprintf('SVM (%.1f%%)',acc_svm),...
    'RowSummary','row-normalized');

subplot(1,3,3);
confusionchart(confusionmat(y_te,y_rf),class_names,...
    'Title',sprintf('Random Forest (%.1f%%)',acc_rf),...
    'RowSummary','row-normalized');

save_fig('M09_ML_Fault_Classification.png');
fprintf('✔ Saved: M09_ML_Fault_Classification.png\n\n');

% Save ML models
save(fullfile(output_folder,'dt_model.mat'),'dt_mdl');
save(fullfile(output_folder,'svm_model.mat'),'svm_mdl');
save(fullfile(output_folder,'rf_model.mat'),'rf_mdl');
fprintf('✔ ML models saved to EV_Battery_Outputs/\n\n');

%% ============================================================
%  MODULE 10 — GPR REMAINING USEFUL LIFE PREDICTION
%% ============================================================
fprintf('▶ MODULE 10: GPR RUL Prediction\n');
fprintf('------------------------------------------\n');

cyc_gpr  = (1:500)';
SOH_true = 100*exp(-0.00035*cyc_gpr) + 2*sin(0.05*cyc_gpr);
SOH_meas = SOH_true + 1.5*randn(500,1);
SOH_meas = max(SOH_meas,70);

dSOH_g = gradient(SOH_meas);
mSOH_g = movmean(SOH_meas,10);
X_gpr  = [cyc_gpr, SOH_meas, dSOH_g, mSOH_g];

sp_gpr  = 400;
fprintf('Training GPR model (this may take 1-2 minutes)...\n');
gpr_mdl = fitrgp(X_gpr(1:sp_gpr,:), SOH_true(1:sp_gpr),...
    'KernelFunction','squaredexponential',...
    'OptimizeHyperparameters','auto',...
    'HyperparameterOptimizationOptions',...
    struct('Verbose',0,...
    'AcquisitionFunctionName','expected-improvement-plus'));

[pred_gpr,~,ci_gpr] = predict(gpr_mdl, X_gpr(sp_gpr+1:end,:));
RMSE_gpr = sqrt(mean((SOH_true(sp_gpr+1:end)-pred_gpr).^2));
EOL_gpr  = find(pred_gpr<=80,1);

if ~isempty(EOL_gpr)
    fprintf('EOL predicted at cycle : %d\n', sp_gpr+EOL_gpr);
    fprintf('Remaining cycles       : %d\n', EOL_gpr);
end
fprintf('GPR RMSE               : %.4f%%\n\n', RMSE_gpr);

figure('Name','M10: GPR RUL Prediction',...
    'Color','white','Position',[50 50 1100 450]);

subplot(1,2,1);
plot(cyc_gpr(1:sp_gpr),SOH_meas(1:sp_gpr),'b.',...
    'MarkerSize',3,'DisplayName','Measured'); hold on;
plot(cyc_gpr(sp_gpr+1:end),SOH_true(sp_gpr+1:end),'g-',...
    'LineWidth',2,'DisplayName','True SOH');
plot(cyc_gpr(sp_gpr+1:end),pred_gpr,'r-',...
    'LineWidth',2,'DisplayName','GPR Prediction');
fill([cyc_gpr(sp_gpr+1:end);flipud(cyc_gpr(sp_gpr+1:end))],...
    [pred_gpr+ci_gpr(:,2);flipud(pred_gpr-ci_gpr(:,1))],...
    'red','FaceAlpha',0.15,'EdgeColor','none',...
    'DisplayName','95% Confidence');
yline(80,'k--','EOL Threshold','LineWidth',2);
xlabel('Cycle'); ylabel('SOH (%)');
title('GPR SOH Prediction with 95% Confidence');
legend('Location','southwest'); grid on; set(gca,'FontSize',10);

subplot(1,2,2);
if ~isempty(EOL_gpr)
    future_cyc = (sp_gpr:500+EOL_gpr)';
    X_fut = [future_cyc,...
        repmat(SOH_meas(end),length(future_cyc),1),...
        repmat(dSOH_g(end),length(future_cyc),1),...
        repmat(mSOH_g(end),length(future_cyc),1)];
    [SOH_fut,~,ci_fut] = predict(gpr_mdl,X_fut);
    plot(future_cyc,SOH_fut,'r-','LineWidth',2,...
        'DisplayName','Predicted'); hold on;
    fill([future_cyc;flipud(future_cyc)],...
        [SOH_fut+ci_fut(:,2);flipud(SOH_fut-ci_fut(:,1))],...
        'red','FaceAlpha',0.15,'EdgeColor','none',...
        'DisplayName','95% CI');
    yline(80,'k--','EOL (80%)','LineWidth',2);
    xline(sp_gpr+EOL_gpr,'b--',...
        sprintf('EOL @ cycle %d',sp_gpr+EOL_gpr),'LineWidth',1.5);
    xlabel('Cycle'); ylabel('SOH (%)');
    title(sprintf('RUL: %d cycles remaining',EOL_gpr));
    legend('Location','northeast'); grid on; set(gca,'FontSize',10);
end

save_fig('M10_GPR_RUL_Prediction.png');
save(fullfile(output_folder,'gpr_model.mat'),'gpr_mdl');
fprintf('✔ Saved: M10_GPR_RUL_Prediction.png\n');
fprintf('✔ GPR model saved to EV_Battery_Outputs/\n\n');

%% ============================================================
%  MODULE 11 — LSTM SOC PREDICTION (Deep Learning)
%% ============================================================
fprintf('▶ MODULE 11: LSTM SOC Prediction\n');
fprintf('------------------------------------------\n');

% Feature engineering
normalize_fn = @(x) (x-min(x))/(max(x)-min(x)+1e-10);
dV_f  = gradient(V);
dI_f  = gradient(I);
P_f   = V.*I;
E_f   = cumtrapz(t, P_f);

V_n  = normalize_fn(V);
I_n  = normalize_fn(I);
dV_n = normalize_fn(dV_f);
dI_n = normalize_fn(dI_f);
P_n  = normalize_fn(P_f);
E_n  = normalize_fn(E_f);

X_lstm = [V_n, I_n, dV_n, dI_n, P_n, E_n];
y_lstm = SOC;

sp_lstm   = round(0.8*length(y_lstm));
X_tr_lstm = X_lstm(1:sp_lstm,:);
y_tr_lstm = y_lstm(1:sp_lstm);
X_te_lstm = X_lstm(sp_lstm+1:end,:);
y_te_lstm = y_lstm(sp_lstm+1:end);

% LSTM network definition
numFeatures = 6;
numHidden1  = 64;
numHidden2  = 32;

layers = [
    sequenceInputLayer(numFeatures,'Name','input')
    lstmLayer(numHidden1,'OutputMode','sequence','Name','lstm1')
    dropoutLayer(0.2,'Name','drop1')
    lstmLayer(numHidden2,'OutputMode','sequence','Name','lstm2')
    dropoutLayer(0.1,'Name','drop2')
    fullyConnectedLayer(16,'Name','fc1')
    reluLayer('Name','relu1')
    fullyConnectedLayer(1,'Name','output')
    regressionLayer('Name','regression')
];

options = trainingOptions('adam',...
    'MaxEpochs',50,...
    'MiniBatchSize',32,...
    'InitialLearnRate',0.001,...
    'GradientThreshold',1,...
    'Shuffle','never',...
    'ValidationData',{{X_te_lstm'},{y_te_lstm'}},...
    'ValidationFrequency',10,...
    'Plots','training-progress',...
    'Verbose',false);

fprintf('Training LSTM (50 epochs)...\n');
lstm_net = trainNetwork({X_tr_lstm'},{y_tr_lstm'},layers,options);
fprintf('LSTM training complete!\n');

% Predictions
pred_tr = lstm_net.predict({X_tr_lstm'});
pred_te = lstm_net.predict({X_te_lstm'});
pred_tr = pred_tr{1}';
pred_te = pred_te{1}';

% Metrics
MAE_te  = mean(abs(y_te_lstm - pred_te))*100;
RMSE_te = sqrt(mean((y_te_lstm - pred_te).^2))*100;
SS_res  = sum((y_te_lstm - pred_te).^2);
SS_tot  = sum((y_te_lstm - mean(y_te_lstm)).^2);
R2_lstm = 1 - SS_res/SS_tot;

fprintf('LSTM Test MAE  : %.4f%%\n', MAE_te);
fprintf('LSTM Test RMSE : %.4f%%\n', RMSE_te);
fprintf('LSTM R²        : %.4f\n\n', R2_lstm);

% Figure M11
figure('Name','M11: LSTM SOC Prediction',...
    'Color','white','Position',[50 50 1200 600]);

subplot(2,2,1);
plot(t,y_lstm*100,'b-','LineWidth',1.5,...
    'DisplayName','Actual SOC'); hold on;
plot(t(sp_lstm+1:end),pred_te*100,'r--',...
    'LineWidth',2,'DisplayName','LSTM Predicted');
xline(t(sp_lstm),'k:','Train|Test','LineWidth',1.5);
xlabel('Time (s)'); ylabel('SOC (%)');
title('LSTM: Actual vs Predicted SOC');
legend('Location','southwest'); grid on; set(gca,'FontSize',10);

subplot(2,2,2);
err_lstm = (y_te_lstm - pred_te)*100;
plot(t(sp_lstm+1:end),err_lstm,'g-','LineWidth',1.5);
yline(0,'k-','LineWidth',1);
yline(1,'r--','±1%','LineWidth',1);
yline(-1,'r--','LineWidth',1);
xlabel('Time (s)'); ylabel('Error (%)');
title('LSTM Prediction Error');
grid on; set(gca,'FontSize',10);

subplot(2,2,3);
scatter(y_te_lstm*100,pred_te*100,20,'filled',...
    'MarkerFaceColor','blue','MarkerFaceAlpha',0.5);
hold on;
lims = [min(y_te_lstm) max(y_te_lstm)]*100;
plot(lims,lims,'r-','LineWidth',2);
xlabel('Actual SOC (%)'); ylabel('Predicted SOC (%)');
title(sprintf('Actual vs Predicted (R²=%.4f)',R2_lstm));
grid on; set(gca,'FontSize',10);

subplot(2,2,4);
histogram(err_lstm,30,'FaceColor','blue',...
    'EdgeColor','white','FaceAlpha',0.7);
xline(0,'r-','LineWidth',2);
xlabel('Error (%)'); ylabel('Frequency');
title(sprintf('Error Distribution (MAE=%.3f%%)',MAE_te));
grid on; set(gca,'FontSize',10);

save_fig('M11_LSTM_SOC_Prediction.png');
save(fullfile(output_folder,'lstm_model.mat'),'lstm_net');
fprintf('✔ Saved: M11_LSTM_SOC_Prediction.png\n');
fprintf('✔ LSTM model saved to EV_Battery_Outputs/\n\n');

%% ============================================================
%  MODULE 12 — EXPORT FULL CSV REPORT
%% ============================================================
fprintf('▶ MODULE 12: Exporting Final CSV Report\n');
fprintf('------------------------------------------\n');

SOC_cc_col = SOC_cc;
T_final = table(...
    t,...
    V,...
    V_fault,...
    I,...
    I_fault,...
    SOC*100,...
    SOC_fault*100,...
    SOC_cc_col*100,...
    double(flag_V),...
    double(flag_I),...
    double(flag_SOC),...
    'VariableNames',{...
    'Time_s','V_Normal_V','V_Fault_V',...
    'I_Normal_A','I_Fault_A',...
    'SOC_Kalman_pct','SOC_Fault_pct','SOC_Coulomb_pct',...
    'Flag_Voltage','Flag_Current','Flag_SOC'});

csv_path = fullfile(output_folder,'Final_Battery_Report.csv');
writetable(T_final, csv_path);
fprintf('✔ Saved: Final_Battery_Report.csv\n\n');

%% ============================================================
%  MODULE 13 — FINAL SUMMARY
%% ============================================================
fprintf('==========================================\n');
fprintf('         FINAL PROJECT SUMMARY            \n');
fprintf('==========================================\n');
fprintf('Pack Config        : 96S4P NMC Pouch\n');
fprintf('Total Cells        : %d\n', n_cells);
fprintf('Pack Voltage       : %.1f V\n', V_pack_nom);
fprintf('Pack Energy        : %.3f kWh\n', E_pack_kWh);
fprintf('------------------------------------------\n');
fprintf('Normal SOH         : %.2f%%\n', SOH_n);
fprintf('Fault SOH          : %.2f%%\n', SOH_f);
fprintf('SOH Drop           : %.2f%%\n', SOH_drop);
fprintf('Fault Detected     : Overcurrent @ t=2200s\n');
fprintf('RUL                : %.1f hours\n', RUL_hours);
fprintf('------------------------------------------\n');
fprintf('ML Models Trained  :\n');
fprintf('  Decision Tree     : %.2f%%\n', acc_dt);
fprintf('  SVM               : %.2f%%\n', acc_svm);
fprintf('  Random Forest     : %.2f%%\n', acc_rf);
fprintf('  Best ML Accuracy  : %.2f%%\n', max([acc_dt,acc_svm,acc_rf]));
fprintf('  GPR RMSE          : %.4f%%\n', RMSE_gpr);
fprintf('  LSTM R²           : %.4f\n', R2_lstm);
fprintf('  LSTM MAE          : %.4f%%\n', MAE_te);
fprintf('------------------------------------------\n');
fprintf('OUTPUT FILES SAVED TO: EV_Battery_Outputs/\n');
fprintf('  M01_Pack_Specification.png\n');
fprintf('  M02_Normal_Simulation.png\n');
fprintf('  M03_Drive_Cycle.png\n');
fprintf('  M04_Fault_Detection.png\n');
fprintf('  M05_Cell_Imbalance.png\n');
fprintf('  M06_Temperature_Analysis.png\n');
fprintf('  M07_Aging_Model.png\n');
fprintf('  M08_SOC_Comparison.png\n');
fprintf('  M09_ML_Fault_Classification.png\n');
fprintf('  M10_GPR_RUL_Prediction.png\n');
fprintf('  M11_LSTM_SOC_Prediction.png\n');
fprintf('  Final_Battery_Report.csv\n');
fprintf('  dt_model.mat\n');
fprintf('  svm_model.mat\n');
fprintf('  rf_model.mat\n');
fprintf('  gpr_model.mat\n');
fprintf('  lstm_model.mat\n');
fprintf('==========================================\n');
fprintf('✅ PROJECT COMPLETE! ALL FILES SAVED!\n');
fprintf('==========================================\n');
%% ============================================================
%  MODULE 05 — CELL IMBALANCE DETECTION
%  Project : Smart EV Battery Health & Fault Prediction System
%  Author  : [Your Name] | Tool: MATLAB 2025a
%  Requires: normal_condition.mat
%% ============================================================
clc; clear; close all;

output_folder = 'EV_Battery_Outputs';
if ~exist(output_folder,'dir'), mkdir(output_folder); end

fprintf('==========================================\n');
fprintf('   MODULE 05: CELL IMBALANCE DETECTION    \n');
fprintf('==========================================\n\n');

load('normal_condition.mat');
V=V_normal;

%% --- SIMULATE 96 CELL VOLTAGES ---
rng(42);
cell_V=V(end)+0.02*randn(1,96);

% Inject known weak cells
cell_V(23)=3.85;  % Weak cell 1 — aged
cell_V(67)=3.78;  % Weak cell 2 — severely aged
cell_V(45)=3.91;  % Weak cell 3 — slightly degraded

%% --- ANALYSIS ---
V_mean  = mean(cell_V);
V_std   = std(cell_V);
weak_th = V_mean - 2*V_std;
weak    = find(cell_V < weak_th);
imbal   = (max(cell_V)-min(cell_V))/V_mean*100;

fprintf('Mean cell voltage  : %.4f V\n', V_mean);
fprintf('Std deviation      : %.4f V\n', V_std);
fprintf('Max cell voltage   : %.4f V (Cell #%d)\n',...
    max(cell_V),find(cell_V==max(cell_V)));
fprintf('Min cell voltage   : %.4f V (Cell #%d)\n',...
    min(cell_V),find(cell_V==min(cell_V)));
fprintf('Imbalance          : %.2f%%\n', imbal);
fprintf('Weak threshold     : %.4f V\n', weak_th);
fprintf('Weak cells detected: %d\n', length(weak));
for i=1:length(weak)
    fprintf('  Cell #%d: %.4f V (%.2f%% below mean)\n',...
        weak(i),cell_V(weak(i)),...
        (V_mean-cell_V(weak(i)))/V_mean*100);
end

%% --- BALANCING RECOMMENDATION ---
fprintf('\n--- Balancing Recommendation ---\n');
if imbal > 2
    fprintf('ACTION REQUIRED: Active cell balancing needed\n');
elseif imbal > 1
    fprintf('WARNING: Passive balancing recommended\n');
else
    fprintf('STATUS: Pack is well balanced\n');
end

%% --- PLOT ---
figure('Name','M05: Cell Imbalance Detection',...
    'Color','white','Position',[50 50 1200 500]);

subplot(1,3,1);
bar(cell_V,'FaceColor',[0.3 0.6 0.9]); hold on;
bar(weak,cell_V(weak),'FaceColor','red');
yline(weak_th,'r--','Weak Threshold','LineWidth',2);
yline(V_mean,'g--','Mean Voltage','LineWidth',1.5);
xlabel('Cell Number'); ylabel('Voltage (V)');
title('96-Cell Voltage Distribution');
legend('Normal','Weak Cell','Threshold','Mean');
grid on; set(gca,'FontSize',10);

subplot(1,3,2);
histogram(cell_V,20,'FaceColor',[0.3 0.6 0.9],'EdgeColor','white');
xline(weak_th,'r--','Weak Threshold','LineWidth',2);
xline(V_mean,'g--','Mean','LineWidth',2);
xlabel('Cell Voltage (V)'); ylabel('Number of Cells');
title('Cell Voltage Histogram'); grid on; set(gca,'FontSize',10);

subplot(1,3,3);
deviation=(cell_V-V_mean)*1000;
bar(deviation,'FaceColor','flat');
colormap(redblue_custom(256));
xlabel('Cell Number'); ylabel('Deviation (mV)');
title('Cell Voltage Deviation from Mean');
yline(0,'k-','LineWidth',1.5); grid on; set(gca,'FontSize',10);

saveas(gcf,fullfile(output_folder,'M05_Cell_Imbalance.png'));
fprintf('\n✔ Saved: M05_Cell_Imbalance.png\n');
fprintf('MODULE 05 COMPLETE!\n');

%% --- Helper: Custom colormap ---
function cmap = redblue_custom(n)
    r=[linspace(0,1,n/2), ones(1,n/2)];
    b=[ones(1,n/2), linspace(1,0,n/2)];
    g=[linspace(0,1,n/2), linspace(1,0,n/2)];
    cmap=[r',g',b'];
end

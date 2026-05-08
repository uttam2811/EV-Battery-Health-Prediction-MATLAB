%% ============================================================
%  MODULE 01 — BATTERY PACK SPECIFICATION
%  Project : Smart EV Battery Health & Fault Prediction System
%  Author  : [Your Name] | Tool: MATLAB 2025a
%  Run     : Press F5 — output saved to EV_Battery_Outputs/
%% ============================================================
clc; clear; close all;

output_folder = 'EV_Battery_Outputs';
if ~exist(output_folder,'dir'), mkdir(output_folder); end

fprintf('==========================================\n');
fprintf('   MODULE 01: BATTERY PACK SPECIFICATION  \n');
fprintf('==========================================\n\n');

V_cell_nom=3.7; V_cell_max=4.2; V_cell_min=3.0;
Q_cell=5; R_cell=0.005; mass_cell=0.045; E_cell_Wh=18.5;

n_series=96; n_parallel=4; n_cells=n_series*n_parallel;
V_pack_nom=n_series*V_cell_nom; V_pack_max=n_series*V_cell_max;
V_pack_min=n_series*V_cell_min; Q_pack=n_parallel*Q_cell;
E_pack_Wh=V_pack_nom*Q_pack; E_pack_kWh=E_pack_Wh/1000;
R_pack=(n_series/n_parallel)*R_cell; mass_pack=n_cells*mass_cell;
volume_pack=0.0417;
gravimetric_density=E_pack_Wh/mass_pack;
volumetric_density=(E_pack_Wh/volume_pack)/1000;
V_module=12*V_cell_nom; E_module_Wh=V_module*Q_pack;

fprintf('Configuration      : 96S4P\n');
fprintf('Total Cells        : %d\n', n_cells);
fprintf('Nominal Voltage    : %.1f V\n', V_pack_nom);
fprintf('Capacity           : %.0f Ah\n', Q_pack);
fprintf('Energy             : %.3f kWh\n', E_pack_kWh);
fprintf('Pack Mass          : %.2f kg\n', mass_pack);
fprintf('Gravimetric Density: %.1f Wh/kg\n', gravimetric_density);
fprintf('Volumetric Density : %.1f Wh/L\n\n', volumetric_density);

C_rates=[0.5,1,2,3,4];
fprintf('C-Rate Analysis:\n');
for i=1:length(C_rates)
    fprintf('  %.1fC: %.0fA — %.1fhr\n',...
        C_rates(i),C_rates(i)*Q_pack,1/C_rates(i));
end

figure('Name','M01: Pack Specification',...
    'Color','white','Position',[50 50 1100 450]);

subplot(1,3,1);
b1=bar([E_cell_Wh,E_module_Wh,E_pack_Wh],'FaceColor','flat');
b1.CData=[0.2 0.6 0.9;0.1 0.8 0.4;0.9 0.3 0.2];
set(gca,'XTickLabel',{'Cell','Module','Pack'},'FontSize',10);
ylabel('Energy (Wh)'); title('Energy: Cell→Module→Pack'); grid on;

subplot(1,3,2);
c_r=0.1:0.1:5;
plot(c_r,1./c_r,'b-','LineWidth',2);
xline(1,'r--','1C','LineWidth',1.5); xline(2,'g--','2C','LineWidth',1.5);
xlabel('C-Rate'); ylabel('Time (hours)');
title('C-Rate vs Discharge Time'); grid on; set(gca,'FontSize',10);

subplot(1,3,3);
b2=bar([V_pack_min,V_pack_nom,V_pack_max],'FaceColor','flat');
b2.CData=[0.9 0.2 0.2;0.2 0.7 0.3;0.2 0.4 0.9];
set(gca,'XTickLabel',{'Min','Nominal','Max'},'FontSize',10);
ylabel('Voltage (V)'); ylim([0 450]);
title('Pack Voltage Range'); grid on;

saveas(gcf,fullfile(output_folder,'M01_Pack_Specification.png'));
fprintf('\n✔ Saved: M01_Pack_Specification.png\n');
fprintf('MODULE 01 COMPLETE!\n');

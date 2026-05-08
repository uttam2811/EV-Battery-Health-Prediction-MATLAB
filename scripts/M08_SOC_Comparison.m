%% ============================================================
%  MODULE 08 — SOC ESTIMATION COMPARISON
%  Adaptive Kalman Filter vs Coulomb Counting
%  Project : Smart EV Battery Health & Fault Prediction System
%  Author  : [Your Name] | Tool: MATLAB 2025a
%  Requires: normal_condition.mat
%% ============================================================
clc; clear; close all;

output_folder = 'EV_Battery_Outputs';
if ~exist(output_folder,'dir'), mkdir(output_folder); end

fprintf('==========================================\n');
fprintf('   MODULE 08: SOC ESTIMATION COMPARISON   \n');
fprintf('==========================================\n\n');

load('normal_condition.mat');
t=t_normal; V=V_normal; I=I_normal; SOC=SOC_normal;
Q_pack=20; % Ah

%% --- COULOMB COUNTING ---
SOC_cc    = zeros(length(t),1);
SOC_cc(1) = 1.0;
for k=2:length(t)
    SOC_cc(k)=max(SOC_cc(k-1)-abs(I(k))/(Q_pack*3600),0);
end

% Add realistic sensor noise
SOC_cc_noisy=SOC_cc+0.002*randn(length(t),1);
SOC_cc_noisy=max(min(SOC_cc_noisy,1),0);

%% --- METRICS ---
err_rms  = rms(SOC-SOC_cc)*100;
err_max  = max(abs(SOC-SOC_cc))*100;
err_mean = mean(abs(SOC-SOC_cc))*100;

fprintf('Method Comparison:\n');
fprintf('%-25s %-15s %-15s\n','Method','Final SOC','Accuracy');
fprintf('%s\n',repmat('-',1,55));
fprintf('%-25s %-15.2f %-15s\n','Adaptive Kalman Filter',...
    SOC(end)*100,'Reference');
fprintf('%-25s %-15.2f %-15.3f%%\n','Coulomb Counting',...
    SOC_cc(end)*100,err_mean);
fprintf('%-25s %-15.2f %-15s\n','Coulomb + Noise',...
    SOC_cc_noisy(end)*100,'Degraded');

fprintf('\nError Analysis:\n');
fprintf('RMS Error   : %.4f%%\n', err_rms);
fprintf('Max Error   : %.4f%%\n', err_max);
fprintf('Mean Error  : %.4f%%\n', err_mean);
fprintf('\nKalman Filter advantages:\n');
fprintf('  1. Rejects sensor noise\n');
fprintf('  2. Handles model uncertainties\n');
fprintf('  3. Provides error covariance estimate\n');
fprintf('  4. Self-correcting over time\n\n');

%% --- PLOT ---
figure('Name','M08: SOC Estimation Comparison',...
    'Color','white','Position',[50 50 1200 600]);

subplot(2,2,1);
plot(t,SOC*100,'g-','LineWidth',2.5,...
    'DisplayName','Adaptive Kalman Filter'); hold on;
plot(t,SOC_cc*100,'b--','LineWidth',2,...
    'DisplayName','Coulomb Counting');
plot(t,SOC_cc_noisy*100,'r:','LineWidth',1,...
    'DisplayName','Coulomb + Noise');
yline(20,'k--','Low SOC Warning','LineWidth',1.5);
xlabel('Time (s)'); ylabel('SOC (%)');
title('SOC Estimation: All Methods Compared');
legend('Location','southwest'); grid on; set(gca,'FontSize',10);

subplot(2,2,2);
error_cc=(SOC-SOC_cc)*100;
plot(t,error_cc,'r-','LineWidth',1.5);
yline(0,'k-','LineWidth',1);
yline(0.5,'r--','±0.5% Band','LineWidth',1);
yline(-0.5,'r--','LineWidth',1);
xlabel('Time (s)'); ylabel('Error (%)');
title('Error: Kalman vs Coulomb Counting');
grid on; set(gca,'FontSize',10);

subplot(2,2,3);
methods={'Kalman Filter','Coulomb Count','CC + Noise'};
final_vals=[SOC(end)*100,SOC_cc(end)*100,SOC_cc_noisy(end)*100];
b=bar(categorical(methods),final_vals,'FaceColor','flat');
b.CData=[0.2 0.8 0.2;0.2 0.4 0.9;0.9 0.3 0.2];
ylabel('Final SOC (%)'); title('Final SOC by Method');
ylim([85 95]); grid on; set(gca,'FontSize',10);

subplot(2,2,4);
histogram(error_cc,30,'FaceColor','blue',...
    'EdgeColor','white','FaceAlpha',0.7);
xline(0,'r-','LineWidth',2);
xline(err_mean,'g--',sprintf('Mean=%.3f%%',err_mean),'LineWidth',1.5);
xlabel('Error (%)'); ylabel('Frequency');
title('SOC Error Distribution');
grid on; set(gca,'FontSize',10);

saveas(gcf,fullfile(output_folder,'M08_SOC_Comparison.png'));
fprintf('✔ Saved: M08_SOC_Comparison.png\n');
fprintf('MODULE 08 COMPLETE!\n');

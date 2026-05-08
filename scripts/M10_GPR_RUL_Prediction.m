%% ============================================================
%  MODULE 10 — GPR REMAINING USEFUL LIFE PREDICTION
%  Gaussian Process Regression with Confidence Intervals
%  Project : Smart EV Battery Health & Fault Prediction System
%  Author  : [Your Name] | Tool: MATLAB 2025a
%% ============================================================
clc; clear; close all;

output_folder = 'EV_Battery_Outputs';
if ~exist(output_folder,'dir'), mkdir(output_folder); end

fprintf('==========================================\n');
fprintf('   MODULE 10: GPR RUL PREDICTION          \n');
fprintf('==========================================\n\n');

%% --- GENERATE AGING DATASET ---
rng(42);
n_cycles  = 500;
cyc_gpr   = (1:n_cycles)';

% Realistic SOH degradation with noise
SOH_true  = 100*exp(-0.00035*cyc_gpr) + 2*sin(0.05*cyc_gpr);
SOH_meas  = SOH_true + 1.5*randn(n_cycles,1);
SOH_meas  = max(SOH_meas,70);

% Feature engineering for GPR
dSOH_g = gradient(SOH_meas);
mSOH_g = movmean(SOH_meas,10);
X_gpr  = [cyc_gpr, SOH_meas, dSOH_g, mSOH_g];
y_gpr  = SOH_true;

%% --- TRAIN/TEST SPLIT ---
sp_gpr    = 400;
X_tr      = X_gpr(1:sp_gpr,:);
y_tr      = y_gpr(1:sp_gpr);
X_te      = X_gpr(sp_gpr+1:end,:);
y_te      = y_gpr(sp_gpr+1:end);

fprintf('Training samples : %d\n', sp_gpr);
fprintf('Test samples     : %d\n', n_cycles-sp_gpr);
fprintf('Features         : Cycle, SOH, dSOH/dt, Moving Avg SOH\n\n');

%% --- TRAIN GPR ---
fprintf('Training GPR model (optimizing hyperparameters)...\n');
fprintf('This may take 1-2 minutes...\n\n');

gpr_mdl = fitrgp(X_tr, y_tr,...
    'KernelFunction','squaredexponential',...
    'OptimizeHyperparameters','auto',...
    'HyperparameterOptimizationOptions',...
    struct('Verbose',0,...
    'AcquisitionFunctionName','expected-improvement-plus'));

%% --- PREDICT WITH CONFIDENCE INTERVALS ---
[pred_te, ~, ci_te] = predict(gpr_mdl, X_te);

%% --- METRICS ---
RMSE_gpr = sqrt(mean((y_te-pred_te).^2));
MAE_gpr  = mean(abs(y_te-pred_te));
SS_res   = sum((y_te-pred_te).^2);
SS_tot   = sum((y_te-mean(y_te)).^2);
R2_gpr   = 1-SS_res/SS_tot;

fprintf('=== GPR PERFORMANCE ===\n');
fprintf('RMSE   : %.4f%%\n', RMSE_gpr);
fprintf('MAE    : %.4f%%\n', MAE_gpr);
fprintf('R²     : %.4f\n\n', R2_gpr);

%% --- FUTURE PREDICTION & RUL ---
n_future   = 300;
future_cyc = (sp_gpr+1:sp_gpr+n_future)';
X_future   = [future_cyc,...
    repmat(SOH_meas(end),n_future,1),...
    repmat(dSOH_g(end),n_future,1),...
    repmat(mSOH_g(end),n_future,1)];

[SOH_fut, ~, ci_fut] = predict(gpr_mdl, X_future);

EOL_th  = 80;
EOL_idx = find(SOH_fut<=EOL_th,1);

fprintf('=== RUL PREDICTION ===\n');
fprintf('Current SOH      : %.2f%%\n', SOH_meas(end));
fprintf('Current cycle    : %d\n', sp_gpr);
fprintf('EOL threshold    : %.0f%%\n', EOL_th);
if ~isempty(EOL_idx)
    fprintf('EOL at cycle     : %d\n', sp_gpr+EOL_idx);
    fprintf('Remaining cycles : %d\n', EOL_idx);
    fprintf('Remaining days   : %.0f (1 cycle/day)\n', EOL_idx);
    fprintf('Remaining months : %.1f\n\n', EOL_idx/30);
else
    fprintf('EOL not reached in forecast window\n\n');
end

%% --- PLOT ---
figure('Name','M10: GPR RUL Prediction',...
    'Color','white','Position',[50 50 1200 600]);

subplot(2,2,1);
plot(cyc_gpr(1:sp_gpr),SOH_meas(1:sp_gpr),'b.',...
    'MarkerSize',3,'DisplayName','Measured SOH'); hold on;
plot(cyc_gpr(sp_gpr+1:end),y_te,'g-',...
    'LineWidth',2,'DisplayName','True SOH');
plot(cyc_gpr(sp_gpr+1:end),pred_te,'r-',...
    'LineWidth',2,'DisplayName','GPR Predicted');
fill([cyc_gpr(sp_gpr+1:end);flipud(cyc_gpr(sp_gpr+1:end))],...
    [pred_te+ci_te(:,2);flipud(pred_te-ci_te(:,1))],...
    'red','FaceAlpha',0.15,'EdgeColor','none',...
    'DisplayName','95% Confidence');
yline(EOL_th,'k--','EOL Threshold','LineWidth',2);
xline(sp_gpr,'k:','Train|Test Split','LineWidth',1.5);
xlabel('Cycle'); ylabel('SOH (%)');
title('GPR SOH Prediction with 95% Confidence');
legend('Location','southwest'); grid on; set(gca,'FontSize',10);

subplot(2,2,2);
plot(future_cyc,SOH_fut,'r-','LineWidth',2,...
    'DisplayName','Predicted SOH'); hold on;
fill([future_cyc;flipud(future_cyc)],...
    [SOH_fut+ci_fut(:,2);flipud(SOH_fut-ci_fut(:,1))],...
    'red','FaceAlpha',0.15,'EdgeColor','none',...
    'DisplayName','95% Confidence');
yline(EOL_th,'k--','EOL (80%)','LineWidth',2);
if ~isempty(EOL_idx)
    xline(sp_gpr+EOL_idx,'b--',...
        sprintf('EOL @cycle %d',sp_gpr+EOL_idx),'LineWidth',1.5);
end
xlabel('Cycle'); ylabel('SOH (%)');
title(sprintf('RUL Forecast: %d cycles remaining',...
    EOL_idx));
legend('Location','northeast'); grid on; set(gca,'FontSize',10);

subplot(2,2,3);
err_gpr=y_te-pred_te;
plot(cyc_gpr(sp_gpr+1:end),err_gpr,'g-','LineWidth',1.5);
yline(0,'k-','LineWidth',1);
yline(RMSE_gpr,'r--',sprintf('RMSE=%.3f%%',RMSE_gpr),'LineWidth',1.5);
yline(-RMSE_gpr,'r--','LineWidth',1.5);
xlabel('Cycle'); ylabel('Error (%)');
title('GPR Prediction Error'); grid on; set(gca,'FontSize',10);

subplot(2,2,4);
scatter(y_te,pred_te,20,'filled',...
    'MarkerFaceColor','blue','MarkerFaceAlpha',0.6);
hold on;
lims=[min(y_te) max(y_te)];
plot(lims,lims,'r-','LineWidth',2);
xlabel('Actual SOH (%)'); ylabel('Predicted SOH (%)');
title(sprintf('Actual vs Predicted (R²=%.4f)',R2_gpr));
grid on; set(gca,'FontSize',10);

saveas(gcf,fullfile(output_folder,'M10_GPR_RUL_Prediction.png'));
save(fullfile(output_folder,'M10_gpr_model.mat'),'gpr_mdl');

fprintf('✔ Saved: M10_GPR_RUL_Prediction.png\n');
fprintf('✔ Saved: M10_gpr_model.mat\n');
fprintf('MODULE 10 COMPLETE!\n');

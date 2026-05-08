%% ============================================================
%  MODULE 11 — LSTM SOC PREDICTION (Deep Learning)
%  Long Short-Term Memory Neural Network
%  Project : Smart EV Battery Health & Fault Prediction System
%  Author  : [Your Name] | Tool: MATLAB 2025a
%  Requires: normal_condition.mat + Deep Learning Toolbox
%% ============================================================
clc; clear; close all;

output_folder = 'EV_Battery_Outputs';
if ~exist(output_folder,'dir'), mkdir(output_folder); end

fprintf('==========================================\n');
fprintf('   MODULE 11: LSTM SOC PREDICTION         \n');
fprintf('==========================================\n\n');

% Check Deep Learning Toolbox
if ~license('test','Neural_Network_Toolbox')
    error(['Deep Learning Toolbox not found!\n'...
        'Please install it from Add-Ons Manager.']);
end

load('normal_condition.mat');
t=t_normal; V=V_normal; I=I_normal; SOC=SOC_normal;

%% --- FEATURE ENGINEERING ---
% 6 features that capture battery dynamics
normalize_fn = @(x) (x-min(x))/(max(x)-min(x)+1e-10);

dV_f = gradient(V);       % Voltage rate of change
dI_f = gradient(I);       % Current rate of change
P_f  = V.*I;              % Instantaneous power
E_f  = cumtrapz(t,P_f);  % Cumulative energy

V_n  = normalize_fn(V);
I_n  = normalize_fn(I);
dV_n = normalize_fn(dV_f);
dI_n = normalize_fn(dI_f);
P_n  = normalize_fn(P_f);
E_n  = normalize_fn(E_f);

X_lstm = [V_n, I_n, dV_n, dI_n, P_n, E_n];  % [N x 6]
y_lstm = SOC;                                   % [N x 1]

fprintf('Feature Matrix : %d samples x %d features\n',...
    size(X_lstm,1), size(X_lstm,2));
fprintf('Features       : V, I, dV/dt, dI/dt, Power, Energy\n\n');

%% --- TRAIN/TEST SPLIT 80/20 ---
sp_lstm   = round(0.8*length(y_lstm));
X_tr_lstm = X_lstm(1:sp_lstm,:);
y_tr_lstm = y_lstm(1:sp_lstm);
X_te_lstm = X_lstm(sp_lstm+1:end,:);
y_te_lstm = y_lstm(sp_lstm+1:end);

fprintf('Training samples : %d\n', sp_lstm);
fprintf('Test samples     : %d\n', length(y_te_lstm));

%% --- DEFINE LSTM NETWORK ---
% 2-layer LSTM with dropout for regularization
numFeatures = 6;
numHidden1  = 64;
numHidden2  = 32;

layers = [
    sequenceInputLayer(numFeatures,'Name','input')
    lstmLayer(numHidden1,'OutputMode','sequence','Name','lstm1')
    dropoutLayer(0.2,'Name','dropout1')
    lstmLayer(numHidden2,'OutputMode','sequence','Name','lstm2')
    dropoutLayer(0.1,'Name','dropout2')
    fullyConnectedLayer(16,'Name','fc1')
    reluLayer('Name','relu1')
    fullyConnectedLayer(1,'Name','output')
    regressionLayer('Name','regression')
];

fprintf('\nNetwork Architecture:\n');
fprintf('  Input  : %d features\n', numFeatures);
fprintf('  LSTM1  : %d hidden units + Dropout 20%%\n', numHidden1);
fprintf('  LSTM2  : %d hidden units + Dropout 10%%\n', numHidden2);
fprintf('  FC     : 16 units + ReLU\n');
fprintf('  Output : 1 (SOC)\n\n');

%% --- TRAINING OPTIONS ---
options = trainingOptions('adam',...
    'MaxEpochs',50,...
    'MiniBatchSize',32,...
    'InitialLearnRate',0.001,...
    'LearnRateSchedule','piecewise',...
    'LearnRateDropFactor',0.5,...
    'LearnRateDropPeriod',20,...
    'GradientThreshold',1,...
    'Shuffle','never',...
    'ValidationData',{{X_te_lstm'},{y_te_lstm'}},...
    'ValidationFrequency',10,...
    'Plots','training-progress',...
    'Verbose',true);

%% --- TRAIN ---
fprintf('Training LSTM network (50 epochs)...\n');
fprintf('Training progress window will open...\n\n');
lstm_net = trainNetwork({X_tr_lstm'},{y_tr_lstm'},layers,options);
fprintf('\nTraining complete!\n\n');

%% --- PREDICT ---
pred_tr = lstm_net.predict({X_tr_lstm'});
pred_te = lstm_net.predict({X_te_lstm'});
pred_tr = pred_tr{1}';
pred_te = pred_te{1}';

%% --- METRICS ---
MAE_tr  = mean(abs(y_tr_lstm-pred_tr))*100;
RMSE_tr = sqrt(mean((y_tr_lstm-pred_tr).^2))*100;
MAE_te  = mean(abs(y_te_lstm-pred_te))*100;
RMSE_te = sqrt(mean((y_te_lstm-pred_te).^2))*100;
SS_res  = sum((y_te_lstm-pred_te).^2);
SS_tot  = sum((y_te_lstm-mean(y_te_lstm)).^2);
R2      = 1-SS_res/SS_tot;

fprintf('=== LSTM PERFORMANCE ===\n');
fprintf('%-20s %-12s %-12s\n','Set','MAE (%%)','RMSE (%%)');
fprintf('%s\n',repmat('-',1,44));
fprintf('%-20s %-12.4f %-12.4f\n','Training',MAE_tr,RMSE_tr);
fprintf('%-20s %-12.4f %-12.4f\n','Test',MAE_te,RMSE_te);
fprintf('%s\n',repmat('-',1,44));
fprintf('R² Score : %.4f\n\n', R2);

%% --- PLOT ---
figure('Name','M11: LSTM SOC Prediction',...
    'Color','white','Position',[50 50 1200 600]);

subplot(2,2,1);
plot(t,y_lstm*100,'b-','LineWidth',1.5,...
    'DisplayName','Actual SOC'); hold on;
plot(t(sp_lstm+1:end),pred_te*100,'r--',...
    'LineWidth',2,'DisplayName','LSTM Predicted');
xline(t(sp_lstm),'k:','Train|Test Split','LineWidth',1.5);
yline(20,'g--','Low SOC Warning','LineWidth',1);
xlabel('Time (s)'); ylabel('SOC (%)');
title('LSTM: Actual vs Predicted SOC');
legend('Location','southwest'); grid on; set(gca,'FontSize',10);

subplot(2,2,2);
err_lstm=(y_te_lstm-pred_te)*100;
plot(t(sp_lstm+1:end),err_lstm,'g-','LineWidth',1.5);
yline(0,'k-','LineWidth',1);
yline(1,'r--','±1% Error Band','LineWidth',1);
yline(-1,'r--','LineWidth',1);
xlabel('Time (s)'); ylabel('Error (%)');
title(sprintf('Prediction Error (MAE=%.3f%%)',MAE_te));
grid on; set(gca,'FontSize',10);

subplot(2,2,3);
scatter(y_te_lstm*100,pred_te*100,20,'filled',...
    'MarkerFaceColor','blue','MarkerFaceAlpha',0.5);
hold on;
lims=[min(y_te_lstm) max(y_te_lstm)]*100;
plot(lims,lims,'r-','LineWidth',2,'DisplayName','Perfect Prediction');
xlabel('Actual SOC (%)'); ylabel('Predicted SOC (%)');
title(sprintf('Actual vs Predicted (R²=%.4f)',R2));
legend('Location','southeast'); grid on; set(gca,'FontSize',10);

subplot(2,2,4);
histogram(err_lstm,30,'FaceColor','blue',...
    'EdgeColor','white','FaceAlpha',0.7);
xline(0,'r-','LineWidth',2);
xline(MAE_te,'g--',sprintf('MAE=%.3f%%',MAE_te),'LineWidth',1.5);
xline(-MAE_te,'g--','LineWidth',1.5);
xlabel('Prediction Error (%)'); ylabel('Frequency');
title('Error Distribution');
grid on; set(gca,'FontSize',10);

saveas(gcf,fullfile(output_folder,'M11_LSTM_SOC_Prediction.png'));
save(fullfile(output_folder,'M11_lstm_model.mat'),'lstm_net');

fprintf('✔ Saved: M11_LSTM_SOC_Prediction.png\n');
fprintf('✔ Saved: M11_lstm_model.mat\n');
fprintf('MODULE 11 COMPLETE!\n');

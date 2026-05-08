%% ============================================================
%  MODULE 12 — AUTOENCODER ANOMALY DETECTION
%  Unsupervised Deep Learning for Unknown Fault Detection
%  Project : Smart EV Battery Health & Fault Prediction System
%  Author  : [Your Name] | Tool: MATLAB 2025a
%  Requires: normal_condition.mat + Deep Learning Toolbox
%% ============================================================
clc; clear; close all;

output_folder = 'EV_Battery_Outputs';
if ~exist(output_folder,'dir'), mkdir(output_folder); end

fprintf('==========================================\n');
fprintf('   MODULE 12: AUTOENCODER ANOMALY DETECT  \n');
fprintf('==========================================\n\n');

load('normal_condition.mat');
t=t_normal; V=V_normal; I=I_normal;

%% --- FEATURE PREPARATION ---
normalize_fn = @(x) (x-min(x))/(max(x)-min(x)+1e-10);

X_ae = [normalize_fn(V),...
        normalize_fn(I),...
        normalize_fn(gradient(V)),...
        normalize_fn(gradient(I))];

fprintf('Feature matrix : %d samples x %d features\n\n',...
    size(X_ae,1),size(X_ae,2));

%% --- TRAIN AUTOENCODER ON NORMAL DATA ONLY ---
% Autoencoder learns to reconstruct NORMAL patterns
% Faults = high reconstruction error (cannot reconstruct)
fprintf('Training Autoencoder on normal data only...\n');
fprintf('(Learns normal battery signature)\n\n');

hiddenSize = 2;  % Compress to 2-D latent space

autoenc = trainAutoencoder(X_ae',...
    hiddenSize,...
    'MaxEpochs',200,...
    'L2WeightRegularization',0.001,...
    'SparsityRegularization',4,...
    'SparsityProportion',0.05,...
    'ScaleData',false);

%% --- RECONSTRUCTION ERROR ON NORMAL DATA ---
X_recon_n  = predict(autoenc, X_ae');
err_normal = mean((X_ae' - X_recon_n).^2, 1)';

% Anomaly threshold: 99th percentile of normal errors
threshold  = prctile(err_normal, 99);
fprintf('Anomaly threshold (99th pct): %.6f\n\n', threshold);

%% --- CREATE FAULTY DATA ---
% Fault 1: Voltage drop
V_f1 = V; V_f1(1800:end) = V_f1(1800:end) - 0.15;

% Fault 2: Overcurrent
I_f2 = I; I_f2(2200:2400) = I_f2(2200:2400)*3.5;

% Fault 3: Combined fault
V_f3 = V; V_f3(2500:end) = V_f3(2500:end) - 0.10;
I_f3 = I; I_f3(2500:end) = I_f3(2500:end)*1.8;

% Build fault feature matrices
X_f1 = [normalize_fn(V_f1), normalize_fn(I),...
         normalize_fn(gradient(V_f1)), normalize_fn(gradient(I))];
X_f2 = [normalize_fn(V), normalize_fn(I_f2),...
         normalize_fn(gradient(V)), normalize_fn(gradient(I_f2))];
X_f3 = [normalize_fn(V_f3), normalize_fn(I_f3),...
         normalize_fn(gradient(V_f3)), normalize_fn(gradient(I_f3))];

%% --- RECONSTRUCTION ERROR ON FAULT DATA ---
X_f1_recon = predict(autoenc, X_f1');
X_f2_recon = predict(autoenc, X_f2');
X_f3_recon = predict(autoenc, X_f3');

err_f1 = mean((X_f1' - X_f1_recon).^2, 1)';
err_f2 = mean((X_f2' - X_f2_recon).^2, 1)';
err_f3 = mean((X_f3' - X_f3_recon).^2, 1)';

% Detect anomalies
anom_f1 = err_f1 > threshold;
anom_f2 = err_f2 > threshold;
anom_f3 = err_f3 > threshold;

fprintf('=== ANOMALY DETECTION RESULTS ===\n');
fprintf('Fault 1 (Voltage Drop)   : %d anomalies detected\n', sum(anom_f1));
if any(anom_f1)
    fprintf('  First detected at t = %.0f s\n', t(find(anom_f1,1)));
end
fprintf('Fault 2 (Overcurrent)    : %d anomalies detected\n', sum(anom_f2));
if any(anom_f2)
    fprintf('  First detected at t = %.0f s\n', t(find(anom_f2,1)));
end
fprintf('Fault 3 (Combined)       : %d anomalies detected\n', sum(anom_f3));
if any(anom_f3)
    fprintf('  First detected at t = %.0f s\n', t(find(anom_f3,1)));
end
fprintf('==================================\n\n');

%% --- LATENT SPACE ---
encoded_n  = encode(autoenc, X_ae');
encoded_f1 = encode(autoenc, X_f1');
encoded_f2 = encode(autoenc, X_f2');

%% --- PLOT ---
figure('Name','M12: Autoencoder Anomaly Detection',...
    'Color','white','Position',[50 50 1300 600]);

subplot(2,3,1);
plot(t,err_normal,'b-','LineWidth',1,'DisplayName','Normal'); hold on;
plot(t,err_f1,'r-','LineWidth',1,'DisplayName','Voltage Fault');
yline(threshold,'k--','Anomaly Threshold','LineWidth',2);
xlabel('Time (s)'); ylabel('Reconstruction Error');
title('Fault 1: Voltage Drop Detection');
legend('Location','northwest'); grid on; set(gca,'FontSize',10);

subplot(2,3,2);
plot(t,err_normal,'b-','LineWidth',1,'DisplayName','Normal'); hold on;
plot(t,err_f2,'r-','LineWidth',1,'DisplayName','Overcurrent Fault');
yline(threshold,'k--','Anomaly Threshold','LineWidth',2);
xlabel('Time (s)'); ylabel('Reconstruction Error');
title('Fault 2: Overcurrent Detection');
legend('Location','northwest'); grid on; set(gca,'FontSize',10);

subplot(2,3,3);
plot(t,err_normal,'b-','LineWidth',1,'DisplayName','Normal'); hold on;
plot(t,err_f3,'r-','LineWidth',1,'DisplayName','Combined Fault');
yline(threshold,'k--','Anomaly Threshold','LineWidth',2);
xlabel('Time (s)'); ylabel('Reconstruction Error');
title('Fault 3: Combined Fault Detection');
legend('Location','northwest'); grid on; set(gca,'FontSize',10);

subplot(2,3,4);
area(t,double(anom_f1),'FaceColor','red','FaceAlpha',0.6,...
    'DisplayName','Fault 1'); hold on;
area(t,double(anom_f2)*0.8,'FaceColor','orange','FaceAlpha',0.6,...
    'DisplayName','Fault 2');
area(t,double(anom_f3)*0.6,'FaceColor','yellow','FaceAlpha',0.6,...
    'DisplayName','Fault 3');
xlabel('Time (s)'); ylabel('Anomaly Flag');
title('Anomaly Timeline — All Faults');
legend; grid on; set(gca,'FontSize',10);

subplot(2,3,5);
scatter(encoded_n(1,:),encoded_n(2,:),5,...
    'blue','filled','MarkerFaceAlpha',0.3,...
    'DisplayName','Normal'); hold on;
scatter(encoded_f1(1,:),encoded_f1(2,:),5,...
    'red','filled','MarkerFaceAlpha',0.3,...
    'DisplayName','Fault 1');
scatter(encoded_f2(1,:),encoded_f2(2,:),5,...
    'green','filled','MarkerFaceAlpha',0.3,...
    'DisplayName','Fault 2');
xlabel('Latent Dim 1'); ylabel('Latent Dim 2');
title('2D Latent Space Visualization');
legend; grid on; set(gca,'FontSize',10);

subplot(2,3,6);
detection_pct=[sum(anom_f1)/length(t)*100,...
               sum(anom_f2)/length(t)*100,...
               sum(anom_f3)/length(t)*100];
b=bar(categorical({'Volt Fault','Overcurrent','Combined'}),...
    detection_pct,'FaceColor','flat');
b.CData=[0.9 0.2 0.2;1 0.5 0;0.9 0.7 0.1];
ylabel('Detected Anomaly (%)');
title('Anomaly Detection Rate per Fault Type');
grid on; set(gca,'FontSize',10);

saveas(gcf,fullfile(output_folder,'M12_Autoencoder_Anomaly.png'));
save(fullfile(output_folder,'M12_autoencoder.mat'),'autoenc');

fprintf('✔ Saved: M12_Autoencoder_Anomaly.png\n');
fprintf('✔ Saved: M12_autoencoder.mat\n');
fprintf('MODULE 12 COMPLETE!\n');

%% ============================================================
%  MODULE 09 — ML FAULT CLASSIFICATION
%  Decision Tree + SVM + Random Forest Comparison
%  Project : Smart EV Battery Health & Fault Prediction System
%  Author  : [Your Name] | Tool: MATLAB 2025a
%  Requires: normal_condition.mat
%% ============================================================
clc; clear; close all;

output_folder = 'EV_Battery_Outputs';
if ~exist(output_folder,'dir'), mkdir(output_folder); end

fprintf('==========================================\n');
fprintf('   MODULE 09: ML FAULT CLASSIFICATION     \n');
fprintf('==========================================\n\n');

load('normal_condition.mat');
t=t_normal; V=V_normal; I=I_normal;

%% --- BUILD 4-CLASS DATASET ---
dV=gradient(V); dI=gradient(I);
X0=[V,I,dV,dI,V.*I]; y0=zeros(length(t),1);       % Normal
V1=V+0.3;
X1=[V1,I,gradient(V1),dI,V1.*I]; y1=ones(length(t),1); % Overvoltage
I2=I*4;
X2=[V,I2,dV,gradient(I2),V.*I2]; y2=2*ones(length(t),1); % Overcurrent
V3=V*0.92; I3=I*0.88;
X3=[V3,I3,gradient(V3),gradient(I3),V3.*I3]; y3=3*ones(length(t),1); % CapFade

idx=1:10:length(t);
X_all=[X0(idx,:);X1(idx,:);X2(idx,:);X3(idx,:)];
y_all=[y0(idx);y1(idx);y2(idx);y3(idx)];

rng(42); perm=randperm(length(y_all));
X_all=X_all(perm,:); y_all=y_all(perm);

sp=round(0.8*length(y_all));
X_tr=X_all(1:sp,:); y_tr=y_all(1:sp);
X_te=X_all(sp+1:end,:); y_te=y_all(sp+1:end);

fprintf('Total samples    : %d\n', length(y_all));
fprintf('Training samples : %d\n', sp);
fprintf('Test samples     : %d\n', length(y_te));
fprintf('Features         : V, I, dV/dt, dI/dt, Power\n\n');

%% --- DECISION TREE ---
fprintf('Training Decision Tree...\n');
dt_mdl=fitctree(X_tr,y_tr,'MaxNumSplits',20);
y_dt=predict(dt_mdl,X_te);
acc_dt=sum(y_dt==y_te)/length(y_te)*100;
cv_dt=crossval(dt_mdl,'KFold',5);
cv_acc_dt=(1-kfoldLoss(cv_dt))*100;

%% --- SVM ---
fprintf('Training SVM...\n');
svm_mdl=fitcecoc(X_tr,y_tr,...
    'Learners',templateSVM('KernelFunction','rbf','KernelScale','auto'));
y_svm=predict(svm_mdl,X_te);
acc_svm=sum(y_svm==y_te)/length(y_te)*100;

%% --- RANDOM FOREST ---
fprintf('Training Random Forest (50 trees)...\n');
rf_mdl=TreeBagger(50,X_tr,y_tr,'Method','classification','MinLeafSize',5);
y_rf=str2double(predict(rf_mdl,X_te));
acc_rf=sum(y_rf==y_te)/length(y_te)*100;

fprintf('\n=== RESULTS ===\n');
fprintf('Decision Tree  : %.2f%% (CV: %.2f%%)\n',acc_dt,cv_acc_dt);
fprintf('SVM (RBF)      : %.2f%%\n',acc_svm);
fprintf('Random Forest  : %.2f%%\n',acc_rf);
fprintf('Best Model     : %.2f%%\n\n',max([acc_dt,acc_svm,acc_rf]));

imp=dt_mdl.predictorImportance;
feat_names={'Voltage','Current','dV/dt','dI/dt','Power'};
fprintf('Feature Importance:\n');
for i=1:5
    fprintf('  %-12s: %.4f\n',feat_names{i},imp(i));
end

%% --- PLOT ---
class_names={'Normal','Overvoltage','Overcurrent','CapFade'};
figure('Name','M09: ML Fault Classification',...
    'Color','white','Position',[50 50 1400 500]);

subplot(1,4,1);
confusionchart(confusionmat(y_te,y_dt),class_names,...
    'Title',sprintf('Decision Tree\n%.1f%%',acc_dt),...
    'RowSummary','row-normalized');

subplot(1,4,2);
confusionchart(confusionmat(y_te,y_svm),class_names,...
    'Title',sprintf('SVM (RBF)\n%.1f%%',acc_svm),...
    'RowSummary','row-normalized');

subplot(1,4,3);
confusionchart(confusionmat(y_te,y_rf),class_names,...
    'Title',sprintf('Random Forest\n%.1f%%',acc_rf),...
    'RowSummary','row-normalized');

subplot(1,4,4);
bar(categorical(feat_names),imp,'FaceColor',[0.3 0.6 0.9]);
ylabel('Importance Score');
title('Feature Importance (DT)');
grid on; set(gca,'FontSize',9);

saveas(gcf,fullfile(output_folder,'M09_ML_Fault_Classification.png'));
save(fullfile(output_folder,'M09_dt_model.mat'),'dt_mdl');
save(fullfile(output_folder,'M09_svm_model.mat'),'svm_mdl');
save(fullfile(output_folder,'M09_rf_model.mat'),'rf_mdl');

fprintf('✔ Saved: M09_ML_Fault_Classification.png\n');
fprintf('✔ Saved: ML models to EV_Battery_Outputs/\n');
fprintf('MODULE 09 COMPLETE!\n');

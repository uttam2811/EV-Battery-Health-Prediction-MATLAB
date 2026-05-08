# 🔋 Smart EV Battery Health & Fault Prediction System

![MATLAB](https://img.shields.io/badge/MATLAB-2025a-orange)
![Simscape](https://img.shields.io/badge/Simscape-Battery-blue)
![AI/ML](https://img.shields.io/badge/AI%2FML-LSTM%20%7C%20GPR%20%7C%20SVM%20%7C%20RF-green)
![License](https://img.shields.io/badge/License-MIT-yellow)

## 📌 Project Overview

A complete **Battery Management System (BMS) simulation** built in 
MATLAB 2025a, combining physics-based modelling with AI/ML for 
real-time battery health monitoring, fault detection, and 
remaining useful life prediction.

This project simulates the kind of BMS used in electric vehicles 
like Tata Nexon EV and similar NMC pouch cell packs.

---

## ⚡ Key Results

| Metric | Value |
|--------|-------|
| Pack Configuration | 96S4P NMC Pouch |
| Pack Voltage | 355.2 V |
| Pack Energy | 7.1 kWh |
| Total Cells | 384 |
| Normal SOH | 93.27% |
| Fault SOH | 87.02% |
| Fault Detected | Overcurrent @ t=2200s |
| LSTM R² Score | >0.999 |
| Random Forest Accuracy | >95% |
| GPR RMSE | <0.05% |

---

## 🏗️ Project Architecture
Battery Builder (96S4P Pack Design)
↓
Simulink + Simscape Electrical
↓
Adaptive Kalman Filter (SOC)
↓
Fault Injection & Detection
↓
AI/ML Layer:
├── LSTM          → SOC Prediction
├── Autoencoder   → Anomaly Detection
├── GPR           → RUL Prediction
├── SVM           → Fault Classification
└── Random Forest → Fault Classification
↓
ISO 26262 ASIL Fault Rating

---

## 🛠️ Tools & Technologies

- **MATLAB 2025a** — Core platform
- **Simscape Electrical** — Circuit simulation
- **Simscape Battery** — Battery Builder pack design
- **Deep Learning Toolbox** — LSTM + Autoencoder
- **Statistics & ML Toolbox** — SVM + GPR + Random Forest
- **Simulink** — System simulation

---

## 📊 Output Plots

### Normal Condition Dashboard
![Normal](outputs/M02_Normal_Simulation.png)

### Fault Detection Dashboard
![Fault](outputs/M04_Fault_Detection.png)

### Cell Imbalance Detection
![Imbalance](outputs/M05_Cell_Imbalance.png)

### ML Fault Classification
![ML](outputs/M09_ML_Fault_Classification.png)

### GPR RUL Prediction
![GPR](outputs/M10_GPR_RUL_Prediction.png)

---

## 📁 Project Structure
├── simulink/          # Simulink .slx model
├── data/              # Simulation output data
├── scripts/           # All MATLAB scripts (M01-M13)
├── outputs/           # All generated plots
├── report/            # Project report PDF
└── README.md

---

## 🚀 How to Run

1. Clone this repository
```bash
git clone https://github.com/YOUR_USERNAME/EV-Battery-Health-Prediction-MATLAB.git
```

2. Open MATLAB 2025a

3. Navigate to the project folder

4. Run the master script:
```matlab
run('scripts/MASTER_EV_Battery_System.m')
```

5. All outputs will be saved to `EV_Battery_Outputs/` automatically

---

## 📋 Module Description

| Module | File | Description |
|--------|------|-------------|
| M01 | M01_BatteryPack_Specification.m | Pack spec, C-rate analysis |
| M02 | M02_Normal_Simulation.m | Normal condition plots |
| M03 | M03_Drive_Cycle.m | UDDS drive cycle + regen |
| M04 | M04_Fault_Detection.m | Fault injection + SOH + RUL |
| M05 | M05_Cell_Imbalance.m | 96-cell imbalance detection |
| M06 | M06_Temperature_Analysis.m | Temperature effects |
| M07 | M07_Aging_Model.m | Capacity fade model |
| M08 | M08_SOC_Comparison.m | Kalman vs Coulomb counting |
| M09 | M09_ML_Fault_Classification.m | DT + SVM + Random Forest |
| M10 | M10_GPR_RUL_Prediction.m | GPR with confidence intervals |
| M11 | M11_LSTM_SOC_Prediction.m | Deep Learning SOC prediction |
| M12 | M12_Autoencoder_Anomaly.m | Unsupervised anomaly detection |
| M13 | M13_Final_Report_Export.m | Full CSV data export |

---

## 🔍 Technical Highlights

- **Battery Pack Design**: 96S4P NMC pouch cell pack manually
  designed in MATLAB Battery Builder with RC2 equivalent circuit,
  aging model (OCV + capacity fade), and thermal port enabled

- **SOC Estimation**: Adaptive Kalman Filter implemented via
  Pack Bar SOC Estimator block — superior to Coulomb counting
  due to noise rejection and self-correction

- **Fault Detection**: Three fault types injected — voltage drop
  (cell short circuit), overcurrent (acceleration demand), and
  SOC anomaly — detected using threshold-based logic with
  ISO 26262 ASIL classification

- **AI/ML Models**: Five models trained — LSTM for time-series
  SOC prediction, Autoencoder for unsupervised anomaly detection,
  Gaussian Process Regression for RUL with uncertainty bounds,
  SVM and Random Forest for multi-class fault classification

- **RUL Prediction**: GPR model predicts remaining useful life
  with 95% confidence interval using cycle number, SOH, rate of
  SOH change, and moving average SOH as features

---

## 👤 Author

Uttam M
uttamkrishnan3578@gmail.com
https://www.linkedin.com/in/uttam-krishnan/  

---

## 📄 License

This project is licensed under the MIT License.


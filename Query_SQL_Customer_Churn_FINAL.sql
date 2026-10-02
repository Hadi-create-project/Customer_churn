-- ==========================================
-- TAHAP 1: PENGECEKAN (PREVIEW)
-- ==========================================
-- (Ditambahkan fungsi CAST agar aman di-run berulang kali meski tipe data sudah berubah)

-- 1. Mencari pelanggan yang TotalCharges-nya kosong/spasi
SELECT 
  customerID, 
  tenure, 
  MonthlyCharges, 
  TotalCharges
FROM 
  `telco.telcomunication`
WHERE 
  TRIM(CAST(TotalCharges AS STRING)) = '';

-- 2. Simulasi perbandingan total charges sebelum diubah
SELECT 
  customerID,
  tenure,
  MonthlyCharges,
  TotalCharges AS TotalCharges_Kotor,
  COALESCE(SAFE_CAST(TRIM(CAST(TotalCharges AS STRING)) AS FLOAT64), 0.0) AS TotalCharges_Bersih
FROM 
  `telco.telcomunication`
WHERE 
  TRIM(CAST(TotalCharges AS STRING)) = ''
LIMIT 20;


-- ==========================================
-- TAHAP 2: DATA CLEANING (EKSEKUSI)
-- ==========================================
-- 1. Menghapus duplikat
CREATE OR REPLACE TABLE `telco.telcomunication` AS
SELECT * 
FROM `telco.telcomunication`
QUALIFY ROW_NUMBER() OVER(PARTITION BY customerID ORDER BY customerID) = 1;

-- 2. Perubahan string jadi float pada totalcharges
CREATE OR REPLACE TABLE `telco.telcomunication` AS
SELECT 
  * EXCEPT(TotalCharges),
  COALESCE(SAFE_CAST(TRIM(CAST(TotalCharges AS STRING)) AS FLOAT64), 0.0) AS TotalCharges
FROM `telco.telcomunication`;

-- 3. Merapihkan data kategori (senior citizen, no phone service, dan no di 6 layanan)
CREATE OR REPLACE TABLE `telco.telcomunication` AS
SELECT
  * EXCEPT(SeniorCitizen, MultipleLines, OnlineSecurity, OnlineBackup, DeviceProtection, TechSupport, StreamingTV, StreamingMovies),
  CASE WHEN CAST(SeniorCitizen AS STRING) IN ('1','Yes') THEN 'Yes' ELSE 'No' END AS SeniorCitizen,  -- FIX: idempotent, aman di-run berulang
  CASE WHEN MultipleLines = 'No phone service' THEN 'No' ELSE MultipleLines END AS MultipleLines,
  CASE WHEN OnlineSecurity = 'No internet service' THEN 'No' ELSE OnlineSecurity END AS OnlineSecurity,
  CASE WHEN OnlineBackup = 'No internet service' THEN 'No' ELSE OnlineBackup END AS OnlineBackup,
  CASE WHEN DeviceProtection = 'No internet service' THEN 'No' ELSE DeviceProtection END AS DeviceProtection,
  CASE WHEN TechSupport = 'No internet service' THEN 'No' ELSE TechSupport END AS TechSupport,
  CASE WHEN StreamingTV = 'No internet service' THEN 'No' ELSE StreamingTV END AS StreamingTV,
  CASE WHEN StreamingMovies = 'No internet service' THEN 'No' ELSE StreamingMovies END AS StreamingMovies
FROM `telco.telcomunication`;

-- 4. Mengembalikan nilai boolean menjadi String Yes/No
CREATE OR REPLACE TABLE `telco.telcomunication` AS
SELECT
  * EXCEPT(Partner, Dependents, PhoneService, PaperlessBilling, Churn),
  CASE WHEN CAST(Partner AS STRING) IN ('true', 'True', 'TRUE') THEN 'Yes' WHEN CAST(Partner AS STRING) IN ('false', 'False', 'FALSE') THEN 'No' ELSE CAST(Partner AS STRING) END AS Partner,
  CASE WHEN CAST(Dependents AS STRING) IN ('true', 'True', 'TRUE') THEN 'Yes' WHEN CAST(Dependents AS STRING) IN ('false', 'False', 'FALSE') THEN 'No' ELSE CAST(Dependents AS STRING) END AS Dependents,
  CASE WHEN CAST(PhoneService AS STRING) IN ('true', 'True', 'TRUE') THEN 'Yes' WHEN CAST(PhoneService AS STRING) IN ('false', 'False', 'FALSE') THEN 'No' ELSE CAST(PhoneService AS STRING) END AS PhoneService,
  CASE WHEN CAST(PaperlessBilling AS STRING) IN ('true', 'True', 'TRUE') THEN 'Yes' WHEN CAST(PaperlessBilling AS STRING) IN ('false', 'False', 'FALSE') THEN 'No' ELSE CAST(PaperlessBilling AS STRING) END AS PaperlessBilling,
  CASE WHEN CAST(Churn AS STRING) IN ('true', 'True', 'TRUE') THEN 'Yes' WHEN CAST(Churn AS STRING) IN ('false', 'False', 'FALSE') THEN 'No' ELSE CAST(Churn AS STRING) END AS Churn
FROM `telco.telcomunication`;


-- ==========================================
-- TAHAP 3: FEATURE ENGINEERING
-- ==========================================
CREATE OR REPLACE TABLE `telco.telcomunication` AS
SELECT 
  *, 
  
  -- Segmentasi Tenure
  CASE 
    WHEN tenure <= 12 THEN '1. 0-12 Bulan (Baru)'
    WHEN tenure <= 24 THEN '2. 13-24 Bulan'
    WHEN tenure <= 48 THEN '3. 25-48 Bulan'
    WHEN tenure <= 60 THEN '4. 49-60 Bulan'
    ELSE '5. > 60 Bulan (Sangat Loyal)'
  END AS TenureGroup,
  
  -- Segmentasi Tagihan
  CASE 
    WHEN MonthlyCharges < 35.0 THEN 'Low Value'
    WHEN MonthlyCharges >= 35.0 AND MonthlyCharges < 70.0 THEN 'Medium Value'
    ELSE 'High Value'
  END AS ChargeSegment,
  
  -- Flag Autopay
  CASE 
    WHEN PaymentMethod LIKE '%(automatic)%' THEN 'Auto Pay'
    ELSE 'Manual Pay'
  END AS AutoPayFlag,
  
  -- Menghitung total add-ons
  (
    (CASE WHEN OnlineSecurity = 'Yes' THEN 1 ELSE 0 END) +
    (CASE WHEN OnlineBackup = 'Yes' THEN 1 ELSE 0 END) +
    (CASE WHEN DeviceProtection = 'Yes' THEN 1 ELSE 0 END) +
    (CASE WHEN TechSupport = 'Yes' THEN 1 ELSE 0 END) +
    (CASE WHEN StreamingTV = 'Yes' THEN 1 ELSE 0 END) +
    (CASE WHEN StreamingMovies = 'Yes' THEN 1 ELSE 0 END)
  ) AS TotalAddOns,

  -- Bundle Pelindung
  CASE 
    WHEN OnlineSecurity = 'Yes' OR TechSupport = 'Yes' THEN 'Yes' 
    ELSE 'No' 
  END AS HasProtectionBundle,

  -- Churn Flag Numerik untuk mempermudah perhitungan rata-rata
  CASE 
    WHEN Churn = 'Yes' THEN 1 
    ELSE 0 
  END AS ChurnFlag,

  -- Validasi Logika Biaya (Anomali)
  CASE 
    WHEN tenure > 0 AND ABS(TotalCharges - (tenure * MonthlyCharges)) > 50 THEN 'Anomali'
    ELSE 'Normal'
  END AS ChargeLogicValidation

FROM `telco.telcomunication`;

-- Mengecek jumlah anomali
SELECT ChargeLogicValidation, COUNT(*) AS Jumlah, ROUND(COUNT(*)*100.0/SUM(COUNT(*)) OVER(),2) AS Pct
FROM `telco.telcomunication`
GROUP BY ChargeLogicValidation;


-- ==========================================
-- TAHAP 4: EDA (MACRO OVERVIEW & BIVARIATE)
-- ==========================================
-- (Query EDA sudah dioptimasi menggunakan kolom `ChurnFlag` agar lebih singkat dan cepat)

-- 1. Churn Rate & Revenue at Risk (Overview)
SELECT 
  COUNT(customerID) AS Total_Customers,
  SUM(ChurnFlag) AS Total_Churn,
  ROUND(AVG(ChurnFlag) * 100, 2) AS Churn_Rate_Pct,
  ROUND(SUM(TotalCharges), 2) AS Total_Revenue,
  ROUND(SUM(CASE WHEN ChurnFlag = 1 THEN TotalCharges ELSE 0 END), 2) AS Revenue_At_Risk
FROM `telco.telcomunication`;

-- 2. Mengidentifikasi Segmen Kontrak Paling Berisiko
SELECT 
  TenureGroup,
  Contract,
  COUNT(*) AS Total_Customers,
  SUM(ChurnFlag) AS Total_Churn,
  ROUND(AVG(ChurnFlag) * 100, 2) AS Churn_Rate_Pct
FROM `telco.telcomunication`
GROUP BY TenureGroup, Contract
ORDER BY Total_Churn DESC;

-- 3. Bivariate Core Analysis: Berdasarkan Layanan Internet & Fitur Pelindung
SELECT 
  InternetService,
  HasProtectionBundle,
  COUNT(customerID) AS Cust_Count,
  ROUND(AVG(ChurnFlag) * 100, 2) AS Churn_Rate_Pct
FROM `telco.telcomunication`
GROUP BY InternetService, HasProtectionBundle
ORDER BY Churn_Rate_Pct DESC;

-- 4. Multivariate: Menemukan Kombinasi Segmen Paling Rentan
SELECT 
  TenureGroup,
  Contract,
  InternetService,
  COUNT(customerID) AS Total_Cust,
  SUM(ChurnFlag) AS Churn_Cust,
  ROUND(AVG(ChurnFlag) * 100, 2) AS Churn_Rate_Pct
FROM `telco.telcomunication`
GROUP BY TenureGroup, Contract, InternetService
HAVING Total_Cust > 50 -- Mengabaikan segmen yang datanya terlalu sedikit agar analisis tetap relevan
ORDER BY Churn_Rate_Pct DESC
LIMIT 10;

-- 5. Analisis Nilai Bisnis (Prinsip Pareto) - Menghitung % Kerugian dari Total
SELECT 
  ChargeSegment,
  SUM(ChurnFlag) AS Total_Churn_Cust,
  ROUND(SUM(CASE WHEN ChurnFlag = 1 THEN TotalCharges ELSE 0 END), 2) AS Revenue_Lost,
  ROUND(SUM(CASE WHEN ChurnFlag = 1 THEN TotalCharges ELSE 0 END) / 
        SUM(SUM(CASE WHEN ChurnFlag = 1 THEN TotalCharges ELSE 0 END)) OVER() * 100, 2) AS Pct_of_Total_Loss
FROM `telco.telcomunication`
GROUP BY ChargeSegment
ORDER BY Revenue_Lost DESC;

select * from `telco.telcomunication`


-- ==========================================
-- TAHAP 5: REVENUE AT RISK (VERSI DIPERBAIKI)
-- ==========================================
-- Revisi dari Tahap 4 Query 1: 'Revenue_At_Risk' sebelumnya memakai SUM(TotalCharges),
-- yaitu akumulasi tagihan HISTORIS, bukan pendapatan berulang ke depan.
-- Query di bawah menghasilkan basis yang benar untuk proyeksi bulanan/tahunan,
-- selaras dengan measure DAX 'MRR at Risk' / 'ARR at Risk' / 'Saved ARR (10%)' di Power BI.

SELECT
  ROUND(SUM(CASE WHEN ChurnFlag = 1 THEN TotalCharges ELSE 0 END), 2) AS Historical_Revenue_Lost,
  ROUND(SUM(CASE WHEN ChurnFlag = 1 THEN MonthlyCharges ELSE 0 END), 2) AS Monthly_Revenue_At_Risk,
  ROUND(SUM(CASE WHEN ChurnFlag = 1 THEN MonthlyCharges ELSE 0 END) * 12, 2) AS Annual_Revenue_At_Risk,
  ROUND(SUM(CASE WHEN ChurnFlag = 1 THEN MonthlyCharges ELSE 0 END) * 0.10, 2) AS Saved_MRR_10pct,
  ROUND(SUM(CASE WHEN ChurnFlag = 1 THEN MonthlyCharges ELSE 0 END) * 12 * 0.10, 2) AS Saved_ARR_10pct
FROM `telco.telcomunication`;

-- Hasil pada dataset ini (7.043 pelanggan, 1.869 churn), diverifikasi dari file Power BI:
--   Historical Revenue Lost : $2.862.926,90   (basis lama, dipakai KPI card "Revenue at Risk")
--   Monthly Revenue At Risk : $139.130,85      (= DAX measure 'MRR at Risk')
--   Annual Revenue At Risk  : $1.669.570,20    (= DAX measure 'ARR at Risk')
--   Saved MRR (10% retensi) : $13.913,08       (= DAX measure 'Saved MRR (10%)')
--   Saved ARR (10% retensi) : $166.957,02      (= DAX measure 'Saved ARR (10%)', dipakai kartu
--                                                 "Proyeksi Pendapatan Tahunan Diselamatkan")

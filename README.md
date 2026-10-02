# 📉 Telco Customer Churn: End-to-End Predictive Analytics & Retention Strategy

![SQL](https://img.shields.io/badge/SQL-BigQuery-blue) ![Python](https://img.shields.io/badge/Python-XGBoost-yellow) ![Power BI](https://img.shields.io/badge/Power_BI-Dashboard-yellowgreen)

**PDF Dashboard:** [Lihat Ekspor PDF](./Telco_Churn_Dashboard.pdf) *(Berfungsi jika reviewer tidak memiliki akses Power BI)*

---

## 📖 1. Business Overview
Di industri telekomunikasi (model bisnis berlangganan), biaya untuk mengakuisisi pelanggan baru 5 hingga 25 kali lebih mahal dibandingkan mempertahankan pelanggan lama. 

**Problem Statement:** Perusahaan kehilangan sebagian pelanggannya setiap bulan (Churn), yang mengancam *Monthly Recurring Revenue* (MRR).
**Objective:** Mengidentifikasi segmen pelanggan berisiko tinggi, membangun model prediksi *Machine Learning* untuk menemukan penggerak utama (*key drivers*), dan merumuskan strategi retensi yang didukung oleh estimasi proyeksi finansial.

![Dashboard Overview](./dashboard_overview.png) *(Ganti path gambar dengan hasil screenshot Halaman 1 Power BI Anda)*

---

## 🗂️ 2. Dataset
Karena ukuran file data cukup besar, data mentah tidak disertakan secara langsung di repositori ini. 
* **Sumber Data:** [Telco Customer Churn Dataset (Kaggle) - Blastchar](https://www.kaggle.com/datasets/blastchar/telco-customer-churn) 
* **Detail Data:** Terdiri dari 7.043 baris pelanggan dan 21 atribut yang mencakup data demografi, layanan langganan, dan informasi tagihan (Billing).

---

## 🛠️ 3. Methodology & Workflow
Proyek ini dikerjakan secara *end-to-end* menggunakan pendekatan sains data. Klik pada tautan di bawah ini untuk melihat *script* atau kode sumber dari masing-masing tahapan:

### A. Data Engineering & Preprocessing (SQL / BigQuery)
* **[🔍 Lihat Script Data Cleaning](./01_data_cleaning.sql)**: Standarisasi tipe data, penanganan nilai kosong (*missing values*), dan implementasi *idempotent query* (contohnya pada kolom `SeniorCitizen`) agar *pipeline* aman dijalankan berulang kali.
* **[⚙️ Lihat Script Feature Engineering](./02_feature_engineering.sql)**: Pembuatan kolom analitik baru seperti `TenureGroup` (pengelompokan umur pelanggan), status *Auto-Pay*, dan agregasi total layanan tambahan (*Add-ons*). Juga dilakukan audit *billing* melalui `ChargeLogicValidation` (99.8% data konsisten).

### B. Exploratory Data Analysis & Predictive Modeling (Python)
* **[📊 Lihat Jupyter Notebook (EDA & XGBoost)](./telco_churn_eda_and_ml.ipynb)**
* **EDA:** Analisis Univariat dan Bivariat mengungkap bahwa pelanggan tipe **Month-to-month** dengan koneksi **Fiber Optic** memiliki tingkat churn tertinggi.
* **Machine Learning:** Menggunakan algoritma **XGBoost** untuk memprediksi probabilitas pelanggan kabur. 
    * **Trade-off Bisnis:** Model dikalibrasi menggunakan `scale_pos_weight` untuk mengoptimalkan **Recall (79%)**. Keputusan bisnis ini diambil karena biaya memberikan promo (False Positive) jauh lebih murah dibandingkan membiarkan pelanggan benar-benar kabur tanpa penanganan (False Negative).

### C. Business Intelligence (Power BI)
* **[📈 Lihat File PBIX Dashboard](./Telco_Churn_Dashboard.pbix)**: Pembuatan *Executive Dashboard* dengan 3 halaman utama: Tinjauan Makro, Analisis Segmen Risiko, dan Rekomendasi Bisnis & Finansial.

---

## 💡 4. Key Insights & Machine Learning Validation
Algoritma *Machine Learning* secara matematis memvalidasi temuan dari analisis Bivariat:
1. **Contract Type is King:** Fitur `Contract_Two year` menjadi faktor penahan churn paling kuat (Peringkat 1 di Feature Importance). Ketiadaan fitur ini (yaitu pelanggan dengan kontrak bulanan) membuat mereka sangat rentan untuk kabur.
2. **Early Tenure Risk:** Risiko churn memuncak pada 12 bulan pertama pelanggan bergabung, menandakan perlunya perbaikan pada proses *onboarding*.

![XGBoost Feature Importance](./feature_importance.png) *(Ganti dengan screenshot Feature Importance Python)*

---

## 💰 5. Business Recommendation & Financial Impact
Alih-alih sekadar melaporkan "uang yang sudah hilang" secara historis (*Historical Revenue Lost* sebesar $2.86M), kami merancang inisiatif untuk menyelamatkan **Pendapatan Berulang (Recurring Revenue)** ke depannya:

1. **Program "Lock-In" Kontrak:** Menawarkan diskon tagihan 15% pada bulan ke-3 khusus untuk pelanggan *Month-to-month* jika mereka bersedia *upgrade* ke kontrak 1 Tahun.
2. **Kampanye Auto-Pay & Proteksi:** Berikan *cashback* $10 atau *free trial* Tech Support selama 1 bulan bagi pelanggan yang beralih ke sistem pembayaran otomatis.

### Estimasi Dampak Finansial:
Saat ini perusahaan memiliki eksposur **Total Risiko Aktif sebesar $1.67M ARR** (Annual Recurring Revenue). 
Jika kampanye ini dieksekusi secara terarah dan berhasil mempertahankan hanya **10%** dari zona merah (pelanggan rawan churn), kita dapat **menyelamatkan ~$167.0K ARR** (setara **~$13.9K MRR** per bulan). Angka ini dapat dijadikan dasar (*baseline*) plafon anggaran kampanye retensi bulanan.

![Recommendation Page](./dashboard_recommendation.png) *(Ganti dengan screenshot Halaman 3 Power BI)*

---
*Dibuat oleh [Hadi Rahman] - Terhubung dengan saya di [LinkedIn](#).*

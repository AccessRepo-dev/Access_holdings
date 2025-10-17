# Access Holdings dbt Project

This dbt project enables data modeling and transformation for **Access Holdings**. It integrates multiple financial and operational data sources — such as **NetSuite**, **Sage Intacct**, and various macroeconomic datasets — into a consistent analytics-ready data warehouse model.

---

## 🧭 Overview

The project follows a **multi-layered architecture**:

| Layer             | Purpose                                                           |
|-------------------|-------------------------------------------------------------------|
| **Raw**           | Ingested source data (external to dbt)                            |
| **Silver**        | Cleansed and standardized data models                             |
| **Gold**          | Business-ready fact and dimension tables for each source system   |
| **Reporting**     | Aggregated and summarized views for analytics                     |
| **Consolidated**  | Unified cross-system models combining multiple sources            |

Each layer ensures data is transformed progressively toward reliable, governed analytics.

---

## 📁 Project Structure

```
Access_holdings/
├── dbt_project.yml
├── packages.yml
├── README.md
├── .gitignore
│
├── macros/
│   ├── get_schema.sql
│   ├── get_target_db.sql
│   ├── model_status.sql
│   ├── generate_alias_name.sql
│   └── config/
│       └── company_sources.yml
│
├── models/
│   ├── integrations/
│   │   ├── silver/
│   │   │   └── macro/              # Curated external datasets (ADP, BEA, BLS, Census, etc.)
│   │   ├── gold/
│   │   │   ├── netsuite/           # NetSuite fact & dimension models
│   │   │   └── sage/               # Sage Intacct fact & dimension models
│   │   └── reporting/              # Source-specific reporting models
│   │
│   ├── consolidated/
│   │   ├── gold/                   # Unified fact & dimension models across systems
│   │   └── reporting/              # Consolidated analytics views
│   │
│   ├── netsuite_schema.yml
│   ├── sage_schema.yml
│   └── macro_schema.yml
│
└── analyses/                        # Analytical SQL or ad-hoc investigations
```

---

## ⚙️ Dynamic Configuration

The project supports multiple companies and source systems through runtime variables and macros.

### Example dbt Run

```bash
dbt run --select models/integrations/gold/netsuite/netsuite_fact_transaction.sql \
  --vars '{"company": "wagway", "sourcesystem": "netsuite"}'
```

### Available Variables

- `company` - Target company identifier (e.g., `wagway`)
- `sourcesystem` - Source system name (e.g., `netsuite`, `sage`)

---

## 📊 Data Sources

### companies
- **WagWay**
- **Playfly**
- **Spotless**
- **AMH**

### Financial Systems
- **NetSuite**
- **Sage Intacct**

### Macroeconomic Data
- **ADP** - Employment and payroll data
- **BEA** - Bureau of Economic Analysis data
- **BLS** - Bureau of Labor Statistics data
- **Census** - US Census Bureau data

---

## 🏗️ Model Layers Explained

### Silver Layer
Cleansed and standardized data with basic transformations applied. Data quality checks and type casting occur here.

### Gold Layer
Business-ready dimensional models organized by source system. Includes fact tables and dimension tables.

### Reporting Layer
Pre-aggregated tables optimized for BI tool consumption.

### Consolidated Layer
Cross-system unified models that combine data from all companies into single analytical tables.


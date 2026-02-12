# ACV Calculation Report

**Opportunity:** [Renewal Opportunity 2026 Renewal w/ 5% Increase](https://macrobond.my.salesforce.com/006TX00000C3yojYAB)
**Generated:** 2026-02-02 18:35:00

---
## 1. Opportunity Details

| Field | Value |
|-------|-------|
| Record Type | Renewal |
| Type | Renewal |
| Link | [006TX00000C3yojYAB](https://macrobond.my.salesforce.com/006TX00000C3yojYAB) |

---
## 2. Primary Quote

**Quote:** [Q-34710](https://macrobond.my.salesforce.com/a0xTX0000043yLVYAY)

---
## 3. Quote Lines (Source Data)

| # | Product | Orig Qty | New Qty | Subscription | Baseline | ACV | Booking Type |
|---|---------|----------|---------|--------------|----------|-----|-------------|
| 1 | [Core License](https://macrobond.my.salesforce.com/a0tTX00000MwKGHYA3) | 4 | 2 | [SUB-0025715](https://macrobond.my.salesforce.com/a19TX000000teQPYAY) | 50000.00 | 26250.00 | Downsell;Price Increase |
| 2 | [Viewer License](https://macrobond.my.salesforce.com/a0tTX00000MwKGIYA3) | 3 | 4 | [SUB-0025716](https://macrobond.my.salesforce.com/a19TX000000teQQYAY) | 0.00 | 0.00 | Upsell |
| 3 | [Data+ License](https://macrobond.my.salesforce.com/a0tTX00000MwKGJYA3) | 1 | 1 | [SUB-0030295](https://macrobond.my.salesforce.com/a19TX000001bEY5YAM) | 25000.00 | 26250.00 | Price Increase |

### Line-Level ACV Breakdown

| # | Product | Renewal | Expansion | Contraction | Price Variance | New |
|---|---------|---------|-----------|-------------|----------------|-----|
| 1 | [Core License](https://macrobond.my.salesforce.com/a0tTX00000MwKGHYA3) | 26250.00 | 0.00 | -25000.00 | 1250.00 | 0.00 |
| 2 | [Viewer License](https://macrobond.my.salesforce.com/a0tTX00000MwKGIYA3) | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 |
| 3 | [Data+ License](https://macrobond.my.salesforce.com/a0tTX00000MwKGJYA3) | 26250.00 | 0.00 | 0.00 | 1250.00 | 0.00 |
| | **TOTAL** | **52500.00** | **0.00** | **-25000.00** | **2500.00** | **0.00** |

---
## 4. Quote-Level Rollup (with Overrides)

| Component | Calculated | Override | Display (Used) |
|-----------|------------|----------|----------------|
| Renewal ACV | 52500.00 | - | **52500.00** |
| Upsell ACV | 0.00 | - | **0.00** |
| Downsell ACV | -25000.00 | - | **-25000.00** |
| Price Variance ACV | 2500.00 | - | **2500.00** |
| New Product ACV | 0.00 | - | **0.00** |
| Baseline Renewal ACV | 75000.00 | - | **75000.00** |

---
## 5. Opportunity-Level Values (Final)

| Component | System Value | Override | Formula Result |
|-----------|--------------|----------|----------------|
| Renewal ACV | 52500.00 | - | **50000.00** |
| Upsell ACV | 0.00 | - | **0.00** |
| Downsell ACV | -25000.00 | - | **-25000.00** |
| Price Increase ACV | 2500.00 | - | **2500.00** |
| New Logo ACV | 0.00 | - | **0.00** |
| Churn ACV | - | - | **0.00** |
| **Gross ACV** | | | **0.00** |
| **Net ACV** | | | **-22500.00** |

> **ACV Override Enabled:** false

---
## 6. Calculation Algorithm

### Step 1: Quote Line Formulas
```
Baseline_ARR = Subscription.Subscription_ACV__c
Renewal_ARR = MIN(Quantity, OriginalQuantity) × AnnualUnitPrice
Expansion_ARR = MAX(0, Quantity - OriginalQuantity) × AnnualUnitPrice
Contraction_ARR = MAX(0, OriginalQuantity - Quantity) × BaselineUnitPrice
Price_Variance = MIN(Quantity, OriginalQuantity) × (AnnualUnitPrice - BaselineUnitPrice)
New_ARR = ACV (if no subscription link)
```

### Step 2: Quote Rollup
```
Total_X_ACV = SUM(line.X_ARR) / segment_count
Total_X_ACV_Display = IF(Override != null, Override, Calculated)
```

### Step 3: Opportunity Formula
```
Renewal_ACV = Total_Renewal_ACV - Total_Price_Variance_ACV (CR000466)
```

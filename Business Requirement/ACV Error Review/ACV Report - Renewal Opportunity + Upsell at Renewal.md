# ACV Calculation Report

**Opportunity:** [Renewal Opportunity + Upsell at Renewal](https://macrobond.my.salesforce.com/006TX00000Bzad0YAB)
**Generated:** 2026-02-02 18:24:34

---
## 1. Opportunity Details

| Field | Value |
|-------|-------|
| Record Type | Renewal |
| Type | Renewal |
| Link | [006TX00000Bzad0YAB](https://macrobond.my.salesforce.com/006TX00000Bzad0YAB) |

---
## 2. Primary Quote

**Quote:** [Q-34359](https://macrobond.my.salesforce.com/a0xTX000003uAkXYAU)

---
## 3. Quote Lines (Source Data)

| # | Product | Orig Qty | New Qty | Subscription | Baseline | ACV | Booking Type |
|---|---------|----------|---------|--------------|----------|-----|-------------|
| 1 | [Data+ License 1st User](https://macrobond.my.salesforce.com/a0tTX00000M403HYAR) | 0 | 1 |  | 0.00 | 128828.00 | New Product |
| 2 | [Core License](https://macrobond.my.salesforce.com/a0tTX00000M403IYAR) | 0 | 6 |  | 0.00 | 592969.00 | New Product |
| 3 | [Core License](https://macrobond.my.salesforce.com/a0tTX00000M4QbxYAF) | 7 | 0 | [SUB-0025619](https://macrobond.my.salesforce.com/a19TX000000tMZNYA2) | 658854.00 | 0.00 | Churn |

### Line-Level ACV Breakdown

| # | Product | Renewal | Expansion | Contraction | Price Variance | New |
|---|---------|---------|-----------|-------------|----------------|-----|
| 1 | [Data+ License 1st User](https://macrobond.my.salesforce.com/a0tTX00000M403HYAR) | 0.00 | 0.00 | 0.00 | 0.00 | 128828.00 |
| 2 | [Core License](https://macrobond.my.salesforce.com/a0tTX00000M403IYAR) | 0.00 | 0.00 | 0.00 | 0.00 | 592969.00 |
| 3 | [Core License](https://macrobond.my.salesforce.com/a0tTX00000M4QbxYAF) | 0.00 | 0.00 | -658854.00 | 0.00 | 0.00 |
| | **TOTAL** | **0.00** | **0.00** | **-658854.00** | **0.00** | **721797.00** |

---
## 4. Quote-Level Rollup (with Overrides)

| Component | Calculated | Override | Display (Used) |
|-----------|------------|----------|----------------|
| Renewal ACV | 0.00 | - | **0.00** |
| Upsell ACV | 0.00 | - | **0.00** |
| Downsell ACV | -658854.00 | - | **-658854.00** |
| Price Variance ACV | 0.00 | - | **0.00** |
| New Product ACV | 721797.00 | - | **721797.00** |
| Baseline Renewal ACV | 658854.00 | - | **658854.00** |

---
## 5. Opportunity-Level Values (Final)

| Component | System Value | Override | Formula Result |
|-----------|--------------|----------|----------------|
| Renewal ACV | 0.00 | - | **0.00** |
| Upsell ACV | 0.00 | - | **62943.00** |
| Downsell ACV | -658854.00 | - | **0.00** |
| Price Increase ACV | 0.00 | - | **0.00** |
| New Logo ACV | 721797.00 | - | **0.00** |
| Churn ACV | - | - | **0.00** |
| **Gross ACV** | | | **62943.00** |
| **Net ACV** | | | **62943.00** |

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

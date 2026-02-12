// Execute Anonymous: ACV Calculation Report Generator
// Usage: Replace the OPPORTUNITY_ID below and run in Developer Console

String OPPORTUNITY_ID = '006TX00000Bzad0YAB'; // <-- Change this

// Query Opportunity
Opportunity opp = [
    SELECT Id, Name, RecordType.Name, Type, Amount,
           Total_Renewal_ACV__c, Total_Upsell_ACV__c, Total_Downsell_ACV__c,
           Total_Price_Variance_ACV__c, Total_New_Product_ACV__c, Total_Churn_ACV__c,
           Renewal_ACV__c, Upsell_ACV__c, Downsell_ACV__c,
           Price_Increase_ACV__c, New_Logo_ACV__c, Churn_ACV__c, Net_ACV__c, Gross_ACV__c,
           ACV_Override__c, Renewal_ACV_Override__c, Upsell_ACV_Override__c,
           Downsell_ACV_Override__c, Price_Increase_ACV_Override__c,
           New_Logo_ACV_Override__c, Churn_ACV_Override__c
    FROM Opportunity
    WHERE Id = :OPPORTUNITY_ID
];

// Query Primary Quote
List<SBQQ__Quote__c> quotes = [
    SELECT Id, Name, SBQQ__Primary__c,
           Total_Renewal_ACV__c, Total_Renewal_ACV_Override__c, Total_Renewal_ACV_Display__c,
           Total_Upsell_ACV__c, Total_Upsell_ACV_Override__c, Total_Upsell_ACV_Display__c,
           Total_Downsell_ACV__c, Total_Downsell_ACV_Override__c, Total_Downsell_ACV_Display__c,
           Total_Price_Variance_ACV__c, Total_Price_Variance_ACV_Override__c, Total_Price_Variance_ACV_Display__c,
           Total_New_Product_ACV__c, Total_New_Product_ACV_Override__c, Total_New_Product_ACV_Display__c,
           Total_Churn_ACV__c, Total_Churn_ACV_Override__c, Total_Churn_ACV_Display__c,
           Baseline_Renewal_ACV__c, Baseline_Renewal_ACV_Override__c, Baseline_Renewal_ACV_Display__c,
           Has_ACV_Override__c, ACV__c, ACV_Override__c, ACV_Display__c
    FROM SBQQ__Quote__c
    WHERE SBQQ__Opportunity2__c = :OPPORTUNITY_ID
      AND SBQQ__Primary__c = true
    LIMIT 1
];

SBQQ__Quote__c quote = quotes.isEmpty() ? null : quotes[0];

// Query Quote Lines
List<SBQQ__QuoteLine__c> lines = new List<SBQQ__QuoteLine__c>();
if (quote != null) {
    lines = [
        SELECT Id, Name, SBQQ__ProductName__c, SBQQ__Number__c,
               Original_Quantity__c, SBQQ__Quantity__c, SBQQ__NetPrice__c,
               SBQQ__RenewedSubscription__c, SBQQ__RenewedSubscription__r.Name,
               SBQQ__RenewedSubscription__r.Subscription_ACV__c,
               SBQQ__UpgradedSubscription__c, SBQQ__UpgradedSubscription__r.Name,
               SBQQ__UpgradedSubscription__r.Subscription_ACV__c,
               Baseline_ARR__c, Baseline_Unit_Price__c,
               Annual_Contract_Value__c, Renewal_ARR__c, New_Product_ARR__c,
               Expansion_ARR__c, Contraction_ARR__c, Price_Variance__c,
               Booking_Type__c, Revenue_Type__c
        FROM SBQQ__QuoteLine__c
        WHERE SBQQ__Quote__c = :quote.Id
        ORDER BY SBQQ__Number__c
    ];
}

// Build Markdown Report
String md = '';
String nl = '\n';

md += '# ACV Calculation Report' + nl;
md += '**Generated:** ' + Datetime.now().format('yyyy-MM-dd HH:mm:ss') + nl + nl;

// Opportunity Section
md += '---' + nl;
md += '## 1. Opportunity Details' + nl + nl;
md += '| Field | Value |' + nl;
md += '|-------|-------|' + nl;
md += '| **Name** | ' + opp.Name + ' |' + nl;
md += '| **Record Type** | ' + opp.RecordType.Name + ' |' + nl;
md += '| **Type** | ' + opp.Type + ' |' + nl;
md += '| **Opportunity ID** | `' + opp.Id + '` |' + nl + nl;

// Quote Section
md += '---' + nl;
md += '## 2. Primary Quote' + nl + nl;

if (quote == null) {
    md += '⚠️ **No Primary Quote Found**' + nl + nl;
} else {
    md += '| Field | Value |' + nl;
    md += '|-------|-------|' + nl;
    md += '| **Quote Name** | ' + quote.Name + ' |' + nl;
    md += '| **Quote ID** | `' + quote.Id + '` |' + nl;
    md += '| **Has Override** | ' + quote.Has_ACV_Override__c + ' |' + nl + nl;
}

// Quote Lines Section
md += '---' + nl;
md += '## 3. Quote Lines (Source Data)' + nl + nl;

if (lines.isEmpty()) {
    md += '⚠️ **No Quote Lines Found**' + nl + nl;
} else {
    md += '| # | Product | Orig Qty | New Qty | Subscription | Sub ACV | Baseline | Line ACV | Booking Type |' + nl;
    md += '|---|---------|----------|---------|--------------|---------|----------|----------|--------------|' + nl;

    for (SBQQ__QuoteLine__c line : lines) {
        String subName = '';
        Decimal subACV = 0;
        if (line.SBQQ__RenewedSubscription__c != null) {
            subName = line.SBQQ__RenewedSubscription__r.Name;
            subACV = line.SBQQ__RenewedSubscription__r.Subscription_ACV__c;
        } else if (line.SBQQ__UpgradedSubscription__c != null) {
            subName = line.SBQQ__UpgradedSubscription__r.Name;
            subACV = line.SBQQ__UpgradedSubscription__r.Subscription_ACV__c;
        }

        md += '| ' + (Integer)line.SBQQ__Number__c + ' | ' + line.SBQQ__ProductName__c + ' | ';
        md += formatNum(line.Original_Quantity__c) + ' | ' + formatNum(line.SBQQ__Quantity__c) + ' | ';
        md += subName + ' | ' + formatCurrency(subACV) + ' | ';
        md += formatCurrency(line.Baseline_ARR__c) + ' | ' + formatCurrency(line.Annual_Contract_Value__c) + ' | ';
        md += line.Booking_Type__c + ' |' + nl;
    }
    md += nl;

    // Detailed Line Calculations
    md += '### Line-Level ACV Breakdown' + nl + nl;
    md += '| # | Product | Renewal | Expansion | Contraction | Price Variance | New Product |' + nl;
    md += '|---|---------|---------|-----------|-------------|----------------|-------------|' + nl;

    Decimal totalRenewal = 0, totalExpansion = 0, totalContraction = 0, totalPV = 0, totalNew = 0;

    for (SBQQ__QuoteLine__c line : lines) {
        md += '| ' + (Integer)line.SBQQ__Number__c + ' | ' + line.SBQQ__ProductName__c + ' | ';
        md += formatCurrency(line.Renewal_ARR__c) + ' | ';
        md += formatCurrency(line.Expansion_ARR__c) + ' | ';
        md += formatCurrency(line.Contraction_ARR__c) + ' | ';
        md += formatCurrency(line.Price_Variance__c) + ' | ';
        md += formatCurrency(line.New_Product_ARR__c) + ' |' + nl;

        totalRenewal += nvl(line.Renewal_ARR__c);
        totalExpansion += nvl(line.Expansion_ARR__c);
        totalContraction += nvl(line.Contraction_ARR__c);
        totalPV += nvl(line.Price_Variance__c);
        totalNew += nvl(line.New_Product_ARR__c);
    }

    md += '| | **TOTAL** | **' + formatCurrency(totalRenewal) + '** | **' + formatCurrency(totalExpansion) + '** | ';
    md += '**' + formatCurrency(totalContraction) + '** | **' + formatCurrency(totalPV) + '** | **' + formatCurrency(totalNew) + '** |' + nl + nl;
}

// Quote Level Rollup
md += '---' + nl;
md += '## 4. Quote-Level Rollup (with Overrides)' + nl + nl;

if (quote != null) {
    md += '| Component | Calculated | Override | Display (Used) |' + nl;
    md += '|-----------|------------|----------|----------------|' + nl;
    md += '| Renewal ACV | ' + formatCurrency(quote.Total_Renewal_ACV__c) + ' | ' + formatCurrency(quote.Total_Renewal_ACV_Override__c) + ' | **' + formatCurrency(quote.Total_Renewal_ACV_Display__c) + '** |' + nl;
    md += '| Upsell ACV | ' + formatCurrency(quote.Total_Upsell_ACV__c) + ' | ' + formatCurrency(quote.Total_Upsell_ACV_Override__c) + ' | **' + formatCurrency(quote.Total_Upsell_ACV_Display__c) + '** |' + nl;
    md += '| Downsell ACV | ' + formatCurrency(quote.Total_Downsell_ACV__c) + ' | ' + formatCurrency(quote.Total_Downsell_ACV_Override__c) + ' | **' + formatCurrency(quote.Total_Downsell_ACV_Display__c) + '** |' + nl;
    md += '| Price Variance ACV | ' + formatCurrency(quote.Total_Price_Variance_ACV__c) + ' | ' + formatCurrency(quote.Total_Price_Variance_ACV_Override__c) + ' | **' + formatCurrency(quote.Total_Price_Variance_ACV_Display__c) + '** |' + nl;
    md += '| New Product ACV | ' + formatCurrency(quote.Total_New_Product_ACV__c) + ' | ' + formatCurrency(quote.Total_New_Product_ACV_Override__c) + ' | **' + formatCurrency(quote.Total_New_Product_ACV_Display__c) + '** |' + nl;
    md += '| Churn ACV | ' + formatCurrency(quote.Total_Churn_ACV__c) + ' | ' + formatCurrency(quote.Total_Churn_ACV_Override__c) + ' | **' + formatCurrency(quote.Total_Churn_ACV_Display__c) + '** |' + nl;
    md += '| Baseline Renewal | ' + formatCurrency(quote.Baseline_Renewal_ACV__c) + ' | ' + formatCurrency(quote.Baseline_Renewal_ACV_Override__c) + ' | **' + formatCurrency(quote.Baseline_Renewal_ACV_Display__c) + '** |' + nl;
    md += nl;
}

// Opportunity Level
md += '---' + nl;
md += '## 5. Opportunity-Level Values (Final)' + nl + nl;

md += '| Component | System Value | Override | Formula Result |' + nl;
md += '|-----------|--------------|----------|----------------|' + nl;
md += '| Renewal ACV | ' + formatCurrency(opp.Total_Renewal_ACV__c) + ' | ' + formatCurrency(opp.Renewal_ACV_Override__c) + ' | **' + formatCurrency(opp.Renewal_ACV__c) + '** |' + nl;
md += '| Upsell ACV | ' + formatCurrency(opp.Total_Upsell_ACV__c) + ' | ' + formatCurrency(opp.Upsell_ACV_Override__c) + ' | **' + formatCurrency(opp.Upsell_ACV__c) + '** |' + nl;
md += '| Downsell ACV | ' + formatCurrency(opp.Total_Downsell_ACV__c) + ' | ' + formatCurrency(opp.Downsell_ACV_Override__c) + ' | **' + formatCurrency(opp.Downsell_ACV__c) + '** |' + nl;
md += '| Price Increase ACV | ' + formatCurrency(opp.Total_Price_Variance_ACV__c) + ' | ' + formatCurrency(opp.Price_Increase_ACV_Override__c) + ' | **' + formatCurrency(opp.Price_Increase_ACV__c) + '** |' + nl;
md += '| New Logo ACV | ' + formatCurrency(opp.Total_New_Product_ACV__c) + ' | ' + formatCurrency(opp.New_Logo_ACV_Override__c) + ' | **' + formatCurrency(opp.New_Logo_ACV__c) + '** |' + nl;
md += '| Churn ACV | ' + formatCurrency(opp.Total_Churn_ACV__c) + ' | ' + formatCurrency(opp.Churn_ACV_Override__c) + ' | **' + formatCurrency(opp.Churn_ACV__c) + '** |' + nl;
md += '| **Gross ACV** | | | **' + formatCurrency(opp.Gross_ACV__c) + '** |' + nl;
md += '| **Net ACV** | | | **' + formatCurrency(opp.Net_ACV__c) + '** |' + nl;
md += nl;

md += '> **ACV Override Enabled:** ' + opp.ACV_Override__c + nl + nl;

// Calculation Algorithm
md += '---' + nl;
md += '## 6. Calculation Algorithm' + nl + nl;

md += '### Step 1: Quote Line Formulas' + nl;
md += '```' + nl;
md += 'Baseline_ARR = Subscription.Subscription_ACV__c' + nl;
md += 'Baseline_Unit_Price = Baseline_ARR / Original_Quantity' + nl;
md += 'Renewal_ARR = MIN(Qty, OrigQty) × NetPrice' + nl;
md += 'Expansion_ARR = MAX(0, Qty - OrigQty) × NetPrice' + nl;
md += 'Contraction_ARR = MAX(0, OrigQty - Qty) × Baseline_Unit_Price' + nl;
md += 'Price_Variance = MIN(Qty, OrigQty) × (NetPrice - Baseline_Unit_Price)' + nl;
md += 'New_Product_ARR = ACV (if no subscription link)' + nl;
md += '```' + nl + nl;

md += '### Step 2: Quote Rollup' + nl;
md += '```' + nl;
md += 'Total_X_ACV = SUM(line.X_ARR) / segment_count' + nl;
md += 'Total_X_ACV_Display = IFNULL(Override, Calculated)' + nl;
md += '```' + nl + nl;

md += '### Step 3: Quote → Opportunity Sync (Flow)' + nl;
md += '```' + nl;
md += 'Opp.Total_Renewal_ACV = Quote.Total_Renewal_ACV_Display' + nl;
md += 'Opp.Total_Upsell_ACV = Quote.Total_Upsell_ACV_Display' + nl;
md += '(etc.)' + nl;
md += '```' + nl + nl;

md += '### Step 4: Opportunity Formula Fields' + nl;
md += '```' + nl;
md += 'Renewal_ACV = IF(Override, Override_Value, Total_Renewal_ACV - Total_Price_Variance_ACV)' + nl;
md += 'Upsell_ACV = IF(Override, Override_Value, Total_Upsell_ACV)' + nl;
md += 'Gross_ACV = Renewal + Upsell + New_Logo + Price_Increase' + nl;
md += 'Net_ACV = Gross_ACV - Downsell - Churn' + nl;
md += '```' + nl + nl;

md += '---' + nl;
md += '*Report generated by ACV Calculation Report Generator*' + nl;

// Output to debug log
System.debug('=== ACV REPORT START ===');
System.debug(md);
System.debug('=== ACV REPORT END ===');

// Helper functions
private String formatCurrency(Decimal val) {
    if (val == null) return '-';
    return String.valueOf(val.setScale(2));
}

private String formatNum(Decimal val) {
    if (val == null) return '0';
    return String.valueOf(val.setScale(0));
}

private Decimal nvl(Decimal val) {
    return val == null ? 0 : val;
}

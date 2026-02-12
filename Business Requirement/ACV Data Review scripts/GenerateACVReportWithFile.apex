String OPP_ID='006TX00000Bzad0YAB';
String DOC_ID='069TX00000TJFCPYA5';
String BASE=URL.getOrgDomainURL().toExternalForm();
Opportunity o=[SELECT Id,Name,RecordType.Name,Type,Total_Renewal_ACV__c,Total_Upsell_ACV__c,Total_Downsell_ACV__c,Total_Price_Variance_ACV__c,Total_New_Product_ACV__c,Renewal_ACV__c,Upsell_ACV__c,Downsell_ACV__c,Price_Increase_ACV__c,New_Logo_ACV__c,Churn_ACV__c,Net_ACV__c,Gross_ACV__c,ACV_Override__c,Renewal_ACV_Override__c,Upsell_ACV_Override__c,Downsell_ACV_Override__c,Price_Increase_ACV_Override__c,New_Logo_ACV_Override__c,Churn_ACV_Override__c FROM Opportunity WHERE Id=:OPP_ID];
List<SBQQ__Quote__c> qs=[SELECT Id,Name,Total_Renewal_ACV__c,Total_Renewal_ACV_Override__c,Total_Renewal_ACV_Display__c,Total_Upsell_ACV__c,Total_Upsell_ACV_Override__c,Total_Upsell_ACV_Display__c,Total_Downsell_ACV__c,Total_Downsell_ACV_Override__c,Total_Downsell_ACV_Display__c,Total_Price_Variance_ACV__c,Total_Price_Variance_ACV_Override__c,Total_Price_Variance_ACV_Display__c,Total_New_Product_ACV__c,Total_New_Product_ACV_Override__c,Total_New_Product_ACV_Display__c,Baseline_Renewal_ACV__c,Baseline_Renewal_ACV_Override__c,Baseline_Renewal_ACV_Display__c FROM SBQQ__Quote__c WHERE SBQQ__Opportunity2__c=:OPP_ID AND SBQQ__Primary__c=true LIMIT 1];
SBQQ__Quote__c q=qs.isEmpty()?null:qs[0];
List<SBQQ__QuoteLine__c> ls=q==null?new List<SBQQ__QuoteLine__c>():[SELECT Id,Name,SBQQ__ProductName__c,SBQQ__Number__c,Original_Quantity__c,SBQQ__Quantity__c,SBQQ__RenewedSubscription__c,SBQQ__RenewedSubscription__r.Name,SBQQ__RenewedSubscription__r.Subscription_ACV__c,SBQQ__UpgradedSubscription__c,SBQQ__UpgradedSubscription__r.Name,SBQQ__UpgradedSubscription__r.Subscription_ACV__c,Baseline_ARR__c,Annual_Contract_Value__c,Renewal_ARR__c,New_ARR__c,Expansion_ARR__c,Contraction_ARR__c,Price_Variance__c,Booking_Type__c FROM SBQQ__QuoteLine__c WHERE SBQQ__Quote__c=:q.Id ORDER BY SBQQ__Number__c];
String r='# ACV Calculation Report\n\n';
r+='**Opportunity:** ['+o.Name+']('+BASE+'/'+o.Id+')\n';
r+='**Generated:** '+Datetime.now().format('yyyy-MM-dd HH:mm:ss')+'\n\n';
r+='---\n## 1. Opportunity Details\n\n';
r+='| Field | Value |\n|-------|-------|\n';
r+='| Record Type | '+o.RecordType.Name+' |\n';
r+='| Type | '+o.Type+' |\n';
r+='| Link | ['+o.Id+']('+BASE+'/'+o.Id+') |\n\n';
if(q!=null){r+='---\n## 2. Primary Quote\n\n';r+='**Quote:** ['+q.Name+']('+BASE+'/'+q.Id+')\n\n';}
if(!ls.isEmpty()){
r+='---\n## 3. Quote Lines (Source Data)\n\n';
r+='| # | Product | Orig Qty | New Qty | Subscription | Baseline | ACV | Booking Type |\n';
r+='|---|---------|----------|---------|--------------|----------|-----|-------------|\n';
for(SBQQ__QuoteLine__c l:ls){String sl='';if(l.SBQQ__RenewedSubscription__c!=null){sl='['+l.SBQQ__RenewedSubscription__r.Name+']('+BASE+'/'+l.SBQQ__RenewedSubscription__c+')';}else if(l.SBQQ__UpgradedSubscription__c!=null){sl='['+l.SBQQ__UpgradedSubscription__r.Name+']('+BASE+'/'+l.SBQQ__UpgradedSubscription__c+')';}
Decimal oq=l.Original_Quantity__c==null?0:l.Original_Quantity__c,nq=l.SBQQ__Quantity__c==null?0:l.SBQQ__Quantity__c,ba=l.Baseline_ARR__c==null?0:l.Baseline_ARR__c,ac=l.Annual_Contract_Value__c==null?0:l.Annual_Contract_Value__c;
r+='| '+Integer.valueOf(l.SBQQ__Number__c)+' | ['+l.SBQQ__ProductName__c+']('+BASE+'/'+l.Id+') | '+oq.setScale(0)+' | '+nq.setScale(0)+' | '+sl+' | '+ba.setScale(2)+' | '+ac.setScale(2)+' | '+(l.Booking_Type__c!=null?l.Booking_Type__c:'-')+' |\n';}
r+='\n### Line-Level ACV Breakdown\n\n';
r+='| # | Product | Renewal | Expansion | Contraction | Price Variance | New |\n';
r+='|---|---------|---------|-----------|-------------|----------------|-----|\n';
Decimal tr=0,te=0,tc=0,tp=0,tn=0;
for(SBQQ__QuoteLine__c l:ls){Decimal re=l.Renewal_ARR__c==null?0:l.Renewal_ARR__c,ex=l.Expansion_ARR__c==null?0:l.Expansion_ARR__c,co=l.Contraction_ARR__c==null?0:l.Contraction_ARR__c,pv=l.Price_Variance__c==null?0:l.Price_Variance__c,nw=l.New_ARR__c==null?0:l.New_ARR__c;
r+='| '+Integer.valueOf(l.SBQQ__Number__c)+' | ['+l.SBQQ__ProductName__c+']('+BASE+'/'+l.Id+') | '+re.setScale(2)+' | '+ex.setScale(2)+' | '+co.setScale(2)+' | '+pv.setScale(2)+' | '+nw.setScale(2)+' |\n';tr+=re;te+=ex;tc+=co;tp+=pv;tn+=nw;}
r+='| | **TOTAL** | **'+tr.setScale(2)+'** | **'+te.setScale(2)+'** | **'+tc.setScale(2)+'** | **'+tp.setScale(2)+'** | **'+tn.setScale(2)+'** |\n\n';}
if(q!=null){r+='---\n## 4. Quote-Level Rollup (with Overrides)\n\n';
r+='| Component | Calculated | Override | Display (Used) |\n';
r+='|-----------|------------|----------|----------------|\n';
Decimal v,d;String ov;
v=q.Total_Renewal_ACV__c==null?0:q.Total_Renewal_ACV__c;ov=q.Total_Renewal_ACV_Override__c==null?'-':String.valueOf(q.Total_Renewal_ACV_Override__c.setScale(2));d=q.Total_Renewal_ACV_Display__c==null?0:q.Total_Renewal_ACV_Display__c;r+='| Renewal ACV | '+v.setScale(2)+' | '+ov+' | **'+d.setScale(2)+'** |\n';
v=q.Total_Upsell_ACV__c==null?0:q.Total_Upsell_ACV__c;ov=q.Total_Upsell_ACV_Override__c==null?'-':String.valueOf(q.Total_Upsell_ACV_Override__c.setScale(2));d=q.Total_Upsell_ACV_Display__c==null?0:q.Total_Upsell_ACV_Display__c;r+='| Upsell ACV | '+v.setScale(2)+' | '+ov+' | **'+d.setScale(2)+'** |\n';
v=q.Total_Downsell_ACV__c==null?0:q.Total_Downsell_ACV__c;ov=q.Total_Downsell_ACV_Override__c==null?'-':String.valueOf(q.Total_Downsell_ACV_Override__c.setScale(2));d=q.Total_Downsell_ACV_Display__c==null?0:q.Total_Downsell_ACV_Display__c;r+='| Downsell ACV | '+v.setScale(2)+' | '+ov+' | **'+d.setScale(2)+'** |\n';
v=q.Total_Price_Variance_ACV__c==null?0:q.Total_Price_Variance_ACV__c;ov=q.Total_Price_Variance_ACV_Override__c==null?'-':String.valueOf(q.Total_Price_Variance_ACV_Override__c.setScale(2));d=q.Total_Price_Variance_ACV_Display__c==null?0:q.Total_Price_Variance_ACV_Display__c;r+='| Price Variance ACV | '+v.setScale(2)+' | '+ov+' | **'+d.setScale(2)+'** |\n';
v=q.Total_New_Product_ACV__c==null?0:q.Total_New_Product_ACV__c;ov=q.Total_New_Product_ACV_Override__c==null?'-':String.valueOf(q.Total_New_Product_ACV_Override__c.setScale(2));d=q.Total_New_Product_ACV_Display__c==null?0:q.Total_New_Product_ACV_Display__c;r+='| New Product ACV | '+v.setScale(2)+' | '+ov+' | **'+d.setScale(2)+'** |\n';
v=q.Baseline_Renewal_ACV__c==null?0:q.Baseline_Renewal_ACV__c;ov=q.Baseline_Renewal_ACV_Override__c==null?'-':String.valueOf(q.Baseline_Renewal_ACV_Override__c.setScale(2));d=q.Baseline_Renewal_ACV_Display__c==null?0:q.Baseline_Renewal_ACV_Display__c;r+='| Baseline Renewal ACV | '+v.setScale(2)+' | '+ov+' | **'+d.setScale(2)+'** |\n\n';}
r+='---\n## 5. Opportunity-Level Values (Final)\n\n';
r+='| Component | System Value | Override | Formula Result |\n';
r+='|-----------|--------------|----------|----------------|\n';
Decimal sv,rs;String so;
sv=o.Total_Renewal_ACV__c==null?0:o.Total_Renewal_ACV__c;so=o.Renewal_ACV_Override__c==null?'-':String.valueOf(o.Renewal_ACV_Override__c.setScale(2));rs=o.Renewal_ACV__c==null?0:o.Renewal_ACV__c;r+='| Renewal ACV | '+sv.setScale(2)+' | '+so+' | **'+rs.setScale(2)+'** |\n';
sv=o.Total_Upsell_ACV__c==null?0:o.Total_Upsell_ACV__c;so=o.Upsell_ACV_Override__c==null?'-':String.valueOf(o.Upsell_ACV_Override__c.setScale(2));rs=o.Upsell_ACV__c==null?0:o.Upsell_ACV__c;r+='| Upsell ACV | '+sv.setScale(2)+' | '+so+' | **'+rs.setScale(2)+'** |\n';
sv=o.Total_Downsell_ACV__c==null?0:o.Total_Downsell_ACV__c;so=o.Downsell_ACV_Override__c==null?'-':String.valueOf(o.Downsell_ACV_Override__c.setScale(2));rs=o.Downsell_ACV__c==null?0:o.Downsell_ACV__c;r+='| Downsell ACV | '+sv.setScale(2)+' | '+so+' | **'+rs.setScale(2)+'** |\n';
sv=o.Total_Price_Variance_ACV__c==null?0:o.Total_Price_Variance_ACV__c;so=o.Price_Increase_ACV_Override__c==null?'-':String.valueOf(o.Price_Increase_ACV_Override__c.setScale(2));rs=o.Price_Increase_ACV__c==null?0:o.Price_Increase_ACV__c;r+='| Price Increase ACV | '+sv.setScale(2)+' | '+so+' | **'+rs.setScale(2)+'** |\n';
sv=o.Total_New_Product_ACV__c==null?0:o.Total_New_Product_ACV__c;so=o.New_Logo_ACV_Override__c==null?'-':String.valueOf(o.New_Logo_ACV_Override__c.setScale(2));rs=o.New_Logo_ACV__c==null?0:o.New_Logo_ACV__c;r+='| New Logo ACV | '+sv.setScale(2)+' | '+so+' | **'+rs.setScale(2)+'** |\n';
so=o.Churn_ACV_Override__c==null?'-':String.valueOf(o.Churn_ACV_Override__c.setScale(2));rs=o.Churn_ACV__c==null?0:o.Churn_ACV__c;r+='| Churn ACV | - | '+so+' | **'+rs.setScale(2)+'** |\n';
rs=o.Gross_ACV__c==null?0:o.Gross_ACV__c;r+='| **Gross ACV** | | | **'+rs.setScale(2)+'** |\n';
rs=o.Net_ACV__c==null?0:o.Net_ACV__c;r+='| **Net ACV** | | | **'+rs.setScale(2)+'** |\n\n';
r+='> **ACV Override Enabled:** '+o.ACV_Override__c+'\n\n';
r+='---\n## 6. Calculation Algorithm\n\n';
r+='### Step 1: Quote Line Formulas\n```\n';
r+='Baseline_ARR = Subscription.Subscription_ACV__c\n';
r+='Renewal_ARR = MIN(Quantity, OriginalQuantity) × AnnualUnitPrice\n';
r+='Expansion_ARR = MAX(0, Quantity - OriginalQuantity) × AnnualUnitPrice\n';
r+='Contraction_ARR = MAX(0, OriginalQuantity - Quantity) × BaselineUnitPrice\n';
r+='Price_Variance = MIN(Quantity, OriginalQuantity) × (AnnualUnitPrice - BaselineUnitPrice)\n';
r+='New_ARR = ACV (if no subscription link)\n```\n\n';
r+='### Step 2: Quote Rollup\n```\n';
r+='Total_X_ACV = SUM(line.X_ARR) / segment_count\n';
r+='Total_X_ACV_Display = IF(Override != null, Override, Calculated)\n```\n\n';
r+='### Step 3: Opportunity Formula\n```\n';
r+='Renewal_ACV = Total_Renewal_ACV - Total_Price_Variance_ACV (CR000466)\n```\n';
ContentVersion cv=new ContentVersion();cv.Title='ACV Report - '+o.Name;cv.PathOnClient='ACV_Report.md';cv.VersionData=Blob.valueOf(r);
if(String.isNotBlank(DOC_ID))cv.ContentDocumentId=DOC_ID;
insert cv;
if(String.isBlank(DOC_ID)){cv=[SELECT ContentDocumentId FROM ContentVersion WHERE Id=:cv.Id];ContentDocumentLink cdl=new ContentDocumentLink();cdl.ContentDocumentId=cv.ContentDocumentId;cdl.LinkedEntityId=o.Id;cdl.ShareType='V';cdl.Visibility='AllUsers';insert cdl;System.debug('New file: '+cv.ContentDocumentId);}
else{System.debug('Updated: '+DOC_ID);}
System.debug('Done: '+cv.Id);

// ============================================================================
// CR000475 - Win/Loss Reason Revamp - DATA MIGRATION SCRIPT
// ============================================================================
// Execute via Developer Console > Execute Anonymous
//
// PREREQUISITES:
//   1. Deploy the new field definitions FIRST (picklist values must exist)
//   2. Run 01_Backup_Opportunity_Data.soql and save the CSV backup
//   3. Running user must have the "Bypass_Opportunity_Validation_Rules"
//      custom permission assigned (to bypass Opportunity_Lock_on_Closed_Status)
//
// SCOPE:
//   - Minimum: Q4 FY25 (Oct 1 - Dec 31, 2025) per Steph's request
//   - Stretch: All FY25 (Jan 1 - Dec 31, 2025)
//   Adjust the DATE_RANGE_START below to control scope.
//
// NOTE ON "Alternative solution/competitor response":
//   This old value maps to TWO possible new values. The script defaults
//   to "Competitive Solution Selected". Records requiring manual review
//   are flagged in the debug log. Run SOQL Step 4 from the backup query
//   to export the list for Steph/Oliver to review.
// ============================================================================

// ---- CONFIGURATION ----
// Change this to 2025-01-01 for full FY25 migration (stretch goal)
Date DATE_RANGE_START = Date.newInstance(2025, 1, 1);
Date DATE_RANGE_END   = Date.newInstance(2026, 2, 6);
Boolean DRY_RUN = false; // Set to true to preview changes without saving

// ---- WIN REASON MAPPING (old fullName → new fullName) ----
Map<String, String> winReasonMap = new Map<String, String>{
    'User interface and Data structure'       => 'Data Structure and User Interface',
    'Clean, High-Quality Data and Meta-Data'  => 'High-Quality, Well Structured Data',
    'Width of Data Available'                 => 'Broad and Deep Data Coverage',
    'Simple Analytics, requiring no coding skills' => 'No Code Analytics',
    'Charting and Visualization'              => 'Powerful Visualization and Charting',
    'Ease of update, removal of workarounds'  => 'Operational Efficiency and Workflow Improvement',
    'Platform access & storage'               => 'Collaboration, Sharing and Access Model',
    'Interconnectivity with existing tools'    => 'Integration with Existing Tools and Workflows',
    'Sharing of finished work'                => 'Collaboration, Sharing and Access Model',
    'Pricing - compelling value-add'          => 'Compelling Value for Price',
    'Pricing \u2013 cheaper vs alternatives'  => 'Compelling Value for Price',
    'Need Macrobond as central tool in the team' => 'Adopted as a Core Team Platform'
};

// ---- LOSS REASON MAPPING (old fullName → new fullName) ----
Map<String, String> lossReasonMap = new Map<String, String>{
    'Missing Data'                              => 'Data Coverage Did Not Meet Requirements',
    'User interface and Data structure'          => 'Platform Usability or Data Structure Limitations',
    'Charting and Visualisation'                 => 'Visualization or Analytical Capabilities Insufficient',
    'Platform access & storage'                  => 'Platform Usability or Data Structure Limitations',
    'Interconnectivity with existing tools'       => 'Integration Constraints to other Tools',
    'Insufficient value-add'                     => 'Insufficient Business Value Relative to Cost',
    'Too expensive vs alternatives'              => 'Budget or Pricing Constraints',
    'IT integration issues'                      => 'IT Environment Constraints',
    'Compliance'                                 => 'Legal or Compliance Restrictions',
    'Agreement on terms'                         => 'Contract Terms not Agreed',
    'Due to change in scope'                     => 'Change in Scope or Priorities',
    'Alternative solution/competitor response'    => 'Competitive Solution Selected',
    'User Transfer'                              => 'Organizational Change/User Transfer',
    'Spare license found'                        => 'Existing License Coverage',
    'License saved'                              => 'License Consolidation or Reduction',
    'Disqualified'                               => 'Disqualified - No Valid Opportunity',
    'Pipe clean up'                              => 'Pipeline Clean Up'
};

// ---- QUERY OPPORTUNITIES IN SCOPE ----
List<Opportunity> oppsToUpdate = new List<Opportunity>();
List<String> manualReviewIds = new List<String>();

// Build the set of all old values we need to find
Set<String> oldWinValues = winReasonMap.keySet();
Set<String> oldLossValues = lossReasonMap.keySet();

List<Opportunity> oppsInScope = [
    SELECT Id, Name, Win_Reason__c, Loss_Reason__c, StageName, CloseDate
    FROM Opportunity
    WHERE CloseDate >= :DATE_RANGE_START
    AND CloseDate <= :DATE_RANGE_END
    AND (
        Win_Reason__c IN :oldWinValues
        OR Loss_Reason__c IN :oldLossValues
    )
    ORDER BY CloseDate ASC
];

System.debug('=== CR000475 MIGRATION: Found ' + oppsInScope.size() + ' opportunities to migrate ===');
System.debug('Date range: ' + DATE_RANGE_START + ' to ' + DATE_RANGE_END);
System.debug('Dry run: ' + DRY_RUN);

Integer winMapped = 0;
Integer lossMapped = 0;
Integer manualReviewCount = 0;

for (Opportunity opp : oppsInScope) {
    Boolean changed = false;

    // Map Win Reason
    if (opp.Win_Reason__c != null && winReasonMap.containsKey(opp.Win_Reason__c)) {
        String newVal = winReasonMap.get(opp.Win_Reason__c);
        System.debug('WIN  | ' + opp.Id + ' | ' + opp.Name + ' | "' + opp.Win_Reason__c + '" → "' + newVal + '"');
        opp.Win_Reason__c = newVal;
        changed = true;
        winMapped++;
    }

    // Map Loss Reason
    if (opp.Loss_Reason__c != null && lossReasonMap.containsKey(opp.Loss_Reason__c)) {
        String oldVal = opp.Loss_Reason__c;
        String newVal = lossReasonMap.get(oldVal);

        // Flag records that need manual review
        if (oldVal == 'Alternative solution/competitor response') {
            manualReviewIds.add(opp.Id);
            manualReviewCount++;
            System.debug('MANUAL REVIEW | ' + opp.Id + ' | ' + opp.Name
                + ' | "Alternative solution/competitor response" → defaulted to "Competitive Solution Selected"'
                + ' | Could also be "Internal/Build Solution Preferred" - review Loss_Reason_Note__c');
        }

        System.debug('LOSS | ' + opp.Id + ' | ' + opp.Name + ' | "' + oldVal + '" → "' + newVal + '"');
        opp.Loss_Reason__c = newVal;
        changed = true;
        lossMapped++;
    }

    if (changed) {
        oppsToUpdate.add(opp);
    }
}

// ---- SUMMARY ----
System.debug('=== MIGRATION SUMMARY ===');
System.debug('Total opportunities to update: ' + oppsToUpdate.size());
System.debug('Win Reasons mapped:  ' + winMapped);
System.debug('Loss Reasons mapped: ' + lossMapped);
System.debug('Manual review needed (Alternative solution/competitor response): ' + manualReviewCount);

if (manualReviewCount > 0) {
    System.debug('=== MANUAL REVIEW IDS (defaulted to Competitive Solution Selected) ===');
    System.debug(String.join(manualReviewIds, ', '));
}

// ---- EXECUTE UPDATE ----
if (!DRY_RUN && !oppsToUpdate.isEmpty()) {
    // Process in batches of 200 to stay within governor limits
    List<Database.SaveResult> allResults = new List<Database.SaveResult>();

    Integer batchSize = 200;
    Integer totalBatches = (Integer)Math.ceil((Decimal)oppsToUpdate.size() / batchSize);

    for (Integer i = 0; i < oppsToUpdate.size(); i += batchSize) {
        Integer endIdx = Math.min(i + batchSize, oppsToUpdate.size());
        List<Opportunity> batch = new List<Opportunity>();
        for (Integer j = i; j < endIdx; j++) {
            batch.add(oppsToUpdate[j]);
        }

        List<Database.SaveResult> results = Database.update(batch, false);
        allResults.addAll(results);

        Integer batchNum = (i / batchSize) + 1;
        System.debug('Batch ' + batchNum + '/' + totalBatches + ' processed (' + batch.size() + ' records)');
    }

    // Report errors
    Integer successCount = 0;
    Integer errorCount = 0;
    for (Database.SaveResult sr : allResults) {
        if (sr.isSuccess()) {
            successCount++;
        } else {
            errorCount++;
            for (Database.Error err : sr.getErrors()) {
                System.debug('ERROR | ' + sr.getId() + ' | ' + err.getStatusCode() + ': ' + err.getMessage());
            }
        }
    }

    System.debug('=== UPDATE RESULTS ===');
    System.debug('Successfully updated: ' + successCount);
    System.debug('Errors: ' + errorCount);
} else if (DRY_RUN) {
    System.debug('=== DRY RUN COMPLETE - No records were modified ===');
} else {
    System.debug('=== No records to update ===');
}

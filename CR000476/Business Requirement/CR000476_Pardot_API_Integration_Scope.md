# CR000476 - Pardot (Account Engagement) REST API Integration for Amplify EULA Opt-In Data

## Summary of the Ask

The Macrobond engineering team (led by Thomas Olsson / Pawel Kudzia) needs to send **marketing opt-in data** collected during the **EULA acceptance process in Amplify** to **Pardot (Account Engagement)** via its REST API. This data currently lives on the CDS backend servers and needs to flow into Pardot so that Marketing (Marisa Watson / Steph Covert) can manage campaigns, subscriptions, and GDPR-compliant unsubscribe workflows.

### What They Really Want

1. **Automated pipeline**: CDS backend servers --> Pardot REST API --> syncs downstream to Salesforce
2. **Pardot as the system of record** for all opt-in/unsubscribe data (GDPR compliance requirement)
3. **Proper error handling** and transaction management (not achievable with form handlers)
4. **No additional browser-side dependencies** in the Amplify web app (firewall/security concerns)
5. **Future-proofing**: ability to add subscription management to the client self-service portal later

### Why Not Form Handlers?

Thomas and Pawel explicitly rejected Pardot form handlers because:
- Amplify is not an HTML form-based app; it cannot use web form integration patterns
- Form handlers offer no real error handling or transaction feedback
- Captcha-protected forms cannot be automated server-to-server
- Adding Pardot endpoints to the browser app increases firewall complexity and cybersecurity exposure
- Form handlers are intended for CMS/low-code tools (WebFlow, etc.), not system-to-system integration

---

## Current State of Pardot Infrastructure in Salesforce Org

### Already Configured (reduces effort significantly)

| Component | Status | Details |
|-----------|--------|---------|
| **Connected App: `Pardot_API`** | Deployed | OAuth scopes: Api, Full, Pardot. Callback: `https://macrobond.lightning.force.com`. Zero refresh token policy. |
| **Connected App: `Macrobond_Pardot_Integration`** | Deployed | OAuth scope: Pardot. Infinite refresh token. IP enforcement enabled. Originally set up by Knowit consultants (simon.glimeld@knowit.se). |
| **User Pardot Fields** | Deployed | `pi__Pardot_Api_Key__c`, `pi__Pardot_User_Id__c`, `pi__Pardot_User_Key__c`, `pi__Pardot_Api_Version__c`, `pi__Pardot_User_Role__c` (all EncryptedText) |
| **Permission Set: `Pardot_Lightning_App_Access`** | Deployed | Grants PardotUser permission |
| **Marketing Administrator Permission Set** | Deployed | Includes Pardot access |
| **Pardot App (Account Engagement)** | Available | `standard__PardotAppV1` in app switcher |

### Not Yet Configured (work required)

| Component | Status | What's Needed |
|-----------|--------|---------------|
| **Server-to-Server OAuth Flow** | Not configured | The existing Connected Apps use Authorization Code flow. For CDS backend integration, need Client Credentials flow or JWT Bearer Token flow enabled. |
| **Pardot Business Unit ID mapping** | Unknown | Need to identify the correct Pardot Business Unit ID for API calls |
| **List / Campaign setup in Pardot** | Pending Marisa | Marketing needs to create the target list(s) and provide list IDs |
| **Field mapping (CDS --> Pardot Prospect)** | Not defined | Need to map EULA questionnaire fields to Pardot prospect fields |
| **Integration User / Service Account** | Not confirmed | Need a dedicated service account for API authentication (not a named user) |

---

## Technical Scope

### Architecture

```
Amplify App (Browser)
       |
       | (EULA acceptance + marketing opt-in)
       v
CDS Backend Servers (Macrobond infrastructure)
       |
       | (Scheduled pipeline / event-driven)
       v
Pardot REST API v5 (via Salesforce OAuth 2.0)
       |
       | (Native Pardot-to-Salesforce sync)
       v
Salesforce CRM (downstream, automatic)
```

### Work Breakdown

#### Phase 1: Authentication Setup (Salesforce Admin Side)

1. **Modify or create a Connected App for server-to-server flow**
   - Enable Client Credentials flow OR JWT Bearer Token flow on an existing Connected App
   - The `Macrobond_Pardot_Integration` app already has infinite refresh tokens and Pardot scope -- this is the most likely candidate to reconfigure
   - Alternatively, create a new Connected App specifically for CDS server-to-server integration
   - Assign a dedicated Integration User as the "Run As" user

2. **Configure Pardot API access rights**
   - Ensure the integration user has the `Pardot_Lightning_App_Access` permission set
   - Verify the Pardot Business Unit ID
   - Confirm API v5 access is enabled

3. **Test authentication**
   - Obtain access token via OAuth flow
   - Make test API call to `GET /api/v5/objects/prospects` to verify connectivity

**Salesforce admin support needed**: Lauren's new Salesforce admin contractor (mentioned by Steph Covert) can assist with Connected App configuration and permission assignment.

#### Phase 2: Pardot Campaign/List Setup (Marketing Side)

1. **Marisa to create target list(s) in Pardot** for Amplify EULA opt-ins
2. **Document the list IDs** via Pardot API: `GET /api/v5/objects/lists`
3. **Define field mapping** between CDS EULA data and Pardot Prospect fields:
   - Email address (required, primary key in Pardot)
   - First name, last name
   - Company / Account
   - Country
   - Marketing opt-in status
   - EULA acceptance date
   - EULA version
   - Any other questionnaire fields

#### Phase 3: Backend Pipeline Development (Pawel's Team - CDS Side)

1. **Build OAuth token management** in CDS backend
   - Implement token acquisition and refresh logic
   - Store credentials securely (not in source control)
   - Handle token expiration gracefully

2. **Build prospect upsert pipeline**
   - Extract EULA opt-in data from CDS database
   - Call Pardot API: `POST /api/v5/objects/prospects` (upsert by email)
   - Handle responses, log errors, implement retry logic

3. **Build list membership management**
   - Add opted-in prospects to the appropriate Pardot list: `POST /api/v5/objects/list-memberships`
   - Remove prospects who opt out

4. **Implement scheduling / triggering**
   - Option A: Event-driven (trigger on each EULA acceptance)
   - Option B: Batch (periodic sweep of new opt-ins from CDS)
   - Thomas mentioned all data is retained on the backend, so batch is viable

#### Phase 4: Testing

1. **Use Pardot sandbox/test environment** (Steph suggested this exists)
2. **Test with a small batch of records**
3. **Verify data appears correctly in Pardot** (prospect fields, list membership)
4. **Verify downstream sync to Salesforce** works correctly
5. **Verify GDPR audit trail** -- opt-in hits Pardot first, then syncs to Salesforce

---

## Level of Effort Assessment

| Work Item | Owner | Effort | Notes |
|-----------|-------|--------|-------|
| Connected App reconfiguration | Salesforce Admin (Lauren's contractor) | Low | Checkbox changes + permission assignment |
| Pardot list/campaign setup | Marisa (Marketing) | Low | Standard Pardot admin task |
| Field mapping definition | Marisa + Pawel (joint) | Low | Document mapping between CDS fields and Pardot fields |
| OAuth token management (CDS) | Pawel's backend team | Medium | Standard OAuth 2.0 client credentials implementation |
| Prospect upsert pipeline (CDS) | Pawel's backend team | Medium | REST API calls with error handling and retry |
| List membership management (CDS) | Pawel's backend team | Low | Simple API calls once prospects exist |
| End-to-end testing | Joint (Engineering + Marketing) | Medium | Need test environment access and validation |
| **Total Engineering Effort** | | **Medium** | Bulk of work is on CDS backend (Pawel's team), not Salesforce |

### Effort Context

- **This is a common integration pattern.** Pardot REST API v5 is well-documented and designed for exactly this use case.
- **Most of the OAuth infrastructure already exists** in the Salesforce org. Two Connected Apps with Pardot scopes are already deployed.
- **The CDS backend team already integrates with Salesforce**, so they have experience with Salesforce OAuth flows. Thomas specifically noted they could reuse the same authentication mechanism.
- **No Salesforce Apex development is required.** The integration is CDS --> Pardot API (external to Salesforce). No triggers, classes, or flows need to be built on the Salesforce side.
- **No changes to the Amplify frontend** are needed. The pipeline runs entirely on the backend.

---

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Pardot API rate limits | Low | Medium | Pardot v5 has generous limits (25k calls/day). Batch processing further reduces risk. |
| OAuth token expiration during batch | Low | Low | Standard refresh token handling. `Macrobond_Pardot_Integration` app already has infinite refresh tokens. |
| Field mapping mismatches | Medium | Low | Resolve during Phase 2 with joint definition session between Marketing and Engineering. |
| Pardot sandbox not available | Low | Medium | Can test with a dedicated test list in production Pardot if sandbox is unavailable. |
| GDPR compliance gap | Low | High | Mitigated by design: data flows to Pardot first (system of record), then syncs to Salesforce. Steph confirmed this approach is acceptable. |
| Pardot Business Unit ID unknown | Medium | Low | Easily discoverable via API or Pardot admin UI. |
| Integration user permissions | Low | Low | Permission sets already exist; just need assignment. |

### What Is NOT Risky

- **This is a standard, well-documented integration.** Salesforce/Pardot explicitly supports and recommends REST API v5 for system-to-system integrations.
- **No sensitive data flows through new channels.** Email, name, company, and opt-in status are standard marketing fields.
- **No architectural changes to Salesforce or Amplify.** This is an additive backend pipeline.

---

## Key Constraints (Agreed by All Parties)

1. **Data must flow to Pardot FIRST**, not Salesforce. Pardot is the system of record for opt-in/unsubscribe (GDPR). Pardot then syncs to Salesforce via its native connector.
2. **No Salesforce Apex development** for this integration. The API call originates from CDS, not from Salesforce.
3. **No changes to the Amplify browser app.** The integration is entirely server-side.
4. **All EULA data is already retained on CDS servers**, so this can be developed at the team's own pace without data loss.

---

## Dependencies / People Needed

| Person/Role | What's Needed From Them |
|-------------|------------------------|
| **Lauren's SF Admin Contractor** | Configure Connected App for server-to-server flow; assign permissions to integration user |
| **Marisa Watson (Marketing)** | Create Pardot list(s); define field mapping; validate test data in Pardot |
| **Steph Covert (RevOps)** | Final sign-off on GDPR compliance of the data flow |
| **Pawel Kudzia (Backend)** | Build the CDS-to-Pardot pipeline (OAuth + API calls) |
| **Thomas Olsson (Architecture)** | Technical oversight and architecture decisions |
| **Oliver Vander Horn** | Resource allocation / prioritization for Salesforce admin support |

---

## Future Enhancements (Out of Scope for This CR)

- **Client self-service portal**: Allow users to change subscription status via the portal, using the same Pardot API connection (mentioned by Thomas as a future possibility)
- **Bi-directional sync**: Reading unsubscribe status back from Pardot into Amplify
- **Additional Pardot campaigns/lists**: Once the pipeline exists, adding new campaigns is trivial

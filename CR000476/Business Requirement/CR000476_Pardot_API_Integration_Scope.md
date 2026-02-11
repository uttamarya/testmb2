# CR000476 - Pardot (Account Engagement) REST API Integration for Amplify EULA Opt-In Data

---

## 1. Business Context: Why Does This Exist?

Macrobond is rolling out a new **EULA (End User License Agreement) acceptance flow** inside their product **Amplify**. As part of onboarding, users are asked whether they consent to receiving marketing communications. This is a standard opt-in question required by **GDPR** and other privacy regulations.

Today, when a user accepts the EULA and checks (or unchecks) the marketing opt-in box, that data is stored on Macrobond's **CDS backend servers** -- but it goes nowhere else. **Marketing has no visibility into it.** They can't add opted-in users to email campaigns, nurture sequences, or newsletters. They also can't honour unsubscribe requests properly because the data never reaches their marketing automation platform.

**The business problem:** Marketing consent data is trapped in the engineering backend, disconnected from the marketing tools that need it to operate legally and effectively.

**The business goal:** Create an automated pipeline so that every time a user opts in (or out) of marketing during the Amplify EULA process, that preference flows automatically into **Pardot (now called Marketing Cloud Account Engagement)**, which is Macrobond's marketing automation system and the **single source of truth for all opt-in/unsubscribe records** (required for GDPR compliance).

---

## 2. How the Conversation Unfolded (Chronological)

### Thomas Olsson starts the investigation (Feb 10, morning)
**Role:** Technical leadership / Architecture

Thomas emails the backend dev team: *"Can we figure out how to get EULA opt-in data from Amplify into Pardot?"* He does initial research, finds the Pardot API uses "lists" for campaign memberships, and suggests a small test before building the full solution. He's unsure about authentication but suspects it may reuse the existing Salesforce OAuth setup.

**Business rationale:** Without this connection, Marketing can't run campaigns to users who opted in, and can't prove GDPR compliance for users who opted out.

### Pawel Kudzia confirms feasibility, flags a blocker (Feb 10, ~10:48 AM)
**Role:** Head of Backend R&D and IT Security

Pawel says: *"We can easily extract the EULA data from CDS servers. The blocker is we can't find anyone on the Pardot/Marketing side to help us configure it."* He needs API keys and a technical counterpart. Notes that Marisa previously suggested using a web form, but **captcha-protected forms cannot be automated server-to-server** -- pretending to be a browser user would be fragile and unreliable.

**Business rationale:** The engineering team is ready to build, but cross-functional collaboration with Marketing ops is needed for configuration. The form-based approach doesn't work for backend automation.

### Thomas suggests reusing Salesforce OAuth (Feb 10, ~12:03 PM)

Thomas finds that Pardot now uses Salesforce's OAuth system for authentication. Since Macrobond already integrates with Salesforce, they may be able to reuse the same auth mechanism. He links the Salesforce developer blog on setting up OAuth for Pardot.

**Business rationale:** Reusing existing authentication reduces cost, complexity, and time-to-delivery.

### Marisa Watson pushes back -- recommends Form Handlers (Feb 10, 1:08 PM)
**Role:** Head of Marketing

Marisa recommends sticking with **Pardot form handlers** (the same approach used for their Webflow-based websites). She argues this is proven, consistent with existing processes, and avoids unnecessary technical complexity. She emphasizes that data **must hit Pardot before Salesforce** to maintain GDPR-compliant unsubscribe management. She loops in Oliver Vander Horn, noting that the API path would require resourcing from his team.

**Business rationale:** Marketing prefers the approach they already know and manage. Form handlers work for their website forms (built on Webflow). Her GDPR concern is valid and critical -- Pardot must remain the system of record for consent.

### Pawel asks about the form handler endpoint (Feb 10, ~1:11 PM)

Pawel tries to work with Marisa's suggestion. He asks: *"If your form handler URL accepts JSON and there's no captcha, we can use it. What format does it need?"* He shares a screenshot of a captcha-protected form to illustrate why automated form submission is unreliable.

**Business rationale:** Engineering is trying to find common ground, but needs a programmatic endpoint that works for server-to-server communication.

### Marisa clarifies: form is Webflow, handler is Pardot (Feb 10, ~1:19 PM)

Marisa explains the architecture: the form on the website is built on **Webflow** (a CMS tool), and the Pardot form handler just listens for submitted data. Captcha is on the Webflow side, not Pardot. She says she'll look up what data formats the handler accepts.

### Marisa reports back: JSON requires the API (Feb 10, 2:49 PM)

Marisa confirms: **Form handlers can accept HTTP POST, but for JSON data, they need the full Pardot API.** She asks whether HTTP POST is sufficient or if they should set up the API, noting it would need Oliver's team.

**Business rationale:** This is the pivotal moment -- the form handler approach has a technical limitation that forces the API decision.

### Thomas makes the call: use the proper API (Feb 10, ~2:01 PM)

Thomas firmly recommends the **Pardot REST API** over form handlers. His reasoning:
- Form handlers are designed for retrofitting HTML web forms (like Webflow) -- Amplify is not that
- The API gives **real error handling** (if something fails, you know about it and can retry)
- The API enables **future capabilities** like letting users manage their own subscriptions in a self-service portal
- The OAuth setup documentation looks straightforward

**Business rationale:** The API is the right tool for the job. Using form handlers for server-to-server integration is using the wrong tool -- it works for website forms but not for backend pipelines. The API also unlocks future product features (self-service subscription management) that form handlers never could.

### Jess McClorey escalates to Steph Covert after SteerCo (Feb 10, ~4:43 PM)
**Role:** Jess -- Project Management; Steph -- RevOps

After a Steering Committee meeting, Steph asked why an API was being proposed. Jess forwards the full email chain for context.

**Business rationale:** Leadership wants to understand why the simpler approach (form handlers) was rejected and whether the API approach introduces unnecessary risk or cost.

### Steph Covert gives conditional approval (Feb 10, ~7:40 PM)
**Role:** RevOps (owns compliance/audit concerns)

Steph says she generally agrees with the API approach, but raises a critical guard rail: **the REST API must connect directly to Pardot, NOT go through Salesforce Apex first.** Her concern:
- If data enters Salesforce first and then syncs to Pardot, the **GDPR audit trail breaks** -- there's no single source of truth for consent
- Pardot must remain the **first stop** for all opt-in data
- Salesforce should only get the data downstream via the native Pardot-to-SF sync

**Business rationale:** GDPR compliance is non-negotiable. If regulators audit Macrobond's consent management, there must be a clear, unambiguous chain: user opts in --> Pardot records it --> Salesforce gets a copy. Reversing this order creates legal risk.

### Thomas provides detailed technical justification (Feb 10, later)

Thomas addresses every concern comprehensively:
- Confirms the API is for **Pardot directly, not Salesforce Apex**
- Explains why the frontend/form approach doesn't work for Amplify:
  - Amplify is not a form-based HTML app
  - No proper error handling with forms (if Pardot is down, you don't know if the data was saved)
  - Don't want Pardot outages to **block new users from onboarding**
  - Fewer external endpoints in the browser = easier firewall setup for enterprise clients, reduced cybersecurity exposure
- Notes that **all EULA data is already stored on CDS servers**, so this can be built at any pace without losing data
- Suggests using **Pardot's test environment** for safe testing
- Points out that **Lauren's new Salesforce admin contractor** can help with OAuth configuration
- Mentions future possibility: **self-service subscription management** in the client portal

**Business rationale:** This is the most important email in the thread. Thomas establishes that the API approach is not only technically superior but also protects the business: it avoids creating a hard dependency on Pardot for user onboarding (if Pardot is down, users can still sign up), reduces client deployment friction (fewer firewall rules), and preserves data integrity (proper error handling means no silent failures).

### Steph confirms everyone is aligned (Feb 10, ~8:39 PM)

Steph says: *"Sounds like we're aligned on the REST API for Pardot."* Asks Marisa to connect with Lauren for Salesforce admin support.

**Business rationale:** Green light from RevOps/compliance. The approach satisfies GDPR requirements and all stakeholders.

---

## 3. Summary of the Ask

The Macrobond engineering team (led by Thomas Olsson / Pawel Kudzia) needs to send **marketing opt-in data** collected during the **EULA acceptance process in Amplify** to **Pardot (Account Engagement)** via its REST API. This data currently lives on the CDS backend servers and needs to flow into Pardot so that Marketing (Marisa Watson / Steph Covert) can manage campaigns, subscriptions, and GDPR-compliant unsubscribe workflows.

### What They Really Want

1. **Automated pipeline**: CDS backend servers --> Pardot REST API --> syncs downstream to Salesforce
   - *Business purpose:* Eliminates manual data transfer, ensures Marketing has real-time access to consent data, enables timely campaign execution
2. **Pardot as the system of record** for all opt-in/unsubscribe data (GDPR compliance requirement)
   - *Business purpose:* Legal requirement under GDPR. If audited, Macrobond must prove a single, authoritative source of consent records with a clear audit trail
3. **Proper error handling** and transaction management (not achievable with form handlers)
   - *Business purpose:* If a record fails to sync, the system knows and can retry. Silent failures mean users who opted in never get marketed to (lost revenue), or users who opted out still get emails (legal risk)
4. **No additional browser-side dependencies** in the Amplify web app (firewall/security concerns)
   - *Business purpose:* Macrobond's enterprise clients have strict firewall requirements. Every additional external endpoint the app connects to creates deployment friction and sales cycle delays
5. **Future-proofing**: ability to add subscription management to the client self-service portal later
   - *Business purpose:* Users could manage their own email preferences without contacting support, reducing operational overhead and improving user experience

### Why Not Form Handlers?

Thomas and Pawel explicitly rejected Pardot form handlers because:
- Amplify is not an HTML form-based app; it cannot use web form integration patterns
- Form handlers offer no real error handling or transaction feedback
- Captcha-protected forms cannot be automated server-to-server
- Adding Pardot endpoints to the browser app increases firewall complexity and cybersecurity exposure
- Form handlers are intended for CMS/low-code tools (WebFlow, etc.), not system-to-system integration

*Business context:* Form handlers work well for Macrobond's marketing website (which runs on Webflow). But Amplify is a B2B analytics product -- a rich web application, not a web page with forms. Using form handlers for this would be like using a screwdriver to hammer a nail -- technically possible in some cases, but fragile and wrong for the job.

---

## 4. Current State of Pardot Infrastructure in Salesforce Org

*Business context:* Before estimating effort, it's important to know what already exists. A significant amount of Pardot infrastructure is already deployed in the Salesforce org, which substantially reduces the work required.

### Already Configured (reduces effort significantly)

| Component | Status | Details | Business Implication |
|-----------|--------|---------|---------------------|
| **Connected App: `Pardot_API`** | Deployed | OAuth scopes: Api, Full, Pardot. Callback: `https://macrobond.lightning.force.com`. Zero refresh token policy. | Authentication plumbing already exists -- no need to build from scratch |
| **Connected App: `Macrobond_Pardot_Integration`** | Deployed | OAuth scope: Pardot. Infinite refresh token. IP enforcement enabled. Originally set up by Knowit consultants. | Purpose-built for Pardot integration; has the right scope and token policy for ongoing automation |
| **User Pardot Fields** | Deployed | `pi__Pardot_Api_Key__c`, `pi__Pardot_User_Id__c`, `pi__Pardot_User_Key__c`, `pi__Pardot_Api_Version__c`, `pi__Pardot_User_Role__c` (all EncryptedText) | User-level Pardot mapping is already supported in the data model |
| **Permission Set: `Pardot_Lightning_App_Access`** | Deployed | Grants PardotUser permission | Access control framework is ready; just needs assignment |
| **Marketing Administrator Permission Set** | Deployed | Includes Pardot access | Marketing team already has appropriate permissions |
| **Pardot App (Account Engagement)** | Available | `standard__PardotAppV1` in app switcher | Pardot UI is accessible for Marketing to manage lists/campaigns |

### Not Yet Configured (work required)

| Component | Status | What's Needed | Business Implication |
|-----------|--------|---------------|---------------------|
| **Server-to-Server OAuth Flow** | Not configured | The existing Connected Apps use Authorization Code flow. For CDS backend integration, need Client Credentials flow or JWT Bearer Token flow enabled. | Required for automation -- without this, every API call would need a human to log in first |
| **Pardot Business Unit ID mapping** | Unknown | Need to identify the correct Pardot Business Unit ID for API calls | API calls won't work without this identifier -- it tells Pardot which business unit owns the data |
| **List / Campaign setup in Pardot** | Pending Marisa | Marketing needs to create the target list(s) and provide list IDs | Marketing decides how to organize opted-in users (e.g., "Amplify EULA Marketing Opt-In" list) |
| **Field mapping (CDS --> Pardot Prospect)** | Not defined | Need to map EULA questionnaire fields to Pardot prospect fields | Ensures the right data lands in the right fields -- critical for campaign segmentation and personalization |
| **Integration User / Service Account** | Not confirmed | Need a dedicated service account for API authentication (not a named user) | Best practice: a service account ensures the integration doesn't break when an employee leaves or changes roles |

---

## 5. Technical Scope

### Architecture

*Business context:* The architecture is designed so that the Amplify product is never directly coupled to Pardot. If Pardot goes down, users can still accept the EULA and onboard. The backend stores everything and syncs to Pardot asynchronously. This protects the user experience and avoids creating a hard dependency on a third-party marketing tool in the critical onboarding path.

```
Amplify App (Browser)
       |
       | User accepts EULA, checks marketing opt-in box
       v
CDS Backend Servers (Macrobond infrastructure)
       |
       | Stores consent data locally (no data loss even if Pardot is down)
       | Asynchronous pipeline pushes to Pardot
       v
Pardot REST API v5 (via Salesforce OAuth 2.0)
       |
       | Pardot = system of record for consent (GDPR)
       | Native Pardot-to-Salesforce sync (automatic, no custom code)
       v
Salesforce CRM (downstream copy for Sales team visibility)
```

### Work Breakdown

#### Phase 1: Authentication Setup (Salesforce Admin Side)

*Business purpose:* Establish the secure "handshake" that allows the CDS backend to talk to Pardot programmatically, without a human logging in each time.

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

*Business purpose:* Marketing needs to define WHERE the opt-in data lands in Pardot. Lists and campaigns are how Pardot organizes contacts for email sends, automation rules, and reporting. Without this, the data goes into Pardot but Marketing can't act on it.

1. **Marisa to create target list(s) in Pardot** for Amplify EULA opt-ins
   - e.g., a list called "Amplify EULA - Marketing Opt-In" that Marketing can use to target opted-in users for campaigns
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

*Business purpose:* This is the core engineering work -- building the automated pipeline that moves data from Macrobond's servers into Pardot. Once built, this runs unattended and ensures Marketing always has up-to-date consent data.

1. **Build OAuth token management** in CDS backend
   - Implement token acquisition and refresh logic
   - Store credentials securely (not in source control)
   - Handle token expiration gracefully

2. **Build prospect upsert pipeline**
   - Extract EULA opt-in data from CDS database
   - Call Pardot API: `POST /api/v5/objects/prospects` (upsert by email)
   - Handle responses, log errors, implement retry logic
   - *Business note:* "Upsert" means if the prospect already exists in Pardot (e.g., from a website form submission), it updates their record rather than creating a duplicate

3. **Build list membership management**
   - Add opted-in prospects to the appropriate Pardot list: `POST /api/v5/objects/list-memberships`
   - Remove prospects who opt out
   - *Business note:* This is how Marketing knows who to email and who not to -- getting this wrong means either missed marketing opportunities or GDPR violations

4. **Implement scheduling / triggering**
   - Option A: Event-driven (trigger on each EULA acceptance) -- faster but more complex
   - Option B: Batch (periodic sweep of new opt-ins from CDS) -- simpler, slight delay
   - Thomas mentioned all data is retained on the backend, so batch is viable and no data is lost between sweeps

#### Phase 4: Testing

*Business purpose:* Validate that the complete flow works end-to-end before going live. This protects against consent data being lost, duplicated, or misattributed -- any of which would have GDPR implications.

1. **Use Pardot sandbox/test environment** (Steph suggested this exists)
2. **Test with a small batch of records**
3. **Verify data appears correctly in Pardot** (prospect fields, list membership)
4. **Verify downstream sync to Salesforce** works correctly
5. **Verify GDPR audit trail** -- opt-in hits Pardot first, then syncs to Salesforce
6. **Marketing validates** -- Marisa confirms she can see the test prospects in the correct list and can use them for campaign targeting

---

## 6. Level of Effort Assessment

*Business context:* The total effort is **Medium**, and most of it falls on Pawel's backend team (CDS side), not on the Salesforce/Marketing side. The Salesforce org already has most of the OAuth infrastructure deployed, which significantly reduces the setup work.

| Work Item | Owner | Effort | Business Notes |
|-----------|-------|--------|----------------|
| Connected App reconfiguration | Salesforce Admin (Lauren's contractor) | Low | Checkbox-level changes + permission assignment. No development. |
| Pardot list/campaign setup | Marisa (Marketing) | Low | Standard Pardot admin task that Marketing does regularly for website campaigns. |
| Field mapping definition | Marisa + Pawel (joint) | Low | One meeting to agree on which CDS fields map to which Pardot fields. |
| OAuth token management (CDS) | Pawel's backend team | Medium | Standard OAuth 2.0 implementation. Team already has experience with SF OAuth. |
| Prospect upsert pipeline (CDS) | Pawel's backend team | Medium | REST API calls with error handling. Core deliverable. |
| List membership management (CDS) | Pawel's backend team | Low | Simple API calls once prospects are created. |
| End-to-end testing | Joint (Engineering + Marketing) | Medium | Requires coordination but no heavy development. |
| **Total Engineering Effort** | | **Medium** | Bulk of work is on CDS backend (Pawel's team), not Salesforce |

### Effort Context

- **This is a common integration pattern.** Pardot REST API v5 is well-documented and designed for exactly this use case (system-to-system opt-in management).
- **Most of the OAuth infrastructure already exists** in the Salesforce org. Two Connected Apps with Pardot scopes are already deployed.
- **The CDS backend team already integrates with Salesforce**, so they have experience with Salesforce OAuth flows. Thomas specifically noted they could reuse the same authentication mechanism.
- **No Salesforce Apex development is required.** The integration is CDS --> Pardot API (external to Salesforce). No triggers, classes, or flows need to be built on the Salesforce side.
- **No changes to the Amplify frontend** are needed. The pipeline runs entirely on the backend. Users won't see any difference.

---

## 7. Risk Assessment

*Business context:* The risks are low overall. This is a well-trodden integration path that Salesforce explicitly supports. The biggest risk area is organizational (coordination between teams), not technical.

| Risk | Likelihood | Impact | Mitigation | Business Impact if Realized |
|------|-----------|--------|------------|---------------------------|
| Pardot API rate limits | Low | Medium | Pardot v5 has generous limits (25k calls/day). Batch processing further reduces risk. | Temporary delay in consent data reaching Marketing; no data loss since CDS retains everything |
| OAuth token expiration during batch | Low | Low | Standard refresh token handling. Existing app has infinite refresh tokens. | Brief sync pause; auto-recovers on next batch run |
| Field mapping mismatches | Medium | Low | Joint definition session between Marketing and Engineering in Phase 2. | Wrong data in wrong Pardot fields; fixable with re-mapping and re-sync |
| Pardot sandbox not available | Low | Medium | Can test with a dedicated test list in production Pardot if sandbox unavailable. | Testing is slightly riskier but still manageable |
| GDPR compliance gap | Low | High | Mitigated by design: data flows to Pardot first (system of record), then syncs to Salesforce. Steph confirmed this. | If data went to SF first, audit trail breaks. Regulatory fines possible. This design prevents that. |
| Pardot Business Unit ID unknown | Medium | Low | Easily discoverable via API or Pardot admin UI. | Blocks API calls until identified; quick fix once found |
| Integration user permissions | Low | Low | Permission sets already exist; just need assignment. | API calls fail with 403; resolved by assigning the correct permission set |
| Cross-team coordination delays | Medium | Medium | Clear ownership table (Section 9). Steph already confirmed alignment. | Timeline slips if Marketing or Admin don't complete their phases on time |

### What Is NOT Risky

- **This is a standard, well-documented integration.** Salesforce/Pardot explicitly supports and recommends REST API v5 for system-to-system integrations. This is not experimental or unusual.
- **No sensitive data flows through new channels.** Email, name, company, and opt-in status are standard marketing fields -- no payment data, no passwords, no PII beyond what Pardot already handles.
- **No architectural changes to Salesforce or Amplify.** This is an additive backend pipeline. Nothing existing is modified or at risk.
- **No data loss risk.** All EULA data is retained on CDS servers regardless of whether Pardot is available. The pipeline can be paused, restarted, or re-run without losing records.

---

## 8. Key Constraints (Agreed by All Parties)

*Business context:* These are non-negotiable requirements that emerged from the discussion. All stakeholders (Engineering, Marketing, RevOps) have confirmed alignment.

1. **Data must flow to Pardot FIRST**, not Salesforce. Pardot is the system of record for opt-in/unsubscribe (GDPR). Pardot then syncs to Salesforce via its native connector.
   - *Why:* Steph Covert (RevOps) was explicit -- if data enters Salesforce first and pushes to Pardot, it "could cause complicated audit trail and compliance issues as we would not have a single source of truth." GDPR requires a clear, traceable consent record.

2. **No Salesforce Apex development** for this integration. The API call originates from CDS, not from Salesforce.
   - *Why:* Apex development would mean data enters Salesforce first (violating constraint #1) and adds ongoing maintenance burden on the Salesforce team.

3. **No changes to the Amplify browser app.** The integration is entirely server-side.
   - *Why:* Thomas listed three reasons: (a) Amplify is not a form app, (b) don't want Pardot downtime to block user onboarding, (c) fewer external endpoints = easier enterprise client deployments.

4. **All EULA data is already retained on CDS servers**, so this can be developed at the team's own pace without data loss.
   - *Why:* No urgency pressure. Users onboarding now are not losing their consent data. The pipeline can be built and tested properly without cutting corners.

---

## 9. Dependencies / People Needed

*Business context:* This is a cross-functional effort. No single team can deliver it alone. The table below clarifies who owns what so there are no gaps or finger-pointing.

| Person/Role | What's Needed From Them | Why |
|-------------|------------------------|-----|
| **Lauren's SF Admin Contractor** | Configure Connected App for server-to-server flow; assign permissions to integration user | Without this, the CDS backend cannot authenticate to Pardot's API |
| **Marisa Watson (Marketing)** | Create Pardot list(s); define field mapping; validate test data in Pardot | Marketing owns the Pardot configuration and must confirm the data lands correctly for their campaign workflows |
| **Steph Covert (RevOps)** | Final sign-off on GDPR compliance of the data flow | RevOps owns compliance; they've conditionally approved but need to validate the final implementation |
| **Pawel Kudzia (Backend)** | Build the CDS-to-Pardot pipeline (OAuth + API calls) | Engineering owns the pipeline code that moves data from CDS to Pardot |
| **Thomas Olsson (Architecture)** | Technical oversight and architecture decisions | Thomas defined the architecture and needs to validate the implementation matches his design intent |
| **Oliver Vander Horn** | Resource allocation / prioritization for Salesforce admin support | Oliver's team is the bridge for any Salesforce-side configuration that Lauren's contractor needs guidance on |

---

## 10. Future Enhancements (Out of Scope for This CR)

*Business context:* Once the Pardot API pipeline exists, it opens the door to additional capabilities that currently aren't possible. These are not part of this CR but should be considered when evaluating the long-term value of the API investment.

- **Client self-service portal**: Allow users to change their marketing subscription status directly from the Macrobond portal, using the same Pardot API connection. *Business value:* Reduces support tickets, improves user autonomy, demonstrates GDPR transparency.
- **Bi-directional sync**: Read unsubscribe status back from Pardot into Amplify, so the product can display current consent status to users. *Business value:* Users see accurate, up-to-date consent status in the product.
- **Additional Pardot campaigns/lists**: Once the pipeline exists, adding new campaign lists is trivial (just a new list ID). *Business value:* Marketing can create targeted segments (e.g., by country, by product tier) without needing additional engineering work.
- **Event-driven notifications**: Trigger real-time Pardot automations when a user opts in (e.g., send a welcome email immediately). *Business value:* Better user experience, higher engagement with timely communications.

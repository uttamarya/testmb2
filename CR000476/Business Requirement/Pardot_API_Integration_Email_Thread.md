# Pardot API Integration for Amplify EULA - Email Thread

---

**From:** Uttam Arya <uttam.arya@macrobond.com>
**Sent:** 17 February 2026
**To:** Oliver Vander Horn <oliver.vanderhorn@macrobond.com>; Marisa Watson <marisa.watson@macrobond.com>; Hugh Diamond <hugh.diamond@macrobond.com>; Thomas Olsson <thomas.olsson@macrobond.com>
**Subject:** Pardot REST API Integration for Amplify EULA Opt-In Data - Plan & Next Steps

Hi Oliver, Marisa, Hugh, and Thomas,

Following the discussion around getting EULA marketing opt-in data from Amplify into Pardot, I have cross-checked the feasibility and can confirm that it is possible to set up Salesforce OAuth-based API access to Pardot (Account Engagement) using the REST API v5. Thomas had referenced the Salesforce developer blog on this topic, and I have reviewed the setup guide here:
https://developer.salesforce.com/blogs/2020/11/setting-up-salesforce-oauth-for-pardot-api-authentication

The approach is to use Salesforce OAuth 2.0 authentication to obtain access tokens that allow our CDS backend servers to communicate directly with the Pardot REST API. This means we can programmatically create and update prospect records in Pardot and manage list memberships — which is exactly what is needed to sync the marketing opt-in/opt-out preferences that users submit during the EULA acceptance flow in Amplify.

To provide some context on the EULA flow: when users onboard onto Amplify, they are presented with an End User License Agreement (EULA) that includes a marketing consent checkbox. This is a standard GDPR-required opt-in question. Currently, this consent data is captured and stored on our CDS backend servers, but it does not flow to Pardot. As a result, Marketing has no visibility into which users have opted in or out, meaning they cannot include opted-in users in email campaigns or properly honour opt-out requests. The goal of this integration is to bridge that gap by sending consent data directly to Pardot — which remains the single source of truth for all opt-in/unsubscribe records as required for GDPR compliance. Importantly, as Steph Covert confirmed, data must flow to Pardot first, and then sync downstream to Salesforce via the native Pardot-to-Salesforce connector — not the other way around.

One important note: **we do not have a dedicated Pardot sandbox environment**. This means we will not have a fully isolated test environment available. In my opinion, testing will need to be done carefully in the production Pardot instance using dedicated test records.

Here is how I propose we approach this in two phases:

## Phase I — Establish the Connection

The goal of Phase I is to set up the authentication and confirm that we can successfully connect to the Pardot REST API from our backend.

- I will create a dedicated production user (integration/service account) in Salesforce for this purpose.
- I will configure the Connected App to enable server-to-server OAuth flow (Client Credentials or JWT Bearer Token) with the appropriate Pardot API scopes.
- I will generate the API credentials (Consumer Key, Consumer Secret) and provide them to Thomas and the backend team.
- We will verify connectivity by making a test API call (e.g., `GET /api/v5/objects/prospects`) to confirm authentication works end-to-end.
- I will also identify and confirm the Pardot Business Unit ID required for API calls.

This phase is relatively low effort — it is primarily configuration and credential setup on the Salesforce/Pardot side.

## Phase II — Collection/List Testing & Data Flow Validation

Once the connection is established, Phase II focuses on validating the actual data flow using Pardot lists (collections).

- **Marisa, I would need your assistance here.** Since you manage the Pardot lists and campaign structure, could you help with the following:
  - Create a test list in Pardot (e.g., "Amplify EULA - Marketing Opt-In Test") that we can use for validation.
  - Provide the list ID so Thomas's team can target it in their API calls.
  - Define the field mapping — which fields from the EULA data (email, first name, last name, company, country, opt-in status, EULA version, acceptance date) should map to which Pardot prospect fields.
  - Validate the test data once it appears in Pardot to confirm it meets your campaign and segmentation requirements.

- The backend team will then test the prospect upsert (create/update by email) and list membership management (adding opted-in users, removing opted-out users) against this test list in production.

- We will verify the downstream sync to Salesforce works correctly via the native Pardot-to-Salesforce connector, and confirm the GDPR audit trail is maintained (data enters Pardot first, then syncs to Salesforce).

Since we are working in production Pardot without a sandbox, I would recommend we keep the test list clearly labelled and isolated so it does not interfere with any active marketing campaigns. Alternatively, I can look at this separately if there is a preferred approach for testing in production that Marisa or Steph would recommend.

**Questions / Clarifications Needed:**

1. @Marisa — Are you able to create and manage the test list in Pardot for Phase II? And can you provide guidance on the field mapping between our EULA data and Pardot prospect fields?
2. @Thomas — Once I provide the API credentials from Phase I, does your team have everything needed to begin building the OAuth token management and prospect upsert pipeline on the CDS side?
3. Does anyone have concerns about testing in production Pardot given the lack of a sandbox? If so, I am happy to discuss alternative approaches.

Please let me know if you need any additional information or if there are other considerations I should account for.

Regards,
Uttam Arya
uttam.arya@macrobond.com

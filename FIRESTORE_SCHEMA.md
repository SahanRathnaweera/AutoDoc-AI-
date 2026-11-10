# 🗄️ AutoDoc AI – Cloud Firestore Schema Architecture

This document specifies the database structure, data types, indexing, and relationships for the AutoDoc AI automated vehicle inspection and valuation platform.

---

## 📌 Architecture Principles
1. **Normalized Document Root**: Major entities (`users`, `vehicles`, `inspections`, `reports`, `marketplace_listings`) reside at top-level collections to allow decoupled querying, security rule enforcement, and independent scaling.
2. **Metadata Separation**: Binary assets (images, engine audio clips, PDF reports) are stored in Firebase Storage; Firestore documents retain only cloud storage URIs and signed metadata.
3. **Audit Trail**: Every document contains server-generated `createdAt` and `updatedAt` timestamps.
4. **Role-Based Access**: Document fields define user roles (`client`, `inspector`, `admin`) to govern security boundaries.

---

## 1. Collections & Document Structures

### 1.1 `users` Collection
* **Path**: `/users/{uid}`
* **Document ID**: Firebase Authentication User UID (`auth.uid`)
* **Purpose**: User profile, role identification, contact details, and account metadata.

| Field | Type | Description | Required | Example |
|---|---|---|---|---|
| `uid` | `string` | Unique authentication identifier | Yes | `"a8F9z0K1pL..."` |
| `email` | `string` | User's verified email address | Yes | `"driver@example.com"` |
| `displayName` | `string?` | Full name of the user | No | `"John Doe"` |
| `phoneNumber` | `string?` | Mobile contact number | No | `"+94771234567"` |
| `photoUrl` | `string?` | Storage URL for profile picture | No | `"gs://.../profile.jpg"` |
| `role` | `string` | User role (`client`, `inspector`, `admin`) | Yes | `"client"` |
| `isEmailVerified` | `boolean`| Email verification status | Yes | `true` |
| `createdAt` | `timestamp` | Profile creation timestamp | Yes | `2026-09-26T10:00:00Z` |
| `updatedAt` | `timestamp` | Last profile update timestamp | Yes | `2026-09-26T10:00:00Z` |

---

### 1.2 `vehicles` Collection
* **Path**: `/vehicles/{vehicleId}`
* **Document ID**: Auto-generated UUID or alphanumeric identifier
* **Purpose**: Vehicle identification, registration records, specifications, and ownership details.

| Field | Type | Description | Required | Example |
|---|---|---|---|---|
| `vehicleId` | `string` | Unique vehicle identifier | Yes | `"veh_91823746"` |
| `ownerId` | `string` | Reference to `/users/{uid}` | Yes | `"a8F9z0K1pL..."` |
| `registrationNumber` | `string` | License plate / registration | Yes | `"CAB-4521"` |
| `chassisNumber` | `string` | Vehicle Identification Number (VIN) | Yes | `"JTDBR32E220194821"` |
| `engineNumber` | `string` | Engine block serial number | No | `"1NZ-FE-98214"` |
| `make` | `string` | Manufacturer brand | Yes | `"Toyota"` |
| `model` | `string` | Vehicle model | Yes | `"Corolla"` |
| `year` | `number` | Year of manufacture | Yes | `2019` |
| `odometer` | `number` | Current mileage in km | Yes | `68500` |
| `fuelType` | `string` | Fuel type (`petrol`, `diesel`, `hybrid`, `ev`) | No | `"petrol"` |
| `transmission` | `string` | Transmission (`automatic`, `manual`) | No | `"automatic"` |
| `documentUrls` | `array<string>` | Storage URLs for registration doc scans | No | `["gs://.../doc1.pdf"]` |
| `createdAt` | `timestamp` | Registration date | Yes | `2026-09-26T10:00:00Z` |
| `updatedAt` | `timestamp` | Record update date | Yes | `2026-09-26T10:00:00Z` |

---

### 1.3 `inspections` Collection
* **Path**: `/inspections/{inspectionId}`
* **Document ID**: Auto-generated UUID
* **Purpose**: Central inspection workflow session tracking status, overall score, and associations.

| Field | Type | Description | Required | Example |
|---|---|---|---|---|
| `inspectionId` | `string` | Unique inspection session ID | Yes | `"insp_88231"` |
| `vehicleId` | `string` | Reference to `/vehicles/{vehicleId}` | Yes | `"veh_91823746"` |
| `userId` | `string` | Reference to `/users/{uid}` (client) | Yes | `"a8F9z0K1pL..."` |
| `inspectorId` | `string?` | Assigned certified inspector UID | No | `"insp_uid_772"` |
| `status` | `string` | Session status (`pending`, `in_progress`, `analyzing`, `completed`, `cancelled`) | Yes | `"completed"` |
| `inspectionDate` | `timestamp` | Scheduled/completed date | Yes | `2026-09-26T12:00:00Z` |
| `overallScore` | `number` | Composite health score (0 - 100) | No | `87.5` |
| `damageScore` | `number?` | Exterior visual condition score | No | `85.0` |
| `engineScore` | `number?` | Acoustic health score | No | `90.0` |
| `createdAt` | `timestamp` | Session created timestamp | Yes | `2026-09-26T10:00:00Z` |
| `updatedAt` | `timestamp` | Session last modified timestamp | Yes | `2026-09-26T12:30:00Z` |

---

### 1.4 `damage_results` Collection
* **Path**: `/damage_results/{damageId}`
* **Document ID**: Auto-generated UUID
* **Purpose**: AI visual damage detection results from 360° vehicle captures.

| Field | Type | Description | Required | Example |
|---|---|---|---|---|
| `damageId` | `string` | Unique damage item ID | Yes | `"dmg_3012"` |
| `inspectionId` | `string` | Reference to `/inspections/{inspectionId}` | Yes | `"insp_88231"` |
| `vehicleId` | `string` | Reference to `/vehicles/{vehicleId}` | Yes | `"veh_91823746"` |
| `imageStoragePath`| `string` | Storage path to original inspection photo | Yes | `"inspections/insp_88231/images/front_bumper.jpg"` |
| `annotatedImagePath`| `string?`| Storage path to AI-annotated bounding box image | No | `"inspections/insp_88231/images/front_bumper_bbox.jpg"` |
| `damageType` | `string` | Classified type (`dent`, `scratch`, `crack`, `paint_chip`, `rust`) | Yes | `"dent"` |
| `severity` | `string` | Severity rating (`minor`, `moderate`, `severe`) | Yes | `"moderate"` |
| `confidence` | `number` | AI model detection confidence (0.00 - 1.00) | Yes | `0.94` |
| `bodyLocation` | `string` | Vehicle zone (`front_bumper`, `left_door`, etc.) | Yes | `"front_bumper"` |
| `estimatedRepairCost`| `number?` | Pre-valuation repair estimate | No | `150.00` |
| `createdAt` | `timestamp` | Detection timestamp | Yes | `2026-09-26T12:10:00Z` |

---

### 1.5 `engine_diagnostics` Collection
* **Path**: `/engine_diagnostics/{diagnosticId}`
* **Document ID**: Auto-generated UUID
* **Purpose**: Acoustic engine sound recording analysis and anomaly classification.

| Field | Type | Description | Required | Example |
|---|---|---|---|---|
| `diagnosticId` | `string` | Unique diagnostic record ID | Yes | `"eng_5521"` |
| `inspectionId` | `string` | Reference to `/inspections/{inspectionId}` | Yes | `"insp_88231"` |
| `vehicleId` | `string` | Reference to `/vehicles/{vehicleId}` | Yes | `"veh_91823746"` |
| `audioStoragePath`| `string` | Storage path to recorded engine sound file | Yes | `"inspections/insp_88231/audio/engine_idle.wav"` |
| `durationSeconds` | `number` | Audio clip duration | Yes | `15.2` |
| `status` | `string` | Analysis state (`uploaded`, `processing`, `completed`, `failed`) | Yes | `"completed"` |
| `anomalyDetected` | `boolean`| Flag indicating engine noise anomaly | Yes | `false` |
| `anomalyType` | `string?` | Anomaly label (`knocking`, `belt_squeal`, `valve_tap`, `normal`) | Yes | `"normal"` |
| `confidence` | `number` | AI classification confidence | Yes | `0.98` |
| `spectralFeatures`| `map?` | Key acoustic frequency characteristics | No | `{"rpm": 780, "freq_peak": 120.4}` |
| `createdAt` | `timestamp` | Record creation timestamp | Yes | `2026-09-26T12:15:00Z` |

---

### 1.6 `ocr_results` Collection
* **Path**: `/ocr_results/{ocrId}`
* **Document ID**: Auto-generated UUID
* **Purpose**: Text and data extracted from vehicle registration books, revenue licenses, and insurance cards.

| Field | Type | Description | Required | Example |
|---|---|---|---|---|
| `ocrId` | `string` | Unique OCR session ID | Yes | `"ocr_441"` |
| `vehicleId` | `string` | Reference to `/vehicles/{vehicleId}` | Yes | `"veh_91823746"` |
| `documentType` | `string` | Document type (`registration_card`, `license`, `insurance`) | Yes | `"registration_card"` |
| `documentStoragePath`| `string`| Storage path to scanned image | Yes | `"vehicles/veh_91823746/documents/reg.jpg"` |
| `extractedData` | `map` | Key-value pairs extracted by OCR engine | Yes | `{"chassis": "JTDB...", "engine": "1NZ...", "year": 2019}` |
| `verificationStatus`| `string`| Match status (`matched`, `mismatch`, `manual_review`) | Yes | `"matched"` |
| `confidence` | `number` | OCR parsing accuracy score | Yes | `0.96` |
| `createdAt` | `timestamp` | Scan timestamp | Yes | `2026-09-26T10:05:00Z` |

---

### 1.7 `valuations` Collection
* **Path**: `/valuations/{valuationId}`
* **Document ID**: Auto-generated UUID
* **Purpose**: Algorithmic market valuation calculation derived from vehicle specs, health scores, and damage deductions.

| Field | Type | Description | Required | Example |
|---|---|---|---|---|
| `valuationId` | `string` | Unique valuation ID | Yes | `"val_1092"` |
| `inspectionId` | `string` | Reference to `/inspections/{inspectionId}` | Yes | `"insp_88231"` |
| `vehicleId` | `string` | Reference to `/vehicles/{vehicleId}` | Yes | `"veh_91823746"` |
| `baseMarketValue`| `number` | Unadjusted market baseline price in USD/LKR | Yes | `18500.00` |
| `damageDeduction`| `number` | Depreciation deduction for detected damages | Yes | `650.00` |
| `estimatedMarketValue` | `number`| Final recommended market valuation | Yes | `17850.00` |
| `currency` | `string` | ISO currency code | Yes | `"USD"` |
| `confidenceInterval` | `map` | Low/high confidence range | Yes | `{"low": 17200.00, "high": 18400.00}` |
| `status` | `string` | Valuation state (`computed`, `verified`, `expired`) | Yes | `"computed"` |
| `createdAt` | `timestamp` | Computation date | Yes | `2026-09-26T12:25:00Z` |

---

### 1.8 `reports` Collection
* **Path**: `/reports/{reportId}`
* **Document ID**: Auto-generated UUID
* **Purpose**: Final generated inspection report metadata, digital signature, and secure download reference.

| Field | Type | Description | Required | Example |
|---|---|---|---|---|
| `reportId` | `string` | Unique report record ID | Yes | `"rep_7718"` |
| `inspectionId` | `string` | Reference to `/inspections/{inspectionId}` | Yes | `"insp_88231"` |
| `vehicleId` | `string` | Reference to `/vehicles/{vehicleId}` | Yes | `"veh_91823746"` |
| `userId` | `string` | Reference to owner `/users/{uid}` | Yes | `"a8F9z0K1pL..."` |
| `pdfStoragePath`| `string` | Storage path to compiled PDF report | Yes | `"reports/insp_88231/report_insp_88231.pdf"` |
| `pdfDownloadUrl` | `string?`| Cached signed URL | No | `"https://firebasestorage.googleapis.com/..."` |
| `verificationIdentifier`| `string`| Cryptographic hash or public QR verification code | Yes | `"v-9a7c81d3f0"` |
| `status` | `string` | Report status (`generating`, `ready`, `revoked`) | Yes | `"ready"` |
| `generatedAt` | `timestamp` | Compilation timestamp | Yes | `2026-09-26T12:35:00Z` |

---

### 1.9 `marketplace_listings` Collection
* **Path**: `/marketplace_listings/{listingId}`
* **Document ID**: Auto-generated UUID
* **Purpose**: Public vehicle listings for sale with verified AutoDoc AI health report badges.

| Field | Type | Description | Required | Example |
|---|---|---|---|---|
| `listingId` | `string` | Unique listing ID | Yes | `"list_00192"` |
| `sellerId` | `string` | Reference to `/users/{uid}` | Yes | `"a8F9z0K1pL..."` |
| `vehicleId` | `string` | Reference to `/vehicles/{vehicleId}` | Yes | `"veh_91823746"` |
| `inspectionId` | `string?` | Optional reference to certified inspection | No | `"insp_88231"` |
| `reportId` | `string?` | Optional reference to verified report | No | `"rep_7718"` |
| `title` | `string` | Listing headline | Yes | `"2019 Toyota Corolla - Inspected Clean"` |
| `description` | `string` | Detailed seller description | Yes | `"One owner, meticulously maintained..."` |
| `price` | `number` | Asking price | Yes | `18200.00` |
| `currency` | `string` | ISO currency code | Yes | `"USD"` |
| `images` | `array<string>` | Storage URLs for public display images | Yes | `["gs://.../photo1.jpg"]` |
| `verificationStatus`| `string`| Inspection badge (`verified`, `unverified`, `pending`) | Yes | `"verified"` |
| `status` | `string` | Listing state (`active`, `sold`, `paused`, `removed`) | Yes | `"active"` |
| `viewsCount` | `number` | Analytics view counter | Yes | `142` |
| `createdAt` | `timestamp` | Publication timestamp | Yes | `2026-09-26T14:00:00Z` |
| `updatedAt` | `timestamp` | Last modification timestamp | Yes | `2026-09-26T14:00:00Z` |

---

## 2. Relationships Diagram

```text
[users] 1 ────< [vehicles] (ownerId)
   │                 │
   │ (userId)        │ (vehicleId)
   ▼                 ▼
[inspections] 1 ────┬────< [damage_results] (inspectionId)
                    ├────< [engine_diagnostics] (inspectionId)
                    ├────< [ocr_results] (vehicleId)
                    ├────1 [valuations] (inspectionId)
                    └────1 [reports] (inspectionId)
                             │
                             ▼
                    [marketplace_listings] (sellerId, vehicleId, inspectionId, reportId)
```

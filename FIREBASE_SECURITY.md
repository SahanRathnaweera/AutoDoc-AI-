# 🛡️ Firebase Security Rules Documentation

This document explains the security architecture, role authorization, and data protection enforcement implemented for AutoDoc AI across Cloud Firestore and Cloud Storage.

---

## 1. Security Architecture Principles

1. **Default Deny**: Any request that does not match an explicit rule is rejected by Firebase Security rules.
2. **Identity Verification**: Requests rely on cryptographically verified `request.auth` tokens generated upon Firebase Authentication login.
3. **Role Separation**:
   * **`client`**: Can read and manage only their own vehicles, trigger inspection requests, and manage their own marketplace listings.
   * **`inspector`**: Certified technicians allowed to upload inspection images, annotate damage, and submit diagnostic readings.
   * **`admin`**: System administrator and authorized backend services with elevated privileges.
4. **Tamper Prevention**:
   * Algorithmic AI valuations (`/valuations`) and finalized PDF inspection reports (`/reports`) cannot be written, mutated, or deleted by client devices. Only administrative service accounts (FastAPI backend with Firebase Admin SDK) are granted write authority.

---

## 2. Firestore Security Rules Summary

| Collection | Read Rule | Write / Create Rule | Delete Rule |
|---|---|---|---|
| `users/{userId}` | Authenticated users | Owner (`auth.uid == userId`) | Admin only |
| `vehicles/{vehicleId}` | Vehicle owner or Inspector | Owner (`auth.uid == ownerId`) | Owner or Admin |
| `inspections/{inspectionId}` | Vehicle owner or assigned Inspector | Owner or Inspector | Admin only |
| `damage_results/{damageId}` | Authenticated inspection viewer | Certified Inspector or Admin | Admin only |
| `engine_diagnostics/{id}` | Authenticated inspection viewer | Certified Inspector or Admin | Admin only |
| `ocr_results/{ocrId}` | Vehicle owner or Inspector | Certified Inspector or Admin | Admin only |
| `valuations/{valuationId}` | Authenticated user | Admin / Backend only | Admin only |
| `reports/{reportId}` | Public (verification token lookup) | Admin / Backend only | Admin only |
| `marketplace_listings/{id}` | Public (`status == 'active'`) | Seller (`auth.uid == sellerId`) | Seller or Admin |

---

## 3. Storage Security Rules Summary

| Path | Read Access | Write Access | Description |
|---|---|---|---|
| `users/{uid}/profile/*` | Public / Authenticated | Owner (`auth.uid == uid`) | User avatar images |
| `vehicles/{vehicleId}/images/*` | Public | Authenticated owner | Vehicle listing photographs |
| `vehicles/{vehicleId}/documents/*`| Authenticated participants | Authenticated owner / Inspector | Registration and legal documents |
| `inspections/{inspectionId}/images/*`| Authenticated participants | Certified Inspector / Owner | 360° visual inspection images |
| `inspections/{inspectionId}/audio/*` | Authenticated participants | Certified Inspector / Owner | Engine acoustic diagnostic audio |
| `reports/{inspectionId}/*` | Public | Admin / Backend service | Tamper-proof inspection report PDFs |

---

## 4. How to Deploy Security Rules

To deploy these rules to your Firebase environment:

```bash
# Deploy Firestore rules and indexes
firebase deploy --only firestore:rules,firestore:indexes

# Deploy Storage rules
firebase deploy --only storage
```

# 🔐 FastAPI + Firebase Authentication Integration Guide

This guide describes how the AutoDoc AI Python / FastAPI backend authenticates incoming requests from the Flutter mobile application using Firebase Authentication ID tokens.

---

## 1. Authentication Flow Diagram

```text
┌─────────────────┐             ┌─────────────────┐             ┌─────────────────────────┐
│ Flutter Client  │             │ FastAPI Backend │             │  Firebase Auth Servers  │
└────────┬────────┘             └────────┬────────┘             └────────────┬────────────┘
         │                               │                                   │
         │ 1. Login / Obtain ID Token    │                                   │
         │──────────────────────────────────────────────────────────────────>│
         │ 2. Return JWT ID Token        │                                   │
         │<──────────────────────────────────────────────────────────────────│
         │                               │                                   │
         │ 3. HTTP Request with Header   │                                   │
         │    Authorization: Bearer <JWT>│                                   │
         │──────────────────────────────>│                                   │
         │                               │ 4. Verify Token & Signature       │
         │                               │    (firebase_admin.auth.verify)   │
         │                               │──────────────────────────────────>│
         │                               │<──────────────────────────────────│
         │                               │                                   │
         │                               │ 5. Extract trusted `uid`, `email` │
         │                               │ 6. Execute ML / Business logic    │
         │ 7. Return 200 Protected Data  │                                   │
         │<──────────────────────────────│                                   │
```

---

## 2. Core Security Principle: Never Trust Client UIDs

> **CRITICAL SECURITY RULE:**
> The mobile client must **never** send its user ID in request bodies or query parameters as proof of identity (e.g. `{"user_id": "123"}`).
> The FastAPI backend **must extract the user's UID directly from the verified Firebase ID token** decoded by the Firebase Admin SDK.

---

## 3. Flutter Client Usage

The Flutter application provides `FirebaseTokenProvider` (injected via `getIt`):

```dart
// Example: Attaching the Firebase ID token in Dio or http client
final tokenProvider = getIt<FirebaseTokenProvider>();
final headers = await tokenProvider.getAuthorizationHeader();

final response = await http.post(
  Uri.parse('https://api.autodoc.ai/api/v1/diagnostics/engine'),
  headers: headers,
  body: jsonEncode({
    'inspectionId': inspectionId,
    'audioStoragePath': audioPath,
  }),
);
```

---

## 4. FastAPI Backend Implementation

### 4.1 Install Dependencies
```bash
pip install fastapi uvicorn firebase-admin pyjwt cryptography
```

### 4.2 Initialize Firebase Admin SDK
In your FastAPI entry point (`app/core/firebase.py`):

```python
import os
import firebase_admin
from firebase_admin import credentials, auth
from fastapi import HTTPException, Security, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials

# Initialize the Firebase Admin SDK using service account credentials
# Keep service-account.json out of git!
if not firebase_admin._apps:
    cred = credentials.Certificate(os.getenv("FIREBASE_CREDENTIALS_PATH", "serviceAccountKey.json"))
    firebase_admin.initialize_app(cred)

security = HTTPBearer()

async def get_current_user(
    credentials: HTTPAuthorizationCredentials = Security(security)
) -> dict:
    """
    FastAPI dependency that extracts, verifies, and decodes the Firebase JWT ID token.
    Returns decoded token dictionary containing 'uid', 'email', 'role', etc.
    """
    token = credentials.credentials
    try:
        # verify_id_token validates expiration, project audience, and cryptographic signature
        decoded_token = auth.verify_id_token(token)
        return decoded_token
    except auth.ExpiredIdTokenError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Firebase ID token has expired. Refresh token on client.",
            headers={"WWW-Authenticate": "Bearer error=\"invalid_token\""},
        )
    except auth.InvalidIdTokenError as e:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=f"Invalid Firebase ID token: {str(e)}",
            headers={"WWW-Authenticate": "Bearer error=\"invalid_token\""},
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=f"Authentication error: {str(e)}",
            headers={"WWW-Authenticate": "Bearer"},
        )
```

### 4.3 Protecting Endpoints
In your API routers (e.g. `app/api/v1/endpoints/damage.py`):

```python
from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel
from app.core.firebase import get_current_user

router = APIRouter(prefix="/damage", tags=["damage"])

class DamageDetectionRequest(BaseModel):
    inspection_id: str
    image_storage_path: str

@router.post("/detect")
async def detect_damage(
    request: DamageDetectionRequest,
    current_user: dict = Depends(get_current_user)
):
    user_uid = current_user["uid"]
    user_email = current_user.get("email")
    user_role = current_user.get("role", "client")

    # Perform damage detection AI processing on image_storage_path
    # user_uid is guaranteed to be authentic and cryptographically verified
    return {
        "status": "success",
        "processed_by_uid": user_uid,
        "inspection_id": request.inspection_id,
        "damages": []
    }
```

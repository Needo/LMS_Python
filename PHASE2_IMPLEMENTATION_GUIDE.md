# Phase 2 - Enhanced Authentication with Refresh Tokens

## ✅ Implementation Complete

Enhanced your existing auth system with refresh tokens without breaking anything!

---

## What Was Added

### Backend:

1. **RefreshToken Model** - Database table for refresh tokens
2. **Token Refresh Logic** - Auto-refresh expired access tokens
3. **Logout Endpoint** - Properly revoke refresh tokens
4. **Logout All** - Revoke all sessions (all devices)

### Frontend:

1. **Auto Token Refresh** - Seamless token refresh on 401 errors
2. **Enhanced Logout** - Revokes refresh token on server
3. **Refresh Token Storage** - Securely stored in localStorage
4. **Token Refresh Interceptor** - Automatic retry with new token

---

## How It Works

### Token Lifecycle:

```
Login → Access Token (15 min) + Refresh Token (7 days)
  ↓
Access Token Expires → 401 Error
  ↓
Auto Refresh → New Access Token (15 min)
  ↓
Continue Working (transparent to user)
  ↓
After 7 Days → Refresh Token Expires → Must Login Again
```

### Security Benefits:

✅ **Short-lived access tokens** (15 minutes) = more secure
✅ **Long user sessions** (7 days) = better UX
✅ **Token revocation** (logout works properly)
✅ **Multi-device support** (logout all devices)

---

## Setup Instructions

### 1. Run Migration

```cmd
cd backend
python -m app.migrations.add_refresh_tokens
```

**Expected Output:**
```
Running migration: add_refresh_tokens
✓ refresh_tokens table created successfully
Migration completed!
```

### 2. Restart Backend

```cmd
uvicorn app.main:app --reload
```

### 3. Test Login

The system automatically uses refresh tokens now - no code changes needed in existing components!

---

## API Endpoints

### POST /api/auth/login
**Request:**
```json
{
  "username": "admin",
  "password": "password"
}
```

**Response:**
```json
{
  "access_token": "eyJ0eXAiOiJKV1QiLCJ...",
  "refresh_token": "dGhpcyBpcyBhIHJlZnJl...",
  "token_type": "bearer",
  "user": {
    "id": 1,
    "username": "admin",
    "email": "admin@example.com",
    "is_admin": true
  }
}
```

### POST /api/auth/refresh
**Request:**
```json
{
  "refresh_token": "dGhpcyBpcyBhIHJlZnJl..."
}
```

**Response:**
```json
{
  "access_token": "eyJ0eXAiOiJKV1QiLCJ...",
  "token_type": "bearer"
}
```

### POST /api/auth/logout
**Request:**
```json
{
  "refresh_token": "dGhpcyBpcyBhIHJlZnJl..."
}
```

**Response:**
```json
{
  "message": "Logged out successfully"
}
```

### POST /api/auth/logout-all
Logs out from all devices.

**Response:**
```json
{
  "message": "Logged out from 3 session(s)"
}
```

---

## Frontend Auto-Refresh Flow

```typescript
// User makes API call
http.get('/api/courses') 

// Token expired (401 error)
  ↓
// Interceptor catches 401
  ↓
// Auto calls /api/auth/refresh
  ↓
// Gets new access token
  ↓
// Retries original request
  ↓
// Returns data (user doesn't notice anything!)
```

### Code Flow:

1. **Request fails with 401**
2. **tokenRefreshInterceptor** catches it
3. Calls `authService.refreshToken()`
4. Gets new access token
5. Retries original request with new token
6. Returns data to caller

**Result:** Seamless experience - user never sees token expiration!

---

## Testing the Implementation

### Test 1: Login and Get Tokens

```bash
curl -X POST http://localhost:8000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"password"}'
```

**Check:** Response includes both `access_token` and `refresh_token`

### Test 2: Use Access Token

```bash
curl http://localhost:8000/api/categories \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

**Check:** Works normally

### Test 3: Refresh Token

```bash
curl -X POST http://localhost:8000/api/auth/refresh \
  -H "Content-Type: application/json" \
  -d '{"refresh_token":"YOUR_REFRESH_TOKEN"}'
```

**Check:** Returns new access token

### Test 4: Logout

```bash
curl -X POST http://localhost:8000/api/auth/logout \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"refresh_token":"YOUR_REFRESH_TOKEN"}'
```

**Check:** Refresh token is revoked (can't use it again)

### Test 5: Frontend Auto-Refresh

1. Login to the app
2. Open browser DevTools → Application → Local Storage
3. Note the `access_token`
4. Wait 15+ minutes
5. Try to navigate or load data
6. Check Network tab - should see automatic `/api/auth/refresh` call
7. New token in localStorage
8. Original request succeeds

---

## Database Schema

### refresh_tokens Table

```sql
CREATE TABLE refresh_tokens (
    id SERIAL PRIMARY KEY,
    token VARCHAR(500) UNIQUE NOT NULL,
    user_id INTEGER REFERENCES users(id),
    expires_at TIMESTAMP NOT NULL,
    created_at TIMESTAMP DEFAULT NOW(),
    revoked BOOLEAN DEFAULT FALSE
);
```

### Indexes

```sql
CREATE INDEX idx_refresh_tokens_token ON refresh_tokens(token);
CREATE INDEX idx_refresh_tokens_user_id ON refresh_tokens(user_id);
```

---

## Configuration

### Token Lifetimes (in code):

```python
# backend/app/core/security.py
ACCESS_TOKEN_LIFETIME = 15 minutes  # Short-lived
REFRESH_TOKEN_LIFETIME = 7 days     # Long-lived
```

To change:

```python
# Access token (security.py)
expire = datetime.utcnow() + timedelta(minutes=15)  # Change 15 to your preference

# Refresh token (auth_service.py)
expires_at = datetime.utcnow() + timedelta(days=7)  # Change 7 to your preference
```

**Recommendations:**
- Access: 15-30 minutes
- Refresh: 7-30 days
- Production: Shorter is more secure

---

## Security Considerations

### ✅ What's Secure:

1. **Short-lived access tokens** - Limited damage if stolen
2. **Refresh token revocation** - Logout actually works
3. **Token type checking** - Access tokens can't be used as refresh tokens
4. **Database-backed** - Can revoke any token anytime
5. **HTTPS required** in production

### ⚠️ Important Notes:

1. **localStorage** is used (acceptable for small apps)
2. For high-security apps, consider httpOnly cookies
3. Always use HTTPS in production
4. Tokens are NOT encrypted (JWT is signed, not encrypted)
5. Don't store sensitive data in JWT payload

---

## Comparison: Before vs After

### Before (Phase 1):
- Access token: 60 minutes
- No refresh mechanism
- Logout clears localStorage only
- User kicked out after 60 min

### After (Phase 2):
- Access token: 15 minutes ✅ More secure
- Refresh token: 7 days ✅ Better UX
- Logout revokes server token ✅ Proper logout
- Auto-refresh ✅ Seamless experience
- Can logout all devices ✅ Better security

---

## Troubleshooting

### Issue: "Invalid refresh token"

**Cause:** Refresh token was revoked or expired

**Solution:**
1. Check `refresh_tokens` table
2. Verify token exists and `revoked=false`
3. Check `expires_at` timestamp
4. User needs to login again

### Issue: "Auto-refresh not working"

**Checks:**
1. Is `tokenRefreshInterceptor` registered in `app.config.ts`?
2. Is refresh token in localStorage?
3. Check browser console for errors
4. Verify `/api/auth/refresh` endpoint works

### Issue: Token still valid after logout

**Cause:** Access tokens can't be revoked (JWT nature)

**Solution:** This is normal! Access tokens expire in 15 minutes anyway. The refresh token is revoked, preventing new access tokens.

### Issue: Database table not found

**Cause:** Migration not run

**Solution:**
```cmd
cd backend
python -m app.migrations.add_refresh_tokens
```

---

## Migration from Phase 1

Your existing auth system continues to work! Changes are backward compatible:

1. **Old tokens still work** until they expire
2. **New logins** get refresh tokens automatically  
3. **Frontend** handles both cases gracefully
4. **No user data lost**

### Optional: Force Re-login

If you want all users to get new refresh tokens:

```sql
-- Clear all sessions (optional)
DELETE FROM refresh_tokens;

-- Or just expired ones
DELETE FROM refresh_tokens WHERE expires_at < NOW();
```

Users will need to login again on next visit.

---

## What Didn't Change

✅ Login UI - same as before
✅ Route guards - same as before  
✅ User model - same as before
✅ Admin checks - same as before
✅ Existing endpoints - all still work

**Result:** Zero breaking changes! Everything works better now.

---

## Next Steps

Phase 2 complete! Your auth system is now production-ready with:
- ✅ JWT authentication
- ✅ Refresh tokens
- ✅ Proper logout
- ✅ Auto-refresh
- ✅ Multi-device support
- ✅ Role-based access (admin/user)

Ready for Phase 3 when you are!

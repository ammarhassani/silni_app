# 🔐 Codemagic Environment Variables Setup

## 📋 All Variables to Add in Codemagic UI

Go to: **Codemagic Dashboard → Your App → Environment variables**

Copy these variable names and paste the values from your local `.env` file:

### Supabase (Staging)
| Variable Name | Value | Secure? |
|--------------|-------|---------|
| `SUPABASE_STAGING_URL` | `https://dqqyhmydodjpqboykzow.supabase.co` | ✅ Yes |
| `SUPABASE_STAGING_ANON_KEY` | `eyJhbGc...` (your anon key) | ✅ Yes |

### Supabase (Production)
| Variable Name | Value | Secure? |
|--------------|-------|---------|
| `SUPABASE_PRODUCTION_URL` | `https://bapwklwxmwhpucutyras.supabase.co` | ✅ Yes |
| `SUPABASE_PRODUCTION_ANON_KEY` | `eyJhbGc...` (your anon key) | ✅ Yes |

### Firebase (Legacy - FCM only)
| Variable Name | Value | Secure? |
|--------------|-------|---------|
| `FIREBASE_API_KEY` | `AIzaSyBuS1snryQ_DWxhcEUtj0Lu_HDrdIvASDY` | ✅ Yes |
| `FIREBASE_AUTH_DOMAIN` | `silni-31811.firebaseapp.com` | ❌ No |
| `FIREBASE_PROJECT_ID` | `silni-31811` | ❌ No |
| `FIREBASE_STORAGE_BUCKET` | `silni-31811.firebasestorage.app` | ❌ No |
| `FIREBASE_MESSAGING_SENDER_ID` | `104991741546` | ❌ No |
| `FIREBASE_APP_ID` | `1:104991741546:web:baa2792c28877379412f13` | ✅ Yes |
| `FIREBASE_MEASUREMENT_ID` | `G-JMW4oM9PXM` | ❌ No |

### Cloudinary
| Variable Name | Value | Secure? |
|--------------|-------|---------|
| `CLOUDINARY_CLOUD_NAME` | `dli79vqgg` | ❌ No |
| `CLOUDINARY_API_KEY` | (your actual API key) | ✅ Yes |
| `CLOUDINARY_API_SECRET` | (your actual API secret) | ✅ Yes |
| `CLOUDINARY_UPLOAD_PRESET` | `silni_unsigned` | ❌ No |

---

## ⚠️ IMPORTANT NOTES:

### ✅ Mark as "Secure" (check the box):
- All API keys
- All secrets
- All anon keys
- Anything sensitive

### ❌ Don't mark as "Secure":
- Domain names
- Project IDs
- Bucket names
- Upload presets
- Non-sensitive config

---

## 🚀 Quick Copy-Paste List

For easy copy-pasting into Codemagic:

```
SUPABASE_STAGING_URL
SUPABASE_STAGING_ANON_KEY
SUPABASE_PRODUCTION_URL
SUPABASE_PRODUCTION_ANON_KEY
FIREBASE_API_KEY
FIREBASE_AUTH_DOMAIN
FIREBASE_PROJECT_ID
FIREBASE_STORAGE_BUCKET
FIREBASE_MESSAGING_SENDER_ID
FIREBASE_APP_ID
FIREBASE_MEASUREMENT_ID
CLOUDINARY_CLOUD_NAME
CLOUDINARY_API_KEY
CLOUDINARY_API_SECRET
CLOUDINARY_UPLOAD_PRESET
```

---

## 🔍 How to Get Values from Your Local `.env`

```bash
cat .env
```

Then copy each value and paste into Codemagic.

---

## ✅ Verification

After adding all variables, go back to this guide and check them off:

- [ ] SUPABASE_STAGING_URL
- [ ] SUPABASE_STAGING_ANON_KEY
- [ ] SUPABASE_PRODUCTION_URL
- [ ] SUPABASE_PRODUCTION_ANON_KEY
- [ ] FIREBASE_API_KEY
- [ ] FIREBASE_AUTH_DOMAIN
- [ ] FIREBASE_PROJECT_ID
- [ ] FIREBASE_STORAGE_BUCKET
- [ ] FIREBASE_MESSAGING_SENDER_ID
- [ ] FIREBASE_APP_ID
- [ ] FIREBASE_MEASUREMENT_ID
- [ ] CLOUDINARY_CLOUD_NAME
- [ ] CLOUDINARY_API_KEY (⚠️ MUST be your actual key, not placeholder!)
- [ ] CLOUDINARY_API_SECRET (⚠️ MUST be your actual secret, not placeholder!)
- [ ] CLOUDINARY_UPLOAD_PRESET

**Total: 15 variables**

---

## 📸 What It Should Look Like

In Codemagic, you'll see something like:

```
Key                              Value                    Secure
-------------------------------------------------------------------
SUPABASE_STAGING_URL             https://dqqyh...         ✅
SUPABASE_STAGING_ANON_KEY        eyJhbGciOiJ...          ✅
FIREBASE_PROJECT_ID              silni-31811              ❌
...
```

---

## ⚠️ Security Warning

- **NEVER commit `.env` file to Git!**
- `.env` should be in your `.gitignore`
- Only add these variables in Codemagic's secure environment variables section
- Mark all sensitive values as "Secure" (they'll be encrypted and hidden)

---

## 🎯 Next Steps

After adding all variables:

1. ✅ Verify all 15 variables are added
2. ✅ Double-check "Secure" checkboxes
3. ✅ Save changes
4. ✅ Go back to `CODEMAGIC_SETUP.md` and continue with Step 6: "Start Your First Build"

---

**Good luck! 🚀**

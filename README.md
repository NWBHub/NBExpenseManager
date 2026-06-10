# Smart Expense Manager Starter

Stack:
- Flutter mobile app
- Node.js + Express backend
- MongoDB Atlas
- Firebase Authentication / Firebase Admin verification

Important security rule:
Every database document has `userId`.
Every API fetches data using authenticated `req.user.uid`.
Never store MongoDB URL inside Flutter app.

## Deployment

Recommended production setup:
- Render for `backend-api`
- MongoDB Atlas for database
- Firebase Auth + Firebase Admin for authentication

### What is already prepared
- Render blueprint: [render.yaml](C:/Users/pc/Desktop/ps-project/NBExpenseManager/render.yaml)
- Health endpoint: `GET /health`
- Runtime-configurable mobile API URL via `--dart-define=API_BASE_URL=...`

### Before pushing code
Make sure these are never committed:
- `backend-api/.env`
- Firebase service account JSON
- MongoDB passwords or private keys

### Render deploy values
- Service type: `Web Service`
- Root directory: `backend-api`
- Build command: `npm install`
- Start command: `npm start`
- Health check path: `/health`

### Render environment variables
- `MONGO_URI`
- `FIREBASE_PROJECT_ID`
- `FIREBASE_CLIENT_EMAIL`
- `FIREBASE_PRIVATE_KEY`

### Flutter run against deployed backend
```powershell
cd C:\Users\pc\Desktop\ps-project\NBExpenseManager\mobile-app
C:\flutter\bin\flutter.bat run --dart-define=API_BASE_URL=https://YOUR-RENDER-URL.onrender.com/api
```

### Flutter release APK
```powershell
cd C:\Users\pc\Desktop\ps-project\NBExpenseManager\mobile-app
C:\flutter\bin\flutter.bat build apk --release --dart-define=API_BASE_URL=https://YOUR-RENDER-URL.onrender.com/api
```

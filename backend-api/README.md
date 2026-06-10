# Smart Expense Manager API

Production-oriented Express API for the Smart Expense Manager Flutter application.

## Highlights

- Firebase Authentication token exchange with app JWT issuance
- MongoDB Atlas via Mongoose
- Per-user data isolation on every collection using `userId`
- Dashboard summary, monthly report JSON, and PDF export
- Savings insight generation for common discretionary categories

## Setup

1. Copy `.env.example` to `.env`
2. Fill MongoDB Atlas and Firebase Admin credentials
3. Run `npm install`
4. Run `npm run dev`

## Security Model

- Mobile app authenticates with Firebase
- Backend verifies Firebase ID token and issues a signed app JWT
- Protected APIs require the app JWT
- CRUD queries always filter by `req.user.userId`

## Important Note

Phone OTP, Google Sign-In, and Email/Password flows are handled by Firebase on the client. The backend only accepts verified Firebase identity and never exposes database credentials to the mobile app.

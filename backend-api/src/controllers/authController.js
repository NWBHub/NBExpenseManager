const admin = require("../config/firebaseAdmin");
const User = require("../models/User");
const Expense = require("../models/Expense");
const Loan = require("../models/Loan");
const CreditCard = require("../models/CreditCard");
const Debt = require("../models/Debt");
const Reminder = require("../models/Reminder");
const Report = require("../models/Report");
const Notification = require("../models/Notification");

function buildUserPayload(req) {
  const firstName = (req.body.firstName || "").trim();
  const lastName = (req.body.lastName || "").trim();
  const fullName = [firstName, lastName].filter(Boolean).join(" ").trim();

  return {
    userId: req.user.uid,
    firstName: firstName || undefined,
    lastName: lastName || undefined,
    name: fullName || req.body.name || req.user.name || undefined,
    email: req.body.email || req.user.email,
    phone: req.body.phone || req.body.mobile || req.user.phone,
    photoUrl: req.body.photoUrl || "",
    currency: req.body.currency || undefined
  };
}

async function syncUser(req, res, next) {
  try {
    const user = await User.findOneAndUpdate(
      { userId: req.user.uid },
      buildUserPayload(req),
      { upsert: true, new: true, setDefaultsOnInsert: true }
    );

    res.json({ success: true, data: user });
  } catch (err) {
    next(err);
  }
}

async function getProfile(req, res, next) {
  try {
    const user = await User.findOne({ userId: req.user.uid });
    res.json({ success: true, data: user });
  } catch (err) {
    next(err);
  }
}

async function updateProfile(req, res, next) {
  try {
    const user = await User.findOneAndUpdate(
      { userId: req.user.uid },
      buildUserPayload(req),
      { new: true }
    );

    if (!user) {
      return res.status(404).json({ success: false, message: "User not found" });
    }

    res.json({ success: true, data: user, message: "Profile updated" });
  } catch (err) {
    next(err);
  }
}

async function deleteAccount(req, res, next) {
  try {
    const query = { userId: req.user.uid };

    await Promise.all([
      User.deleteOne(query),
      Expense.deleteMany(query),
      Loan.deleteMany(query),
      CreditCard.deleteMany(query),
      Debt.deleteMany(query),
      Reminder.deleteMany(query),
      Report.deleteMany(query),
      Notification.deleteMany(query),
      admin.auth().deleteUser(req.user.uid)
    ]);

    res.json({ success: true, message: "Account deleted permanently" });
  } catch (err) {
    next(err);
  }
}

module.exports = { syncUser, getProfile, updateProfile, deleteAccount };

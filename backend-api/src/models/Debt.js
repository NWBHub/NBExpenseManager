const mongoose = require("mongoose");

const schema = new mongoose.Schema({
  userId: { type: String, required: true },
  personName: { type: String, required: true },
  mobileNumber: String,
  amountGiven: { type: Number, required: true },
  amountReturned: { type: Number, default: 0 },
  balanceAmount: { type: Number, default: 0 },
  givenDate: Date,
  expectedReturnDate: Date,
  reminderDate: Date,
  notes: String
}, { timestamps: true });

schema.index({ userId: 1, createdAt: -1 });

module.exports = mongoose.model("Debt", schema);

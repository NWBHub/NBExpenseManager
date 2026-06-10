const mongoose = require("mongoose");

const schema = new mongoose.Schema({
  userId: { type: String, required: true },
  loanName: { type: String, required: true },
  bankName: String,
  totalLoanAmount: { type: Number, required: true },
  emiAmount: { type: Number, required: true },
  interestRate: Number,
  startDate: Date,
  dueDate: Date,
  paidAmount: { type: Number, default: 0 },
  remainingAmount: { type: Number, default: 0 },
  paymentStatus: { type: String, enum: ["Paid", "Partial", "Pending"], default: "Pending" },
  reminderDate: Date
}, { timestamps: true });

schema.index({ userId: 1, createdAt: -1 });

module.exports = mongoose.model("Loan", schema);

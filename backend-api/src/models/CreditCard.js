const mongoose = require("mongoose");

const schema = new mongoose.Schema({
  userId: { type: String, required: true },
  recordType: {
    type: String,
    enum: ["Credit Card", "BC"],
    default: "Credit Card"
  },
  cardName: { type: String, required: true },
  bankName: String,
  creditLimit: Number,
  billAmount: { type: Number, required: true },
  dueDate: Date,
  minimumDue: Number,
  paidAmount: { type: Number, default: 0 },
  balanceAmount: { type: Number, default: 0 },
  paymentStatus: { type: String, enum: ["Paid", "Partial", "Pending"], default: "Pending" },
  reminderDate: Date,
  totalInstallments: { type: Number, default: 0 },
  paidInstallments: { type: Number, default: 0 },
  installmentAmount: { type: Number, default: 0 },
  startDate: Date,
  completionDate: Date,
  notes: String
}, { timestamps: true });

schema.index({ userId: 1, createdAt: -1 });

module.exports = mongoose.model("CreditCard", schema);

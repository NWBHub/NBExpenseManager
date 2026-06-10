const mongoose = require("mongoose");

const schema = new mongoose.Schema({
  userId: { type: String, required: true },
  title: { type: String, required: true },
  shopkeeperName: String,
  shopkeeperPhone: String,
  category: { type: String, required: true },
  amount: { type: Number, required: true },
  paidAmount: { type: Number, default: 0 },
  balanceAmount: { type: Number, default: 0 },
  paymentStatus: { type: String, enum: ["Paid", "Partial", "Pending"], default: "Pending" },
  paymentMode: { type: String, default: "Cash" },
  expenseDate: { type: Date, required: true },
  dueDate: Date,
  reminderDate: Date,
  notes: String,
  billImage: String
}, { timestamps: true });

schema.index({ userId: 1, createdAt: -1 });

module.exports = mongoose.model("Expense", schema);

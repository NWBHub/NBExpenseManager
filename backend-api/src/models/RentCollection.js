const mongoose = require("mongoose");

const schema = new mongoose.Schema({
  userId: { type: String, required: true },
  propertyName: { type: String, required: true },
  propertyType: {
    type: String,
    enum: ["Shop", "Apartment", "Office", "House", "Other"],
    default: "Shop"
  },
  tenantName: { type: String, required: true },
  tenantPhone: String,
  monthlyRent: { type: Number, required: true },
  paidAmount: { type: Number, default: 0 },
  balanceAmount: { type: Number, default: 0 },
  paymentStatus: { type: String, enum: ["Paid", "Partial", "Pending"], default: "Pending" },
  rentMonth: Date,
  dueDate: Date,
  reminderDate: Date,
  notes: String
}, { timestamps: true });

schema.index({ userId: 1, createdAt: -1 });

module.exports = mongoose.model("RentCollection", schema);

const mongoose = require("mongoose");

const schema = new mongoose.Schema({
  userId: { type: String, required: true },
  title: { type: String, required: true },
  type: String,
  amount: Number,
  dueDate: Date,
  reminderDate: Date,
  isCompleted: { type: Boolean, default: false },
  notes: String
}, { timestamps: true });

schema.index({ userId: 1, createdAt: -1 });

module.exports = mongoose.model("Reminder", schema);

const mongoose = require('mongoose');

const reportSchema = new mongoose.Schema(
  {
    userId: { type: String, required: true, index: true },
    type: { type: String, required: true, trim: true },
    periodStart: { type: Date, required: true },
    periodEnd: { type: Date, required: true },
    totals: {
      totalExpense: { type: Number, default: 0 },
      totalPaid: { type: Number, default: 0 },
      totalPending: { type: Number, default: 0 },
    },
    insights: [{ type: String }],
    fileUrl: { type: String, trim: true },
  },
  { timestamps: true }
);

module.exports = mongoose.model('Report', reportSchema);

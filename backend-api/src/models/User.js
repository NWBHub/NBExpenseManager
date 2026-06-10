const mongoose = require("mongoose");

const userSchema = new mongoose.Schema({
  userId: { type: String, required: true, unique: true },
  firstName: String,
  lastName: String,
  name: String,
  email: String,
  phone: String,
  photoUrl: String,
  currency: { type: String, default: "INR" }
}, { timestamps: true });

module.exports = mongoose.model("User", userSchema);

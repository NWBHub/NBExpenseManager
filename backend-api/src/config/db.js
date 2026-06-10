const mongoose = require("mongoose");
const env = require("./env");

let cachedConnectionPromise = null;

async function connectDB() {
  if (!env.MONGO_URI) {
    throw new Error("MONGO_URI missing in .env");
  }

  if (mongoose.connection.readyState === 1) {
    return mongoose.connection;
  }

  if (cachedConnectionPromise) {
    return cachedConnectionPromise;
  }

  cachedConnectionPromise = mongoose
    .connect(env.MONGO_URI)
    .then((connection) => {
      console.log("MongoDB connected");
      return connection;
    })
    .catch((error) => {
      cachedConnectionPromise = null;
      throw error;
    });

  return cachedConnectionPromise;
}

module.exports = connectDB;

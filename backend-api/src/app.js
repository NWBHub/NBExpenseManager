const express = require("express");
const cors = require("cors");
const helmet = require("helmet");
const morgan = require("morgan");

const authRoutes = require("./routes/authRoutes");
const expenseRoutes = require("./routes/expenseRoutes");
const loanRoutes = require("./routes/loanRoutes");
const creditCardRoutes = require("./routes/creditCardRoutes");
const debtRoutes = require("./routes/debtRoutes");
const rentRoutes = require("./routes/rentRoutes");
const reportRoutes = require("./routes/reportRoutes");
const reminderRoutes = require("./routes/reminderRoutes");

const app = express();

app.use(helmet());
app.use(cors());
app.use(express.json({ limit: "10mb" }));
app.use(morgan("dev"));

app.get("/", (req, res) => res.json({ message: "Smart Expense Manager API" }));
app.get("/health", (req, res) => {
  res.status(200).json({
    success: true,
    message: "NBExpenseManager API healthy"
  });
});

app.use("/api/auth", authRoutes);
app.use("/api/expenses", expenseRoutes);
app.use("/api/loans", loanRoutes);
app.use("/api/credit-cards", creditCardRoutes);
app.use("/api/debts", debtRoutes);
app.use("/api/rents", rentRoutes);
app.use("/api/reports", reportRoutes);
app.use("/api/reminders", reminderRoutes);

app.use((err, req, res, next) => {
  console.error(err);
  res.status(err.statusCode || 500).json({
    success: false,
    message: err.message || "Server Error"
  });
});

module.exports = app;

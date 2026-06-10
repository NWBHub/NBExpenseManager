const Expense = require("../models/Expense");
const Loan = require("../models/Loan");
const CreditCard = require("../models/CreditCard");
const Debt = require("../models/Debt");

function monthRange(year, month) {
  const start = new Date(year, month - 1, 1);
  const end = new Date(year, month, 1);
  return { start, end };
}

async function monthlyReport(req, res, next) {
  try {
    const year = Number(req.query.year);
    const month = Number(req.query.month);

    if (!year || !month) {
      return res.status(400).json({ success: false, message: "year and month required" });
    }

    const { start, end } = monthRange(year, month);

    const expenses = await Expense.find({
      userId: req.user.uid,
      expenseDate: { $gte: start, $lt: end }
    });

    const totalExpense = expenses.reduce((s, e) => s + Number(e.amount || 0), 0);
    const totalPaid = expenses.reduce((s, e) => s + Number(e.paidAmount || 0), 0);
    const totalPending = expenses.reduce((s, e) => s + Number(e.balanceAmount || 0), 0);

    const byCategory = {};
    for (const expense of expenses) {
      byCategory[expense.category] = (byCategory[expense.category] || 0) + Number(expense.amount || 0);
    }

    const loans = await Loan.find({ userId: req.user.uid });
    const creditCards = await CreditCard.find({ userId: req.user.uid });
    const debts = await Debt.find({ userId: req.user.uid });

    const smallCategories = ["Tea Expense", "Hotel Meal Bill", "Petrol", "Shopping", "Entertainment"];
    const smallTotal = expenses
      .filter((expense) => smallCategories.includes(expense.category))
      .reduce((sum, expense) => sum + Number(expense.amount || 0), 0);

    res.json({
      success: true,
      data: {
        year,
        month,
        totalExpense,
        totalPaid,
        totalPending,
        byCategory,
        loanBalance: loans.reduce((s, x) => s + Number(x.remainingAmount || 0), 0),
        creditCardBalance: creditCards.reduce((s, x) => s + Number(x.balanceAmount || 0), 0),
        debtBalance: debts.reduce((s, x) => s + Number(x.balanceAmount || 0), 0),
        savingSuggestion: `Small repeated expenses are INR ${smallTotal}. Reducing 30% can save around INR ${Math.round(smallTotal * 0.3)} this month.`
      }
    });
  } catch (err) {
    next(err);
  }
}

module.exports = { monthlyReport };

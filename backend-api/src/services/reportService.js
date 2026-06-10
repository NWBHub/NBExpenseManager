const dayjs = require('dayjs');
const Expense = require('../models/Expense');
const Loan = require('../models/Loan');
const CreditCard = require('../models/CreditCard');
const Debt = require('../models/Debt');

const getRange = (period = 'month') => {
  const now = dayjs();
  if (period === 'week') {
    return [now.startOf('week').toDate(), now.endOf('week').toDate()];
  }

  if (period === 'day') {
    return [now.startOf('day').toDate(), now.endOf('day').toDate()];
  }

  return [now.startOf('month').toDate(), now.endOf('month').toDate()];
};

const getDashboardSummary = async (userId) => {
  const [dayStart, dayEnd] = getRange('day');
  const [weekStart, weekEnd] = getRange('week');
  const [monthStart, monthEnd] = getRange('month');

  const [todayExpenses, weekExpenses, monthExpenses, pendingExpenses, loans, cards, debts] = await Promise.all([
    Expense.find({ userId, expenseDate: { $gte: dayStart, $lte: dayEnd } }).lean(),
    Expense.find({ userId, expenseDate: { $gte: weekStart, $lte: weekEnd } }).lean(),
    Expense.find({ userId, expenseDate: { $gte: monthStart, $lte: monthEnd } }).lean(),
    Expense.find({ userId, paymentStatus: { $ne: 'Paid' } }).lean(),
    Loan.find({ userId }).lean(),
    CreditCard.find({ userId }).lean(),
    Debt.find({ userId }).lean(),
  ]);

  const sumBy = (items, key) => items.reduce((sum, item) => sum + (item[key] || 0), 0);

  return {
    todayExpense: sumBy(todayExpenses, 'amount'),
    thisWeekExpense: sumBy(weekExpenses, 'amount'),
    thisMonthExpense: sumBy(monthExpenses, 'amount'),
    pendingPayments: sumBy(pendingExpenses, 'balanceAmount'),
    upcomingDuePayments: pendingExpenses.filter((item) => item.dueDate).length,
    totalDebtGiven: sumBy(debts, 'amountGiven'),
    totalDebtReceived: sumBy(debts, 'amountReturned'),
    loanBalance: sumBy(loans, 'remainingAmount'),
    creditCardBalance: sumBy(cards, 'balanceAmount'),
  };
};

const buildMonthlyReport = async (userId, date = new Date()) => {
  const start = dayjs(date).startOf('month').toDate();
  const end = dayjs(date).endOf('month').toDate();
  const expenses = await Expense.find({
    userId,
    expenseDate: { $gte: start, $lte: end },
  }).lean();

  const totalExpense = expenses.reduce((sum, item) => sum + item.amount, 0);
  const totalPaid = expenses.reduce((sum, item) => sum + item.paidAmount, 0);
  const totalPending = expenses.reduce((sum, item) => sum + item.balanceAmount, 0);

  const byCategory = Object.values(
    expenses.reduce((acc, expense) => {
      if (!acc[expense.category]) {
        acc[expense.category] = { category: expense.category, total: 0, count: 0 };
      }
      acc[expense.category].total += expense.amount;
      acc[expense.category].count += 1;
      return acc;
    }, {})
  );

  return {
    periodStart: start,
    periodEnd: end,
    totals: { totalExpense, totalPaid, totalPending },
    categoryBreakdown: byCategory,
    dailyBreakdown: expenses.map((item) => ({
      date: item.expenseDate,
      title: item.title,
      category: item.category,
      amount: item.amount,
      paymentStatus: item.paymentStatus,
    })),
  };
};

module.exports = {
  getDashboardSummary,
  buildMonthlyReport,
};

const dayjs = require('dayjs');
const Expense = require('../models/Expense');

const trackedCategories = ['Tea Expense', 'Hotel Meal Bill', 'Petrol', 'Shopping', 'Entertainment'];

const generateSavingsInsights = async (userId, referenceDate = new Date()) => {
  const monthStart = dayjs(referenceDate).startOf('month').toDate();
  const monthEnd = dayjs(referenceDate).endOf('month').toDate();

  const expenses = await Expense.find({
    userId,
    category: { $in: trackedCategories },
    expenseDate: { $gte: monthStart, $lte: monthEnd },
  }).lean();

  const total = expenses.reduce((sum, item) => sum + item.amount, 0);
  const grouped = trackedCategories.map((category) => {
    const items = expenses.filter((expense) => expense.category === category);
    return {
      category,
      total: items.reduce((sum, item) => sum + item.amount, 0),
      count: items.length,
    };
  });

  const recommendedSavings = Number((total * 0.3).toFixed(2));
  const insight =
    total > 0
      ? `You spent INR ${total.toFixed(0)} on tea, meals, fuel, shopping, and entertainment this month. Cutting 30% can save INR ${recommendedSavings.toFixed(0)}.`
      : 'No discretionary spending detected yet for this month.';

  return {
    trackedCategories: grouped,
    totalTrackedSpend: total,
    recommendedSavings,
    insight,
  };
};

module.exports = {
  generateSavingsInsights,
};

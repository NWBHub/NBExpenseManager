const asyncHandler = require('../utils/asyncHandler');
const { sendSuccess } = require('../utils/responseHandler');
const { generateSavingsInsights } = require('../services/savingSuggestionService');

const getSavingsInsights = asyncHandler(async (req, res) => {
  const insights = await generateSavingsInsights(req.user.userId);

  return sendSuccess(res, {
    data: insights,
  });
});

module.exports = {
  getSavingsInsights,
};

const asyncHandler = require('../utils/asyncHandler');
const { sendSuccess } = require('../utils/responseHandler');

const createCrudController = (Model, resourceName) => ({
  list: asyncHandler(async (req, res) => {
    const query = { userId: req.user.userId };

    if (req.query.category) {
      query.category = req.query.category;
    }

    if (req.query.paymentStatus) {
      query.paymentStatus = req.query.paymentStatus;
    }

    if (req.query.from || req.query.to) {
      query.expenseDate = {};
      if (req.query.from) {
        query.expenseDate.$gte = new Date(req.query.from);
      }
      if (req.query.to) {
        query.expenseDate.$lte = new Date(req.query.to);
      }
    }

    if (req.query.search) {
      query.$or = [
        { title: { $regex: req.query.search, $options: 'i' } },
        { notes: { $regex: req.query.search, $options: 'i' } },
        { personName: { $regex: req.query.search, $options: 'i' } },
      ];
    }

    const items = await Model.find(query).sort({ createdAt: -1 }).lean();

    return sendSuccess(res, {
      data: items,
    });
  }),

  getById: asyncHandler(async (req, res) => {
    const item = await Model.findOne({
      _id: req.params.id,
      userId: req.user.userId,
    }).lean();

    return sendSuccess(res, { data: item });
  }),

  create: asyncHandler(async (req, res) => {
    const item = await Model.create({
      ...req.body,
      userId: req.user.userId,
    });

    return sendSuccess(res, {
      statusCode: 201,
      message: `${resourceName} created`,
      data: item,
    });
  }),

  update: asyncHandler(async (req, res) => {
    const item = await Model.findOneAndUpdate(
      { _id: req.params.id, userId: req.user.userId },
      { $set: req.body },
      { new: true, runValidators: true }
    ).lean();

    return sendSuccess(res, {
      message: `${resourceName} updated`,
      data: item,
    });
  }),

  remove: asyncHandler(async (req, res) => {
    await Model.deleteOne({ _id: req.params.id, userId: req.user.userId });

    return sendSuccess(res, {
      message: `${resourceName} deleted`,
    });
  }),
});

module.exports = createCrudController;

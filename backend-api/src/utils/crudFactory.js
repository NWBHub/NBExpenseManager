function calcPayment(data) {
  const amount = Number(data.amount || data.billAmount || data.totalLoanAmount || data.amountGiven || 0);
  const paid = Number(data.paidAmount || data.amountReturned || 0);
  const balance = Math.max(amount - paid, 0);

  if ("balanceAmount" in data || data.amount || data.billAmount || data.amountGiven) {
    data.balanceAmount = balance;
  }

  if ("remainingAmount" in data || data.totalLoanAmount) {
    data.remainingAmount = balance;
  }

  if (paid <= 0) data.paymentStatus = data.paymentStatus || "Pending";
  else if (balance <= 0) data.paymentStatus = "Paid";
  else data.paymentStatus = "Partial";

  return data;
}

function createCrudController(Model) {
  return {
    async create(req, res, next) {
      try {
        const data = calcPayment({ ...req.body, userId: req.user.uid });
        const doc = await Model.create(data);
        res.status(201).json({ success: true, data: doc });
      } catch (err) {
        next(err);
      }
    },

    async list(req, res, next) {
      try {
        const query = { userId: req.user.uid };

        if (req.query.category) {
          query.category = req.query.category;
        }

        if (req.query.paymentStatus) {
          query.paymentStatus = req.query.paymentStatus;
        }

        if (req.query.search) {
          const regex = new RegExp(req.query.search, "i");
          query.$or = [
            { title: regex },
            { shopkeeperName: regex },
            { propertyName: regex },
            { tenantName: regex },
            { notes: regex },
            { personName: regex }
          ];
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

        const docs = await Model.find(query).sort({ createdAt: -1 });
        res.json({ success: true, data: docs });
      } catch (err) {
        next(err);
      }
    },

    async get(req, res, next) {
      try {
        const doc = await Model.findOne({ _id: req.params.id, userId: req.user.uid });
        if (!doc) return res.status(404).json({ success: false, message: "Not found" });
        res.json({ success: true, data: doc });
      } catch (err) {
        next(err);
      }
    },

    async update(req, res, next) {
      try {
        const data = calcPayment({ ...req.body });
        const doc = await Model.findOneAndUpdate(
          { _id: req.params.id, userId: req.user.uid },
          data,
          { new: true }
        );
        if (!doc) return res.status(404).json({ success: false, message: "Not found" });
        res.json({ success: true, data: doc });
      } catch (err) {
        next(err);
      }
    },

    async remove(req, res, next) {
      try {
        const doc = await Model.findOneAndDelete({ _id: req.params.id, userId: req.user.uid });
        if (!doc) return res.status(404).json({ success: false, message: "Not found" });
        res.json({ success: true, message: "Deleted" });
      } catch (err) {
        next(err);
      }
    }
  };
}

module.exports = createCrudController;

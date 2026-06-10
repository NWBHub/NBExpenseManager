const Model = require("../models/Expense");
const createCrudController = require("../utils/crudFactory");

module.exports = createCrudController(Model);

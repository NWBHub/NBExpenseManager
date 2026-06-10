const Model = require("../models/Loan");
const createCrudController = require("../utils/crudFactory");

module.exports = createCrudController(Model);

const Model = require("../models/Debt");
const createCrudController = require("../utils/crudFactory");

module.exports = createCrudController(Model);

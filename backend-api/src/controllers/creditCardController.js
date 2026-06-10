const Model = require("../models/CreditCard");
const createCrudController = require("../utils/crudFactory");

module.exports = createCrudController(Model);

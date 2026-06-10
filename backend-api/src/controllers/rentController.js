const Model = require("../models/RentCollection");
const createCrudController = require("../utils/crudFactory");

module.exports = createCrudController(Model);

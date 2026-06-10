const Model = require("../models/Reminder");
const createCrudController = require("../utils/crudFactory");

module.exports = createCrudController(Model);

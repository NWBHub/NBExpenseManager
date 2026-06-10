const express = require("express");
const auth = require("../middleware/authMiddleware");
const { monthlyReport } = require("../controllers/reportController");

const router = express.Router();

router.use(auth);
router.get("/monthly", monthlyReport);

module.exports = router;

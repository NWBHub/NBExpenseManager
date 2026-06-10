const express = require("express");
const auth = require("../middleware/authMiddleware");
const controller = require("../controllers/reminderController");

const router = express.Router();

router.use(auth);

router.post("/", controller.create);
router.get("/", controller.list);
router.get("/:id", controller.get);
router.put("/:id", controller.update);
router.delete("/:id", controller.remove);

module.exports = router;

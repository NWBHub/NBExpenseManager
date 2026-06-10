const express = require("express");
const auth = require("../middleware/authMiddleware");
const { syncUser, getProfile, updateProfile, deleteAccount } = require("../controllers/authController");

const router = express.Router();

router.post("/sync-user", auth, syncUser);
router.get("/me", auth, getProfile);
router.put("/me", auth, updateProfile);
router.delete("/me", auth, deleteAccount);

module.exports = router;

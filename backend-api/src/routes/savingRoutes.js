const express = require('express');
const { requireAuth } = require('../middleware/authMiddleware');
const { getSavingsInsights } = require('../controllers/savingController');

const router = express.Router();

router.use(requireAuth);
router.get('/insights', getSavingsInsights);

module.exports = router;

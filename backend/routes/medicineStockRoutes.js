const express = require('express');
const router = express.Router();
const {
  addMedicine,
  getAllMedicines,
  updateMedicine,
  deleteMedicine,
  getLowStockAlerts,
  getExpiryAlerts
} = require('../controllers/medicineStockController');
const { protect } = require('../middleware/auth');

// All routes require authentication
router.use(protect);

// Alert routes (must come before parameterized routes)
router.get('/alerts/low-stock', getLowStockAlerts);
router.get('/alerts/expiring', getExpiryAlerts);

// Main CRUD routes
router.post('/', addMedicine);
router.get('/', getAllMedicines);
router.put('/:id', updateMedicine);
router.delete('/:id', deleteMedicine);

module.exports = router;

const express = require('express');
const router = express.Router();
const medicineController = require('../controllers/medicineController');
const { protect } = require('../middleware/auth');

// All routes protected
router.use(protect);

router.post('/add', medicineController.addMedicine);
router.get('/calendar', medicineController.getCalendar);
router.get('/by-date', medicineController.getByDate);
router.get('/list', medicineController.getAllMedicines);
router.get('/:id', medicineController.getMedicine);
router.put('/update/:id', medicineController.updateMedicine);
router.delete('/delete/:id', medicineController.deleteMedicine);
router.post('/:id/mark-taken', medicineController.markAsTaken);
router.delete('/:id/unmark-taken', medicineController.unmarkAsTaken);

module.exports = router;

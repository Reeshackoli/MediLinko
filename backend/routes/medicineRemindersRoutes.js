const express = require('express');
const router = express.Router();
const { protect } = require('../middleware/auth');
const User = require('../models/User');

// @route   GET /api/medicines
// @desc    Get user's medicine reminders
// @access  Private
router.get('/', protect, async (req, res) => {
  try {
    const user = await User.findById(req.user._id).select('medicines');
    res.json({
      success: true,
      medicines: user.medicines || [],
    });
  } catch (error) {
    console.error('Error fetching medicines:', error);
    res.status(500).json({ error: error.message });
  }
});

// @route   POST /api/medicines
// @desc    Add medicine reminder
// @access  Private
router.post('/', protect, async (req, res) => {
  try {
    const { id, name, dosage, time } = req.body;
    
    if (!id || !name || !dosage || !time) {
      return res.status(400).json({ error: 'All fields required' });
    }
    
    const user = await User.findById(req.user._id);
    
    if (!user.medicines) {
      user.medicines = [];
    }
    
    user.medicines.push({ id, name, dosage, time });
    await user.save();
    
    console.log(`✅ Medicine added: ${name} for user ${user.email}`);
    
    res.json({
      success: true,
      message: 'Medicine reminder added',
      medicines: user.medicines,
    });
  } catch (error) {
    console.error('Error adding medicine:', error);
    res.status(500).json({ error: error.message });
  }
});

// @route   DELETE /api/medicines/:id
// @desc    Delete medicine reminder
// @access  Private
router.delete('/:id', protect, async (req, res) => {
  try {
    const medicineId = parseInt(req.params.id);
    
    const user = await User.findById(req.user._id);
    user.medicines = user.medicines.filter(m => m.id !== medicineId);
    await user.save();
    
    console.log(`✅ Medicine deleted: ID ${medicineId}`);
    
    res.json({
      success: true,
      message: 'Medicine reminder deleted',
      medicines: user.medicines,
    });
  } catch (error) {
    console.error('Error deleting medicine:', error);
    res.status(500).json({ error: error.message });
  }
});

module.exports = router;

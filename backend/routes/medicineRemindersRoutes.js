const express = require('express');
const router = express.Router();
const { protect } = require('../middleware/auth');
const User = require('../models/User');
const UserMedicine = require('../models/UserMedicine');
const MedicineDose = require('../models/MedicineDose');

// Helper function to normalize time to consistent format
function normalizeTime(time) {
  const trimmed = time.trim();
  
  // If already in 24-hour format (no AM/PM), return as-is with padding
  if (!trimmed.includes('AM') && !trimmed.includes('PM') && 
      !trimmed.includes('am') && !trimmed.includes('pm')) {
    const parts = trimmed.split(':');
    if (parts.length === 2) {
      return `${parts[0].padStart(2, '0')}:${parts[1].padStart(2, '0')}`;
    }
    return trimmed;
  }
  
  // Convert from 12-hour to 24-hour format
  const match = trimmed.match(/(\d+):(\d+)\s*(AM|PM)/i);
  if (!match) return trimmed;
  
  let hour = parseInt(match[1]);
  const minute = match[2];
  const period = match[3].toUpperCase();
  
  if (period === 'PM' && hour !== 12) hour += 12;
  if (period === 'AM' && hour === 12) hour = 0;
  
  return `${hour.toString().padStart(2, '0')}:${minute}`;
}

// @route   POST /api/user-medicines
// @desc    Add new medicine with doses
// @access  Private
router.post('/', protect, async (req, res) => {
  try {
    const { medicineName, dosage, startDate, endDate, notes, doses } = req.body;

    if (!medicineName || !dosage) {
      return res.status(400).json({ 
        success: false, 
        message: 'Medicine name and dosage are required' 
      });
    }

    // Create medicine
    const medicine = await UserMedicine.create({
      userId: req.user._id,
      medicineName,
      dosage,
      startDate: startDate ? new Date(startDate) : undefined,
      endDate: endDate ? new Date(endDate) : undefined,
      notes,
      isActive: true,
    });

    // Create doses if provided
    if (Array.isArray(doses) && doses.length > 0) {
      const doseDocs = doses.map(d => ({
        userMedicineId: medicine._id,
        time: d.time,
        instruction: d.instruction || '',
        frequency: d.frequency || 'daily',
        daysOfWeek: Array.isArray(d.daysOfWeek) ? d.daysOfWeek : [],
      }));
      await MedicineDose.insertMany(doseDocs);
    }

    console.log(`✅ Medicine added: ${medicineName} for user ${req.user.email}`);

    res.status(201).json({
      success: true,
      message: 'Medicine added successfully',
      data: medicine,
    });
  } catch (error) {
    console.error('Error adding medicine:', error);
    res.status(500).json({ 
      success: false, 
      message: error.message 
    });
  }
});

// @route   GET /api/user-medicines
// @desc    Get all user's medicines with doses
// @access  Private
router.get('/', protect, async (req, res) => {
  try {
    const medicines = await UserMedicine.find({
      userId: req.user._id,
      isActive: true,
    }).sort({ createdAt: -1 });

    // Get doses for each medicine
    const medicinesWithDoses = await Promise.all(
      medicines.map(async (medicine) => {
        const doses = await MedicineDose.find({
          userMedicineId: medicine._id,
        }).sort({ time: 1 });

        return {
          _id: medicine._id,
          medicineName: medicine.medicineName,
          dosage: medicine.dosage,
          startDate: medicine.startDate,
          endDate: medicine.endDate,
          notes: medicine.notes,
          takenHistory: medicine.takenHistory || [],
          doses: doses.map(d => ({
            _id: d._id,
            time: d.time,
            instruction: d.instruction || '',
            frequency: d.frequency,
          })),
        };
      })
    );

    res.json({
      success: true,
      medicines: medicinesWithDoses,
    });
  } catch (error) {
    console.error('Error fetching user medicines:', error);
    res.status(500).json({ error: error.message });
  }
});

// @route   GET /api/user-medicines/by-date
// @desc    Get medicines for a specific date
// @access  Private
router.get('/by-date', protect, async (req, res) => {
  try {
    const { date } = req.query;
    if (!date) {
      return res.status(400).json({ 
        success: false, 
        message: 'date parameter is required' 
      });
    }

    const medicines = await UserMedicine.find({
      userId: req.user._id,
      isActive: true,
    }).sort({ createdAt: -1 });

    // Get doses for each medicine
    const medicinesWithDoses = await Promise.all(
      medicines.map(async (medicine) => {
        const doses = await MedicineDose.find({
          userMedicineId: medicine._id,
        }).sort({ time: 1 });

        return {
          _id: medicine._id,
          medicineName: medicine.medicineName,
          dosage: medicine.dosage,
          startDate: medicine.startDate,
          endDate: medicine.endDate,
          notes: medicine.notes,
          takenHistory: medicine.takenHistory || [],
          doses: doses.map(d => ({
            _id: d._id,
            time: d.time,
            instruction: d.instruction || '',
            frequency: d.frequency,
          })),
        };
      })
    );

    res.json({
      success: true,
      data: medicinesWithDoses,
    });
  } catch (error) {
    console.error('Error fetching medicines by date:', error);
    res.status(500).json({ 
      success: false,
      message: error.message 
    });
  }
});

// @route   GET /api/medicine-reminders/calendar
// @desc    Get calendar data with medicine completion status
// @access  Private
router.get('/calendar', protect, async (req, res) => {
  try {
    const { month, year } = req.query;
    const startDate = new Date(year, month - 1, 1);
    const endDate = new Date(year, month, 0);

    const medicines = await UserMedicine.find({
      userId: req.user._id,
      isActive: true,
    });

    const calendar = {};

    // Build calendar data
    for (const medicine of medicines) {
      const doses = await MedicineDose.find({
        userMedicineId: medicine._id,
      });

      for (let date = new Date(startDate); date <= endDate; date.setDate(date.getDate() + 1)) {
        const dateStr = date.toISOString().split('T')[0];
        
        if (!calendar[dateStr]) {
          calendar[dateStr] = { medicines: [] };
        }

        for (const dose of doses) {
          const takenOnDate = medicine.takenHistory?.some(
            h => h.date === dateStr && h.time === dose.time
          ) || false;

          calendar[dateStr].medicines.push({
            medicineId: medicine._id,
            medicineName: medicine.medicineName,
            dosage: medicine.dosage,
            time: dose.time,
            isTaken: takenOnDate,
          });
        }
      }
    }

    res.json({
      success: true,
      calendar,
    });
  } catch (error) {
    console.error('Error fetching calendar:', error);
    res.status(500).json({ error: error.message });
  }
});

// @route   GET /api/medicine-reminders/today
// @desc    Get today's medicine reminders with completion status
// @access  Private
router.get('/today', protect, async (req, res) => {
  try {
    const today = new Date().toISOString().split('T')[0];
    
    // Get user's active medicines from UserMedicine collection
    const medicines = await UserMedicine.find({
      userId: req.user._id,
      isActive: true,
    });

    if (medicines.length === 0) {
      return res.json({
        success: true,
        reminders: [],
        date: today,
      });
    }

    // Build today's reminders with completion status
    const todaysReminders = [];
    
    for (const medicine of medicines) {
      // Get doses for this medicine
      const doses = await MedicineDose.find({
        userMedicineId: medicine._id,
      }).sort({ time: 1 });

      for (const dose of doses) {
        const takenToday = medicine.takenHistory?.some(
          h => h.date === today && h.time === dose.time
        ) || false;

        todaysReminders.push({
          _id: `${medicine._id}_${dose.time}`,
          medicineId: medicine._id,
          medicineName: medicine.medicineName,
          dosage: medicine.dosage,
          time: dose.time,
          isTaken: takenToday,
        });
      }
    }

    // Sort by time
    todaysReminders.sort((a, b) => a.time.localeCompare(b.time));

    res.json({
      success: true,
      reminders: todaysReminders,
      date: today,
    });
  } catch (error) {
    console.error('Error fetching today\'s reminders:', error);
    res.status(500).json({ error: error.message });
  }
});

// @route   PATCH /api/medicine-reminders/:id/mark-taken
// @desc    Mark medicine as taken for today
// @access  Private
router.patch('/:id/mark-taken', protect, async (req, res) => {
  try {
    const { date } = req.body;
    const medicineId = req.params.id.split('_')[0]; // Extract medicine ID from composite ID
    const time = req.params.id.split('_')[1]; // Extract time from composite ID

    const medicine = await UserMedicine.findOne({
      _id: medicineId,
      userId: req.user._id,
    });

    if (!medicine) {
      return res.status(404).json({ error: 'Medicine not found' });
    }

    // Initialize takenHistory if not exists
    if (!medicine.takenHistory) {
      medicine.takenHistory = [];
    }

    // Check if already marked as taken
    const alreadyTaken = medicine.takenHistory.some(
      h => h.date === date && h.time === time
    );

    if (!alreadyTaken) {
      medicine.takenHistory.push({
        date,
        time,
        takenAt: new Date(),
      });
      await medicine.save();
    }

    console.log(`✅ Medicine ${medicine.medicineName} marked as taken at ${time} for ${date}`);

    res.json({
      success: true,
      message: 'Medicine marked as taken',
    });
  } catch (error) {
    console.error('Error marking medicine as taken:', error);
    res.status(500).json({ error: error.message });
  }
});

// @route   PATCH /api/user-medicines/:id/unmark-taken
// @desc    Unmark medicine as taken (toggle back)
// @access  Private
router.patch('/:id/unmark-taken', protect, async (req, res) => {
  try {
    const { date } = req.body;
    const medicineId = req.params.id.split('_')[0];
    const time = req.params.id.split('_')[1];

    const medicine = await UserMedicine.findOne({
      _id: medicineId,
      userId: req.user._id,
    });

    if (!medicine) {
      return res.status(404).json({ error: 'Medicine not found' });
    }

    // Remove from takenHistory
    if (medicine.takenHistory) {
      medicine.takenHistory = medicine.takenHistory.filter(
        h => !(h.date === date && h.time === time)
      );
      await medicine.save();
    }

    console.log(`↩️ Medicine ${medicine.medicineName} unmarked for ${time} on ${date}`);

    res.json({
      success: true,
      message: 'Medicine unmarked',
    });
  } catch (error) {
    console.error('Error unmarking medicine:', error);
    res.status(500).json({ error: error.message });
  }
});

// @route   DELETE /api/user-medicines/:id
// @desc    Delete a medicine reminder
// @access  Private
router.delete('/:id', protect, async (req, res) => {
  try {
    const medicine = await UserMedicine.findOne({
      _id: req.params.id,
      userId: req.user._id,
    });

    if (!medicine) {
      return res.status(404).json({ 
        success: false,
        message: 'Medicine not found' 
      });
    }

    // Delete associated doses
    await MedicineDose.deleteMany({ userMedicineId: medicine._id });

    // Delete the medicine
    await UserMedicine.findByIdAndDelete(req.params.id);

    console.log(`🗑️ Medicine ${medicine.medicineName} deleted`);

    res.json({
      success: true,
      message: 'Medicine reminder deleted successfully',
    });
  } catch (error) {
    console.error('Error deleting medicine:', error);
    res.status(500).json({ 
      success: false,
      message: error.message 
    });
  }
});

// @route   PUT /api/user-medicines/:id
// @desc    Update a medicine reminder
// @access  Private
router.put('/:id', protect, async (req, res) => {
  try {
    const { medicineName, dosage, startDate, endDate, notes, doses } = req.body;

    const medicine = await UserMedicine.findOne({
      _id: req.params.id,
      userId: req.user._id,
    });

    if (!medicine) {
      return res.status(404).json({ 
        success: false,
        message: 'Medicine not found' 
      });
    }

    // Update medicine
    medicine.medicineName = medicineName || medicine.medicineName;
    medicine.dosage = dosage || medicine.dosage;
    medicine.startDate = startDate ? new Date(startDate) : medicine.startDate;
    medicine.endDate = endDate ? new Date(endDate) : medicine.endDate;
    medicine.notes = notes !== undefined ? notes : medicine.notes;
    await medicine.save();

    // Update doses if provided
    if (Array.isArray(doses)) {
      // Delete old doses
      await MedicineDose.deleteMany({ userMedicineId: medicine._id });
      
      // Create new doses
      if (doses.length > 0) {
        const doseDocs = doses.map(d => ({
          userMedicineId: medicine._id,
          time: d.time,
          instruction: d.instruction || '',
          frequency: d.frequency || 'daily',
          daysOfWeek: Array.isArray(d.daysOfWeek) ? d.daysOfWeek : [],
        }));
        await MedicineDose.insertMany(doseDocs);
      }
    }

    console.log(`✏️ Medicine ${medicine.medicineName} updated`);

    res.json({
      success: true,
      message: 'Medicine reminder updated successfully',
      data: medicine,
    });
  } catch (error) {
    console.error('Error updating medicine:', error);
    res.status(500).json({ 
      success: false,
      message: error.message 
    });
  }
});

// @route   GET /api/user-medicines/:id
// @desc    Get single medicine details with doses
// @access  Private
router.get('/:id', protect, async (req, res) => {
  try {
    const medicine = await UserMedicine.findOne({ 
      _id: req.params.id, 
      userId: req.user._id 
    });
    
    if (!medicine) {
      return res.status(404).json({ 
        success: false, 
        message: 'Medicine not found' 
      });
    }
    
    // Get doses for this medicine
    const doses = await MedicineDose.find({ userMedicineId: medicine._id });
    
    const medicineWithDoses = {
      ...medicine.toObject(),
      doses: doses
    };
    
    res.json({ 
      success: true, 
      data: medicineWithDoses 
    });
  } catch (error) {
    console.error('Error fetching medicine:', error);
    res.status(500).json({ 
      success: false,
      message: error.message 
    });
  }
});

// @route   POST /api/user-medicines/:id/mark-taken
// @desc    Mark medicine dose as taken
// @access  Private
router.post('/:id/mark-taken', protect, async (req, res) => {
  try {
    const { date, time } = req.body;

    if (!date || !time) {
      return res.status(400).json({ 
        success: false, 
        message: 'date and time are required' 
      });
    }

    const medicine = await UserMedicine.findOne({ 
      _id: req.params.id, 
      userId: req.user._id 
    });
    
    if (!medicine) {
      return res.status(404).json({ 
        success: false, 
        message: 'Medicine not found' 
      });
    }

    // Normalize the incoming time for consistent storage
    const normalizedTime = normalizeTime(time);

    // Check if already marked (compare normalized times)
    const alreadyTaken = medicine.takenHistory.some(h => {
      if (h.date !== date) return false;
      return normalizeTime(h.time) === normalizedTime;
    });
    
    if (alreadyTaken) {
      return res.json({ 
        success: true, 
        message: 'Already marked as taken' 
      });
    }

    // Add to history with normalized time
    medicine.takenHistory.push({
      date,
      time: normalizedTime,
      takenAt: new Date()
    });

    await medicine.save();

    console.log(`✅ Marked ${medicine.medicineName} as taken for ${date} ${normalizedTime}`);

    res.json({ 
      success: true, 
      message: 'Marked as taken', 
      data: medicine 
    });
  } catch (error) {
    console.error('Error marking medicine as taken:', error);
    res.status(500).json({ 
      success: false,
      message: error.message 
    });
  }
});

// @route   DELETE /api/user-medicines/:id/unmark-taken
// @desc    Unmark medicine dose
// @access  Private
router.delete('/:id/unmark-taken', protect, async (req, res) => {
  try {
    const { date, time } = req.body;

    if (!date || !time) {
      return res.status(400).json({ 
        success: false, 
        message: 'date and time are required' 
      });
    }

    const medicine = await UserMedicine.findOne({ 
      _id: req.params.id, 
      userId: req.user._id 
    });
    
    if (!medicine) {
      return res.status(404).json({ 
        success: false, 
        message: 'Medicine not found' 
      });
    }

    // Normalize time for comparison
    const normalizedTime = normalizeTime(time);

    // Remove from history (compare normalized times)
    medicine.takenHistory = medicine.takenHistory.filter(h => {
      if (h.date !== date) return true;
      return normalizeTime(h.time) !== normalizedTime;
    });

    await medicine.save();

    console.log(`↩️ Unmarked ${medicine.medicineName} for ${date} ${normalizedTime}`);

    res.json({ 
      success: true, 
      message: 'Unmarked', 
      data: medicine 
    });
  } catch (error) {
    console.error('Error unmarking medicine:', error);
    res.status(500).json({ 
      success: false,
      message: error.message 
    });
  }
});

module.exports = router;

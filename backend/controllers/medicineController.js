const UserMedicine = require('../models/UserMedicine');
const MedicineDose = require('../models/MedicineDose');
const { scheduleMedicineReminders, clearMedicineReminders } = require('../services/medicineReminderScheduler');

// Helper: parse date string to YYYY-MM-DD (local time)
function toDateKey(date) {
  const d = new Date(date);
  const y = d.getFullYear();
  const m = String(d.getMonth() + 1).padStart(2, '0');
  const day = String(d.getDate()).padStart(2, '0');
  return `${y}-${m}-${day}`;
}

// Helper: iterate days between two dates (inclusive)
function iterateDates(start, end) {
  const dates = [];
  const cur = new Date(start);
  cur.setHours(0,0,0,0);
  const last = new Date(end);
  last.setHours(0,0,0,0);
  while (cur <= last) {
    dates.push(new Date(cur));
    cur.setDate(cur.getDate() + 1);
  }
  return dates;
}

// POST /api/medicine/add
exports.addMedicine = async (req, res) => {
  try {
    const userId = req.user.id;
    const { medicineName, dosage, startDate, endDate, notes, doses } = req.body;

    if (!medicineName || !dosage) {
      return res.status(400).json({ success: false, message: 'medicineName and dosage are required' });
    }

    const userMedicine = await UserMedicine.create({
      userId,
      medicineName,
      dosage,
      startDate: startDate ? new Date(startDate) : undefined,
      endDate: endDate ? new Date(endDate) : undefined,
      notes,
      isActive: true
    });

    // create doses if provided
    if (Array.isArray(doses) && doses.length > 0) {
      const doseDocs = doses.map(d => ({
        userMedicineId: userMedicine._id,
        time: d.time,
        instruction: d.instruction || '',
        frequency: d.frequency || 'daily',
        daysOfWeek: Array.isArray(d.daysOfWeek) ? d.daysOfWeek : []
      }));
      await MedicineDose.insertMany(doseDocs);
    }

    // Populate doses for scheduling
    const medicineWithDoses = await UserMedicine.findById(userMedicine._id).lean();
    const dosesForMedicine = await MedicineDose.find({ userMedicineId: userMedicine._id }).lean();
    medicineWithDoses.doses = dosesForMedicine;

    // Schedule push notifications for this medicine
    scheduleMedicineReminders(medicineWithDoses);

    return res.status(201).json({ success: true, message: 'Medicine added', data: userMedicine });
  } catch (error) {
    return res.status(500).json({ success: false, message: error.message });
  }
};

// GET /api/medicine/calendar?month=MM&year=YYYY
exports.getCalendar = async (req, res) => {
  try {
    const userId = req.user.id;
    const month = parseInt(req.query.month, 10); // 1-12
    const year = parseInt(req.query.year, 10);

    if (!month || !year) {
      return res.status(400).json({ success: false, message: 'month and year are required' });
    }

    // compute first and last day of month
    const firstDay = new Date(year, month - 1, 1);
    const lastDay = new Date(year, month, 0);

    // fetch active user medicines
    const medicines = await UserMedicine.find({ userId, isActive: true }).lean();
    const medicineIds = medicines.map(m => m._id);
    const doses = await MedicineDose.find({ userMedicineId: { $in: medicineIds } }).lean();

    const calendar = {};

    medicines.forEach(med => {
      const medDoses = doses.filter(d => String(d.userMedicineId) === String(med._id));
      const s = med.startDate ? new Date(med.startDate) : firstDay;
      const e = med.endDate ? new Date(med.endDate) : lastDay;

      // clamp to month
      const start = s > firstDay ? s : firstDay;
      const end = e < lastDay ? e : lastDay;
      if (start > end) return; // no overlap

      const dateList = iterateDates(start, end);

      dateList.forEach(dateObj => {
        const weekday = dateObj.getDay(); // 0-6
        medDoses.forEach(d => {
          const freq = d.frequency || 'daily';
          let include = false;
          if (freq === 'daily') include = true;
          else if (freq === 'weekly') {
            if (Array.isArray(d.daysOfWeek) && d.daysOfWeek.length) {
              include = d.daysOfWeek.includes(weekday);
            }
          }

          if (include) {
            const key = toDateKey(dateObj);
            calendar[key] = calendar[key] || [];
            
            // Check if this dose was taken on this date
            const isTaken = med.takenHistory && med.takenHistory.some(h => {
              if (h.date !== key) return false;
              // Normalize both times to compare (handle both 12-hour and 24-hour formats)
              const doseTime = d.time.trim();
              const historyTime = h.time.trim();
              
              // Simple comparison first
              if (doseTime === historyTime) return true;
              
              // Try converting both to 24-hour format for comparison
              const normalize = (time) => {
                // If already 24-hour format (no AM/PM)
                if (!time.includes('AM') && !time.includes('PM')) {
                  const parts = time.split(':');
                  return parts.length === 2 ? `${parts[0].padStart(2, '0')}:${parts[1]}` : time;
                }
                // Convert 12-hour to 24-hour
                const match = time.match(/(\d+):(\d+)\s*(AM|PM)/i);
                if (!match) return time;
                let hour = parseInt(match[1]);
                const minute = match[2];
                const period = match[3].toUpperCase();
                if (period === 'PM' && hour !== 12) hour += 12;
                if (period === 'AM' && hour === 12) hour = 0;
                return `${hour.toString().padStart(2, '0')}:${minute}`;
              };
              
              return normalize(doseTime) === normalize(historyTime);
            });
            
            calendar[key].push({
              medicineId: med._id,
              medicineName: med.medicineName,
              dosage: med.dosage,
              time: d.time,
              isTaken: isTaken || false
            });
          }
        });
      });
    });

    return res.status(200).json({ success: true, data: calendar });
  } catch (error) {
    return res.status(500).json({ success: false, message: error.message });
  }
};

// GET /api/medicine/by-date?date=YYYY-MM-DD
exports.getByDate = async (req, res) => {
  try {
    const userId = req.user.id;
    const dateStr = req.query.date;
    if (!dateStr) return res.status(400).json({ success: false, message: 'date is required' });

    const dateObj = new Date(dateStr);
    if (isNaN(dateObj)) return res.status(400).json({ success: false, message: 'Invalid date' });

    // find active medicines that cover this date
    const medicines = await UserMedicine.find({ userId, isActive: true }).lean();
    const medicineIds = medicines.map(m => m._id);
    const doses = await MedicineDose.find({ userMedicineId: { $in: medicineIds } }).lean();

    const results = [];
    const dayKey = toDateKey(dateObj);
    const weekday = dateObj.getDay();

    medicines.forEach(med => {
      const s = med.startDate ? new Date(med.startDate) : null;
      const e = med.endDate ? new Date(med.endDate) : null;
      // check active range
      if (s && dateObj < new Date(s.getFullYear(), s.getMonth(), s.getDate())) return;
      if (e && dateObj > new Date(e.getFullYear(), e.getMonth(), e.getDate())) return;

      const medDoses = doses.filter(d => String(d.userMedicineId) === String(med._id));
      medDoses.forEach(d => {
        const freq = d.frequency || 'daily';
        let include = false;
        if (freq === 'daily') include = true;
        else if (freq === 'weekly') {
          if (Array.isArray(d.daysOfWeek) && d.daysOfWeek.length) {
            include = d.daysOfWeek.includes(weekday);
          }
        }
        if (include) {
          results.push({
            medicineId: med._id,
            medicineName: med.medicineName,
            dosage: med.dosage,
            time: d.time,
            notes: med.notes
          });
        }
      });
    });

    // sort by time (simple lexicographic, assumes times formatted consistently)
    results.sort((a,b) => a.time.localeCompare(b.time));

    return res.status(200).json({ success: true, date: dayKey, data: results });
  } catch (error) {
    return res.status(500).json({ success: false, message: error.message });
  }
};

// PUT /api/medicine/update/:id
exports.updateMedicine = async (req, res) => {
  try {
    const userId = req.user.id;
    const id = req.params.id;
    const { medicineName, dosage, startDate, endDate, notes, doses } = req.body;

    const med = await UserMedicine.findById(id);
    if (!med) return res.status(404).json({ success: false, message: 'Medicine not found' });
    if (String(med.userId) !== String(userId)) return res.status(403).json({ success: false, message: 'Not authorized' });

    med.medicineName = medicineName || med.medicineName;
    med.dosage = dosage || med.dosage;
    med.startDate = startDate ? new Date(startDate) : med.startDate;
    med.endDate = endDate ? new Date(endDate) : med.endDate;
    med.notes = notes || med.notes;
    await med.save();

    // if doses provided, replace existing
    if (Array.isArray(doses)) {
      await MedicineDose.deleteMany({ userMedicineId: med._id });
      const doseDocs = doses.map(d => ({
        userMedicineId: med._id,
        time: d.time,
        frequency: d.frequency || 'daily',
        daysOfWeek: Array.isArray(d.daysOfWeek) ? d.daysOfWeek : []
      }));
      if (doseDocs.length) await MedicineDose.insertMany(doseDocs);
    }

    // Reschedule reminders for updated medicine
    clearMedicineReminders(med._id);
    const medicineWithDoses = await UserMedicine.findById(med._id).lean();
    const dosesForMedicine = await MedicineDose.find({ userMedicineId: med._id }).lean();
    medicineWithDoses.doses = dosesForMedicine;
    scheduleMedicineReminders(medicineWithDoses);

    return res.status(200).json({ success: true, message: 'Medicine updated', data: med });
  } catch (error) {
    return res.status(500).json({ success: false, message: error.message });
  }
};

// DELETE /api/medicine/delete/:id (soft delete)
exports.deleteMedicine = async (req, res) => {
  try {
    const userId = req.user.id;
    const id = req.params.id;
    const med = await UserMedicine.findById(id);
    if (!med) return res.status(404).json({ success: false, message: 'Medicine not found' });
    if (String(med.userId) !== String(userId)) return res.status(403).json({ success: false, message: 'Not authorized' });

    med.isActive = false;
    await med.save();

    // Clear all reminders for this medicine
    clearMedicineReminders(id);

    return res.status(200).json({ success: true, message: 'Medicine soft-deleted' });
  } catch (error) {
    return res.status(500).json({ success: false, message: error.message });
  }
};

// GET /api/medicine/list - Get all user's medicines
exports.getAllMedicines = async (req, res) => {
  try {
    const userId = req.user.id;
    const medicines = await UserMedicine.find({ userId, isActive: true }).sort({ createdAt: -1 });
    
    // Get doses for each medicine
    const medicineIds = medicines.map(m => m._id);
    const doses = await MedicineDose.find({ userMedicineId: { $in: medicineIds } });
    
    // Attach doses to medicines
    const medicinesWithDoses = medicines.map(med => {
      const medDoses = doses.filter(d => String(d.userMedicineId) === String(med._id));
      return {
        ...med.toObject(),
        doses: medDoses
      };
    });

    return res.status(200).json({ success: true, data: medicinesWithDoses });
  } catch (error) {
    return res.status(500).json({ success: false, message: error.message });
  }
};

// GET /api/user-medicines/:id - Get single medicine details
exports.getMedicine = async (req, res) => {
  try {
    const userId = req.user.id;
    const medicineId = req.params.id;
    
    const medicine = await UserMedicine.findOne({ _id: medicineId, userId });
    if (!medicine) {
      return res.status(404).json({ success: false, message: 'Medicine not found' });
    }
    
    // Get doses for this medicine
    const doses = await MedicineDose.find({ userMedicineId: medicineId });
    
    const medicineWithDoses = {
      ...medicine.toObject(),
      doses: doses
    };
    
    return res.status(200).json({ success: true, data: medicineWithDoses });
  } catch (error) {
    return res.status(500).json({ success: false, message: error.message });
  }
};

// POST /api/user-medicines/:id/mark-taken
exports.markAsTaken = async (req, res) => {
  try {
    const userId = req.user.id;
    const medicineId = req.params.id;
    const { date, time } = req.body;

    if (!date || !time) {
      return res.status(400).json({ success: false, message: 'date and time are required' });
    }

    const medicine = await UserMedicine.findOne({ _id: medicineId, userId });
    if (!medicine) {
      return res.status(404).json({ success: false, message: 'Medicine not found' });
    }

    // Check if already marked
    const alreadyTaken = medicine.takenHistory.some(h => h.date === date && h.time === time);
    if (alreadyTaken) {
      return res.status(200).json({ success: true, message: 'Already marked as taken' });
    }

    // Add to history
    medicine.takenHistory.push({
      date,
      time,
      takenAt: new Date()
    });

    await medicine.save();

    return res.status(200).json({ success: true, message: 'Marked as taken', data: medicine });
  } catch (error) {
    return res.status(500).json({ success: false, message: error.message });
  }
};

// DELETE /api/user-medicines/:id/unmark-taken
exports.unmarkAsTaken = async (req, res) => {
  try {
    const userId = req.user.id;
    const medicineId = req.params.id;
    const { date, time } = req.body;

    if (!date || !time) {
      return res.status(400).json({ success: false, message: 'date and time are required' });
    }

    const medicine = await UserMedicine.findOne({ _id: medicineId, userId });
    if (!medicine) {
      return res.status(404).json({ success: false, message: 'Medicine not found' });
    }

    // Remove from history
    medicine.takenHistory = medicine.takenHistory.filter(h => 
      !(h.date === date && h.time === time)
    );

    await medicine.save();

    return res.status(200).json({ success: true, message: 'Unmarked', data: medicine });
  } catch (error) {
    return res.status(500).json({ success: false, message: error.message });
  }
};

const MedicineStock = require('../models/MedicineStock');
const User = require('../models/User');

// @desc    Add new medicine to stock
// @route   POST /api/medicine-stock
// @access  Private (Pharmacist only)
exports.addMedicine = async (req, res) => {
  try {
    const pharmacistId = req.user.id;
    
    // Verify user is a pharmacist
    const user = await User.findById(pharmacistId);
    if (!user || user.role !== 'pharmacist') {
      return res.status(403).json({
        success: false,
        message: 'Only pharmacists can manage medicine stock'
      });
    }

    const {
      medicineName,
      batchNumber,
      expiryDate,
      quantity,
      price,
      manufacturer,
      category,
      lowStockLevel
    } = req.body;

    const medicine = await MedicineStock.create({
      pharmacistId,
      medicineName,
      batchNumber,
      expiryDate,
      quantity,
      price,
      manufacturer,
      category,
      lowStockLevel: lowStockLevel || 10
    });

    res.status(201).json({
      success: true,
      message: 'Medicine added to stock successfully',
      data: medicine
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
};

// @desc    Get all medicines in stock
// @route   GET /api/medicine-stock
// @access  Private (Pharmacist only)
exports.getAllMedicines = async (req, res) => {
  try {
    const pharmacistId = req.user.id;
    
    const medicines = await MedicineStock.find({ pharmacistId })
      .sort({ medicineName: 1 });

    // Categorize medicines
    const lowStockMedicines = medicines.filter(m => m.isLowStock);
    const expiringMedicines = medicines.filter(m => m.isExpiringSoon);

    res.status(200).json({
      success: true,
      data: {
        medicines,
        summary: {
          total: medicines.length,
          lowStock: lowStockMedicines.length,
          expiringSoon: expiringMedicines.length,
          totalValue: medicines.reduce((sum, m) => sum + (m.quantity * m.price), 0)
        },
        alerts: {
          lowStock: lowStockMedicines,
          expiringSoon: expiringMedicines
        }
      }
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
};

// @desc    Get single medicine by ID
// @route   GET /api/medicine-stock/:id
// @access  Private (Pharmacist only)
exports.getMedicineById = async (req, res) => {
  try {
    const medicine = await MedicineStock.findById(req.params.id);

    if (!medicine) {
      return res.status(404).json({
        success: false,
        message: 'Medicine not found'
      });
    }

    // Verify ownership
    if (medicine.pharmacistId.toString() !== req.user.id) {
      return res.status(403).json({
        success: false,
        message: 'Not authorized to access this medicine'
      });
    }

    res.status(200).json({
      success: true,
      data: medicine
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
};

// @desc    Update medicine stock
// @route   PUT /api/medicine-stock/:id
// @access  Private (Pharmacist only)
exports.updateMedicine = async (req, res) => {
  try {
    let medicine = await MedicineStock.findById(req.params.id);

    if (!medicine) {
      return res.status(404).json({
        success: false,
        message: 'Medicine not found'
      });
    }

    // Verify ownership
    if (medicine.pharmacistId.toString() !== req.user.id) {
      return res.status(403).json({
        success: false,
        message: 'Not authorized to update this medicine'
      });
    }

    medicine = await MedicineStock.findByIdAndUpdate(
      req.params.id,
      req.body,
      { new: true, runValidators: true }
    );

    res.status(200).json({
      success: true,
      message: 'Medicine updated successfully',
      data: medicine
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
};

// @desc    Delete medicine from stock
// @route   DELETE /api/medicine-stock/:id
// @access  Private (Pharmacist only)
exports.deleteMedicine = async (req, res) => {
  try {
    const medicine = await MedicineStock.findById(req.params.id);

    if (!medicine) {
      return res.status(404).json({
        success: false,
        message: 'Medicine not found'
      });
    }

    // Verify ownership
    if (medicine.pharmacistId.toString() !== req.user.id) {
      return res.status(403).json({
        success: false,
        message: 'Not authorized to delete this medicine'
      });
    }

    await medicine.deleteOne();

    res.status(200).json({
      success: true,
      message: 'Medicine deleted successfully'
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
};

// @desc    Update stock quantity
// @route   PATCH /api/medicine-stock/:id/quantity
// @access  Private (Pharmacist only)
exports.updateQuantity = async (req, res) => {
  try {
    const { quantity, action } = req.body; // action: 'add' or 'subtract'

    const medicine = await MedicineStock.findById(req.params.id);

    if (!medicine) {
      return res.status(404).json({
        success: false,
        message: 'Medicine not found'
      });
    }

    // Verify ownership
    if (medicine.pharmacistId.toString() !== req.user.id) {
      return res.status(403).json({
        success: false,
        message: 'Not authorized'
      });
    }

    if (action === 'add') {
      medicine.quantity += quantity;
    } else if (action === 'subtract') {
      if (medicine.quantity < quantity) {
        return res.status(400).json({
          success: false,
          message: 'Insufficient stock'
        });
      }
      medicine.quantity -= quantity;
    }

    await medicine.save();

    res.status(200).json({
      success: true,
      message: 'Quantity updated successfully',
      data: medicine
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
};

// @desc    Search medicines
// @route   GET /api/medicine-stock/search/:query
// @access  Private (Pharmacist only)
exports.searchMedicines = async (req, res) => {
  try {
    const pharmacistId = req.user.id;
    const query = req.params.query;

    const medicines = await MedicineStock.find({
      pharmacistId,
      $or: [
        { medicineName: { $regex: query, $options: 'i' } },
        { manufacturer: { $regex: query, $options: 'i' } },
        { category: { $regex: query, $options: 'i' } },
        { batchNumber: { $regex: query, $options: 'i' } }
      ]
    });

    res.status(200).json({
      success: true,
      data: medicines
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
};

// @desc    Get low stock alerts
// @route   GET /api/medicine-stock/alerts/low-stock
// @access  Private (Pharmacist only)
exports.getLowStockAlerts = async (req, res) => {
  try {
    const pharmacistId = req.user.id;
    
    const medicines = await MedicineStock.find({ pharmacistId });
    const lowStockMedicines = medicines.filter(m => m.isLowStock);

    res.status(200).json({
      success: true,
      count: lowStockMedicines.length,
      data: lowStockMedicines
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
};

// @desc    Get expiry alerts
// @route   GET /api/medicine-stock/alerts/expiring
// @access  Private (Pharmacist only)
exports.getExpiryAlerts = async (req, res) => {
  try {
    const pharmacistId = req.user.id;
    
    const medicines = await MedicineStock.find({ pharmacistId });
    const expiringMedicines = medicines.filter(m => m.isExpiringSoon);

    res.status(200).json({
      success: true,
      count: expiringMedicines.length,
      data: expiringMedicines
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
};

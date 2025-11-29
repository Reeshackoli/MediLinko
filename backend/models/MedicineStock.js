const mongoose = require('mongoose');

const medicineStockSchema = new mongoose.Schema({
  pharmacistId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  medicineName: {
    type: String,
    required: [true, 'Medicine name is required'],
    trim: true
  },
  batchNumber: {
    type: String,
    required: [true, 'Batch number is required'],
    trim: true
  },
  expiryDate: {
    type: Date,
    required: [true, 'Expiry date is required']
  },
  quantity: {
    type: Number,
    required: [true, 'Quantity is required'],
    min: 0
  },
  lowStockLevel: {
    type: Number,
    default: 10,
    min: 0
  },
  lastExpiryAlertSent: {
    type: Date,
    default: null
  },
  lastLowStockAlertSent: {
    type: Date,
    default: null
  }
}, {
  timestamps: true
});

// Indexes for faster queries
medicineStockSchema.index({ pharmacistId: 1 });
medicineStockSchema.index({ medicineName: 1 });
medicineStockSchema.index({ expiryDate: 1 });
medicineStockSchema.index({ quantity: 1 });

// Virtual to check if stock is low
medicineStockSchema.virtual('isLowStock').get(function() {
  return this.quantity <= this.lowStockLevel;
});

// Virtual to check if expiring soon (within 30 days)
medicineStockSchema.virtual('isExpiringSoon').get(function() {
  const thirtyDaysFromNow = new Date();
  thirtyDaysFromNow.setDate(thirtyDaysFromNow.getDate() + 30);
  return this.expiryDate <= thirtyDaysFromNow;
});

module.exports = mongoose.model('MedicineStock', medicineStockSchema);

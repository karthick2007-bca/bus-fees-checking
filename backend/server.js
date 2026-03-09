const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const path = require('path');
require('dotenv').config({ silent: true });

const app = express();
app.use(cors());
app.use(express.json());

// Global error logger
app.use((req, res, next) => {
  console.log(`${new Date().toISOString()} - ${req.method} ${req.path}`);
  next();
});

// Serve static files from public directory
app.use(express.static(path.join(__dirname, 'public')));

// MongoDB Connection
const MONGODB_URI = process.env.MONGODB_URI || 'mongodb+srv://karthi2142007:karthi2024@cluster0.nfyak0h.mongodb.net/karthick?retryWrites=true&w=majority';
const RAZORPAY_KEY_SECRET = process.env.RAZORPAY_KEY_SECRET || 'AaGkFvMKbn1QDgQ1m0mH80JI';

mongoose.connect(MONGODB_URI, {
  useNewUrlParser: true,
  useUnifiedTopology: true,
  maxPoolSize: 10,
  serverSelectionTimeoutMS: 30000,
  socketTimeoutMS: 45000,
})
.then(() => console.log('MongoDB Connected to:', MONGODB_URI.split('@')[1]))
.catch(err => console.error('MongoDB Connection Error:', err));

// Student Schema
const studentSchema = new mongoose.Schema({
  id: String,
  name: String,
  rollNo: String,
  address: String,
  email: String,
  phone: String,
  parentName: String,
  studentClass: String,
  dob: Date,
  location: String,
  amountPaid: Number,
  totalDue: Number,
  status: String,
  lastUpdated: Date,
  payments: Array,
  locationHistory: Array,
  reportGenerated: { type: Date, default: null },
});

studentSchema.index({ phone: 1, dob: 1 });
studentSchema.index({ phone: 1 });
const Student = mongoose.model('Student', studentSchema);

// Report Schema
const reportSchema = new mongoose.Schema({
  studentId: String,
  phone: String,
  name: String,
  rollNo: String,
  studentClass: String,
  parentName: String,
  address: String,
  location: String,
  totalDue: Number,
  amountPaid: Number,
  status: String,
  dob: String,
  generatedAt: { type: Date, default: Date.now },
});

const Report = mongoose.model('Report', reportSchema);

// Location Schema
const locationSchema = new mongoose.Schema({
  id: String,
  name: String,
  fee: Number,
});

locationSchema.index({ id: 1 });
const Location = mongoose.model('Location', locationSchema);

// Recycle Bin Schema
const recycleBinSchema = new mongoose.Schema({
  type: String, // 'student' or 'location'
  data: Object,
  deletedAt: { type: Date, default: Date.now },
});

const RecycleBin = mongoose.model('RecycleBin', recycleBinSchema);

// Transaction Schema
const transactionSchema = new mongoose.Schema({
  paymentId: String,
  orderId: String,
  studentId: String,
  studentName: String,
  amount: Number,
  status: String,
  createdAt: { type: Date, default: Date.now },
});

transactionSchema.index({ createdAt: -1 });
const Transaction = mongoose.model('Transaction', transactionSchema);

// Notification Schema
const notificationSchema = new mongoose.Schema({
  studentName: String,
  phone: String,
  amount: Number,
  location: String,
  paymentId: String,
  read: { type: Boolean, default: false },
  createdAt: { type: Date, default: Date.now },
});

notificationSchema.index({ createdAt: -1 });
const Notification = mongoose.model('Notification', notificationSchema);

// Routes with error handling
app.get('/api/students', async (req, res) => {
  try {
    const students = await Student.find().lean();
    res.json(students);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.post('/api/students', async (req, res) => {
  try {
    // Check if student exists by phone and dob
    const existing = await Student.findOne({ phone: req.body.phone, dob: req.body.dob });
    
    if (existing) {
      // Update existing student
      Object.assign(existing, req.body);
      await existing.save();
      
      // Create notification if payment successful
      if (req.body.status === 'succeed' && req.body.amountPaid > 0) {
        await Notification.create({
          studentName: req.body.name,
          phone: req.body.phone,
          amount: req.body.amountPaid,
          location: req.body.location,
          paymentId: req.body.payments?.[req.body.payments.length - 1]?.paymentId || 'N/A',
        });
      }
      
      res.status(200).json(existing);
    } else {
      // Create new student
      const student = new Student(req.body);
      await student.save();
      
      // Create notification if payment successful
      if (req.body.status === 'succeed' && req.body.amountPaid > 0) {
        await Notification.create({
          studentName: req.body.name,
          phone: req.body.phone,
          amount: req.body.amountPaid,
          location: req.body.location,
          paymentId: req.body.payments?.[req.body.payments.length - 1]?.paymentId || 'N/A',
        });
      }
      
      res.status(201).json(student);
    }
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.get('/api/locations', async (req, res) => {
  try {
    const locations = await Location.find().lean();
    res.json(locations);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.post('/api/locations', async (req, res) => {
  try {
    const existing = await Location.findOne({ id: req.body.id });
    
    if (existing) {
      existing.name = req.body.name;
      existing.fee = req.body.fee;
      await existing.save();
      res.status(200).json(existing);
    } else {
      const location = new Location(req.body);
      await location.save();
      res.status(201).json(location);
    }
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.delete('/api/locations/:id', async (req, res) => {
  try {
    const location = await Location.findOne({ id: req.params.id });
    if (location) {
      await RecycleBin.create({ type: 'location', data: location.toObject() });
      await Location.findOneAndDelete({ id: req.params.id });
    }
    res.status(204).send();
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.get('/api/recyclebin', async (req, res) => {
  try {
    const items = await RecycleBin.find().sort({ deletedAt: -1 }).lean();
    res.json(items);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.post('/api/recyclebin/restore/:id', async (req, res) => {
  try {
    const item = await RecycleBin.findById(req.params.id);
    if (item) {
      if (item.type === 'student') {
        await Student.create(item.data);
      } else if (item.type === 'location') {
        await Location.create(item.data);
      }
      await RecycleBin.findByIdAndDelete(req.params.id);
    }
    res.status(200).send();
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.delete('/api/recyclebin/:id', async (req, res) => {
  try {
    await RecycleBin.findByIdAndDelete(req.params.id);
    res.status(204).send();
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.put('/api/students/:phone', async (req, res) => {
  try {
    const student = await Student.findOneAndUpdate(
      { phone: req.params.phone },
      req.body,
      { new: true }
    );
    res.json(student);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.delete('/api/locations', async (req, res) => {
  try {
    await Location.deleteMany({});
    res.status(204).send();
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Generate and save report
app.post('/api/reports', async (req, res) => {
  try {
    const report = new Report(req.body);
    await report.save();
    
    await Student.findOneAndUpdate(
      { phone: req.body.phone },
      { reportGenerated: new Date() }
    );
    
    res.status(201).json(report);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Get all reports
app.get('/api/reports', async (req, res) => {
  try {
    const reports = await Report.find().lean();
    res.json(reports);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Student login
app.post('/api/students/login', async (req, res) => {
  try {
    const { phone, dob } = req.body;
    const student = await Student.findOne({ phone, dob: new Date(dob) });
    if (student) {
      res.json(student);
    } else {
      res.status(404).json({ error: 'Student not found' });
    }
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Get notifications
app.get('/api/notifications', async (req, res) => {
  try {
    const notifications = await Notification.find().sort({ createdAt: -1 }).lean();
    res.json(notifications);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Mark notification as read
app.put('/api/notifications/:id', async (req, res) => {
  try {
    await Notification.findByIdAndUpdate(req.params.id, { read: true });
    res.status(200).send();
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Delete notification
app.delete('/api/notifications/:id', async (req, res) => {
  try {
    await Notification.findByIdAndDelete(req.params.id);
    res.status(204).send();
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Transaction routes
app.post('/api/transactions', async (req, res) => {
  try {
    const transaction = new Transaction(req.body);
    await transaction.save();
    res.status(201).json(transaction);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.get('/api/transactions', async (req, res) => {
  try {
    const transactions = await Transaction.find().sort({ createdAt: -1 }).lean();
    res.json(transactions);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

const PORT = process.env.PORT || 3000;

// Serve frontend for all other routes
app.get('*', (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

// Global error handler (must be last)
app.use((err, req, res, next) => {
  console.error(`ERROR: ${err.message}`);
  res.status(500).json({ error: 'Internal server error' });
});

app.listen(PORT, '0.0.0.0', () => console.log(`Server running on port ${PORT}`));

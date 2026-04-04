const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const path = require('path');
require('dotenv').config();


const app = express();

app.use(cors());


// CORS configuration
app.use(cors({
  origin: '*',
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization', 'Accept'],
  credentials: true
}));

// Handle preflight requests
app.options('*', cors());

app.use(express.json());

// Request logger
app.use((req, res, next) => {
  console.log(`${new Date().toISOString()} - ${req.method} ${req.path}`);
  next();
});

// Serve static files
app.use(express.static(path.join(__dirname, 'public')));

// MongoDB Connection with proper error handling
const MONGODB_URI = process.env.MONGODB_URI || 'mongodb+srv://karthi2142007:karthi2024@cluster0.nfyak0h.mongodb.net/karthick?retryWrites=true&w=majority';

console.log('Attempting to connect to MongoDB...');
console.log('MongoDB URI:', MONGODB_URI.replace(/\/\/[^:]+:[^@]+@/, '//***:***@'));

// Connection options
const mongooseOptions = {
  useNewUrlParser: true,
  useUnifiedTopology: true,
  serverSelectionTimeoutMS: 30000,
  socketTimeoutMS: 45000,
  connectTimeoutMS: 30000,
  maxPoolSize: 10,
  minPoolSize: 2,
  retryWrites: true,
  retryReads: true
};

// Connect to MongoDB
mongoose.connect(MONGODB_URI, mongooseOptions)
  .then(() => {
    console.log('✅ MongoDB Connected successfully');
    console.log('Database:', mongoose.connection.name);
    console.log('Host:', mongoose.connection.host);
    console.log('Port:', mongoose.connection.port);
  })
  .catch(err => {
    console.error('❌ MongoDB Connection Error:');
    console.error('Error Name:', err.name);
    console.error('Error Message:', err.message);
    console.error('Error Code:', err.code);
    
    if (err.name === 'MongoNetworkError') {
      console.error('🔴 Network Error: Check if your IP is whitelisted in MongoDB Atlas');
      console.error('Go to: https://cloud.mongodb.com -> Network Access -> Add IP Address');
      console.error('Add 0.0.0.0/0 for testing or your server IP');
    } else if (err.name === 'MongoParseError') {
      console.error('🔴 Connection string parse error: Check your MongoDB URI format');
    } else if (err.message.includes('authentication failed')) {
      console.error('🔴 Authentication failed: Check username and password');
    } else if (err.message.includes('getaddrinfo ENOTFOUND')) {
      console.error('🔴 Cannot resolve MongoDB hostname: Check cluster name in URI');
    }
    
    // Don't exit, let the app try to reconnect
  });

// Connection event listeners
mongoose.connection.on('connected', () => {
  console.log('✅ Mongoose connected to MongoDB');
});

mongoose.connection.on('error', (err) => {
  console.error('❌ Mongoose connection error:', err.message);
});

mongoose.connection.on('disconnected', () => {
  console.log('⚠️ Mongoose disconnected from MongoDB');
});

mongoose.connection.on('reconnected', () => {
  console.log('✅ Mongoose reconnected to MongoDB');
});

// Graceful shutdown
process.on('SIGINT', async () => {
  await mongoose.connection.close();
  console.log('Mongoose connection closed due to app termination');
  process.exit(0);
});

process.on('SIGTERM', async () => {
  await mongoose.connection.close();
  console.log('Mongoose connection closed due to app termination');
  process.exit(0);
});

// Test database connection endpoint
app.get('/api/health', async (req, res) => {
  try {
    const dbState = mongoose.connection.readyState;
    const states = {
      0: 'disconnected',
      1: 'connected',
      2: 'connecting',
      3: 'disconnecting'
    };
    
    const studentCount = await Student.countDocuments().maxTimeMS(5000);
    
    res.json({
      status: 'OK',
      database: {
        state: states[dbState] || 'unknown',
        connected: dbState === 1,
        name: mongoose.connection.name || 'N/A',
        host: mongoose.connection.host || 'N/A'
      },
      stats: {
        totalStudents: studentCount
      },
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    res.status(500).json({
      status: 'ERROR',
      error: error.message,
      database: {
        state: 'error',
        connected: false
      }
    });
  }
});

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
  dob: String, // Changed to String for easier comparison
  location: String,
  amountPaid: Number,
  totalDue: Number,
  status: String,
  lastUpdated: Date,
  payments: Array,
  locationHistory: Array,
  reportGenerated: { type: Date, default: null },
});

// Create indexes
studentSchema.index({ phone: 1 });
studentSchema.index({ phone: 1, dob: 1 });

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
  type: String,
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

// ==================== API ROUTES ====================

// STUDENT LOGIN - FIXED VERSION
app.post('/api/students/login', async (req, res) => {
  try {
    // Check database connection first
    if (mongoose.connection.readyState !== 1) {
      console.log('Database not connected. State:', mongoose.connection.readyState);
      return res.status(503).json({ 
        error: 'Database service unavailable',
        details: 'Please try again in a few moments'
      });
    }

    const { phone, dob } = req.body;
    
    // Validate input
    if (!phone || !dob) {
      return res.status(400).json({ 
        error: 'Phone number and date of birth are required' 
      });
    }

    console.log('Login attempt:', { phone, dob });

    // Clean the phone number (remove any non-numeric characters)
    const cleanPhone = phone.toString().replace(/\D/g, '');
    
    // Try to find student with exact match (both as strings)
    let student = await Student.findOne({ 
      phone: cleanPhone, 
      dob: dob.toString().trim() 
    });

    // If not found, try without cleaning (in case phone is stored differently)
    if (!student) {
      student = await Student.findOne({ 
        phone: phone.toString().trim(), 
        dob: dob.toString().trim() 
      });
    }

    // If still not found, try with phone only (for debugging)
    if (!student) {
      console.log('Student not found with phone + dob, trying phone only search');
      const studentsWithPhone = await Student.find({ phone: cleanPhone }).limit(5);
      console.log('Found students with same phone:', studentsWithPhone.length);
      
      if (studentsWithPhone.length > 0) {
        console.log('Sample student DOB:', studentsWithPhone[0].dob);
        console.log('Provided DOB:', dob);
      }
    }

    if (student) {
      console.log('✅ Login successful for:', student.name);
      
      // Don't send sensitive data
      const studentData = student.toObject();
      delete studentData.payments;
      delete studentData.locationHistory;
      
      res.json({
        success: true,
        student: studentData
      });
    } else {
      console.log('❌ No student found with phone:', cleanPhone);
      res.status(404).json({ 
        error: 'Invalid phone number or date of birth',
        details: 'Please check your credentials and try again'
      });
    }
  } catch (err) {
    console.error('❌ Login error:', err);
    res.status(500).json({ 
      error: 'Server error during login',
      details: err.message 
    });
  }
});

// Get all students
app.get('/api/students', async (req, res) => {
  try {
    const students = await Student.find().lean();
    res.json(students);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Add/Update student
app.post('/api/students', async (req, res) => {
  try {
    console.log('Received student data:', req.body);
    
    if (mongoose.connection.readyState !== 1) {
      return res.status(503).json({ error: 'Database not connected' });
    }
    
    const existing = await Student.findOne({ phone: req.body.phone, dob: req.body.dob });
    
    if (existing) {
      Object.assign(existing, req.body);
      await existing.save();
      
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
      const student = new Student(req.body);
      await student.save();
      
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

// Get all locations
app.get('/api/locations', async (req, res) => {
  try {
    const locations = await Location.find().lean();
    res.json(locations);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Add/Update location
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

// Update location fee by id
app.put('/api/locations/:id', async (req, res) => {
  try {
    const location = await Location.findOneAndUpdate(
      { id: req.params.id },
      { fee: req.body.fee, name: req.body.name },
      { new: true }
    );
    if (!location) return res.status(404).json({ error: 'Location not found' });
    res.json(location);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Delete location
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

// Get recycle bin items
app.get('/api/recyclebin', async (req, res) => {
  try {
    const items = await RecycleBin.find().sort({ deletedAt: -1 }).lean();
    res.json(items);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Restore from recycle bin
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

// Delete from recycle bin
app.delete('/api/recyclebin/:id', async (req, res) => {
  try {
    await RecycleBin.findByIdAndDelete(req.params.id);
    res.status(204).send();
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Update student by MongoDB _id - updates student AND report together
app.put('/api/students/id/:id', async (req, res) => {
  try {
    let student;
    try {
      student = await Student.findByIdAndUpdate(
        req.params.id,
        { $set: req.body },
        { new: true }
      );
    } catch (e) {}
    if (!student) {
      student = await Student.findOneAndUpdate(
        { id: req.params.id },
        { $set: req.body },
        { new: true }
      );
    }
    if (!student) return res.status(404).json({ error: 'Student not found' });
    await Report.updateMany(
      { phone: student.phone },
      { $set: {
        name: req.body.name ?? student.name,
        rollNo: req.body.rollNo ?? student.rollNo,
        studentClass: req.body.studentClass ?? student.studentClass,
        parentName: req.body.parentName ?? student.parentName,
        address: req.body.address ?? student.address,
      }}
    );
    res.json(student);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Update student by phone
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

// Delete all locations
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

// Update report by phone (sync when admin edits student)
app.put('/api/reports/phone/:phone', async (req, res) => {
  try {
    await Report.updateMany(
      { phone: req.params.phone },
      { $set: req.body }
    );
    res.json({ success: true });
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

// Create transaction
app.post('/api/transactions', async (req, res) => {
  try {
    const transaction = new Transaction(req.body);
    await transaction.save();
    res.status(201).json(transaction);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Get all transactions
app.get('/api/transactions', async (req, res) => {
  try {
    const transactions = await Transaction.find().sort({ createdAt: -1 }).lean();
    res.json(transactions);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Debug endpoint to check database data
app.get('/api/debug/students', async (req, res) => {
  try {
    const count = await Student.countDocuments();
    const sample = await Student.find().limit(5).select('phone name dob');
    
    res.json({
      totalStudents: count,
      sampleStudents: sample,
      dbConnected: mongoose.connection.readyState === 1
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Serve frontend for all other routes
// Razorpay web checkout for desktop fallback
app.get('/pay', (req, res) => {
  const { amount, name, phone, email } = req.query;
  const html = `<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Pay | Razorpay Checkout</title>
  <script src="https://checkout.razorpay.com/v1/checkout.js"></script>
  <style>
    body { font-family: system-ui, -apple-system, Segoe UI, Roboto, Ubuntu, Cantarell, Noto Sans, Helvetica, Arial, 'Apple Color Emoji', 'Segoe UI Emoji'; padding: 24px; }
    .card { max-width: 480px; margin: 0 auto; padding: 24px; border: 1px solid #e5e7eb; border-radius: 12px; box-shadow: 0 10px 15px -3px rgb(0 0 0 / 0.1); }
    .btn { background: #4F46E5; color: #fff; border: 0; padding: 12px 16px; border-radius: 8px; cursor: pointer; font-size: 16px; }
    .btn:disabled { opacity: .5; cursor: not-allowed; }
  </style>
</head>
<body>
  <div class="card">
    <h2>Student Fee Payment</h2>
    <p>Name: ${name || ''}</p>
    <p>Phone: ${phone || ''}</p>
    <p>Amount: ₹${(parseInt(amount || '0')/100).toFixed(2)}</p>
    <button id="pay" class="btn">Pay with Razorpay</button>
  </div>

  <script>
    const options = {
      key: 'rzp_live_SNyLCysaEf0ooI',
      amount: ${Number.isFinite(parseInt(`${amount || 0}`)) ? amount : '0'},
      currency: 'INR',
      name: 'Fee Payment',
      description: 'Student Fee Payment',
      prefill: { contact: '${phone || ''}', email: '${email || ''}', name: '${name || ''}' },
      theme: { color: '#4F46E5' },
      handler: function (response) {
        alert('Payment Success: ' + response.razorpay_payment_id);
        window.close();
      },
      modal: { ondismiss: function() { alert('Payment cancelled'); } }
    };
    document.getElementById('pay').onclick = function() {
      const rzp = new Razorpay(options);
      rzp.open();
    };
  </script>
</body>
</html>`;
  res.set('Content-Type', 'text/html');
  res.send(html);
});

app.get('*', (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

// Global error handler
app.use((err, req, res, next) => {
  console.error('❌ Global error:', err);
  res.status(500).json({ 
    error: 'Internal server error',
    message: err.message 
  });
});

// ... mela ulla code ellam apdiye irukkatum ...

const PORT = process.env.PORT || 3000;
module.exports = app;
// Indha listen function-ah Vercel-la skip pannidunga
if (process.env.NODE_ENV !== 'production') {
    app.listen(PORT, () => {
        console.log(`Server running on port ${PORT}`);
    });
}

// IDHU THAAN ROMBA MUKKIYAM (Vercel Backend-ku)

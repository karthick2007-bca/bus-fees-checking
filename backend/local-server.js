const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');

const app = express();
app.use(cors());
app.use(express.json());

// Simple localhost MongoDB connection
mongoose.connect('mongodb://localhost:27017/transitpay', {
  useNewUrlParser: true,
  useUnifiedTopology: true,
})
.then(() => console.log('✅ Connected to localhost MongoDB'))
.catch(err => console.log('❌ MongoDB connection error:', err));

// Simple test route
app.get('/api/test', (req, res) => {
  res.json({ message: 'Server is working!', database: 'localhost' });
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
  dob: Date,
  location: String,
  amountPaid: Number,
  totalDue: Number,
  status: String,
  lastUpdated: Date,
  payments: Array,
});

const Student = mongoose.model('Student', studentSchema);

// Basic routes
app.get('/api/students', async (req, res) => {
  try {
    const students = await Student.find();
    res.json(students);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.post('/api/students', async (req, res) => {
  try {
    const student = new Student(req.body);
    await student.save();
    res.json(student);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

const PORT = 5000;
app.listen(PORT, () => {
  console.log(`🚀 Server running on http://localhost:${PORT}`);
});
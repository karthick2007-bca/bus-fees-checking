const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');

const app = express();
app.use(cors());
app.use(express.json());

// MongoDB Connection
const MONGODB_URI = process.env.MONGODB_URI || 'mongodb+srv://karthi2142007:Karthick2024@cluster0.nfyak0h.mongodb.net/karthick?retryWrites=true&w=majority';
mongoose.connect(MONGODB_URI, {
  useNewUrlParser: true,
  useUnifiedTopology: true,
})
.then(() => console.log('MongoDB Connected'))
.catch(err => console.log(err));

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

const Transaction = mongoose.model('Transaction', transactionSchema);

// Routes
app.get('/api/students', async (req, res) => {
  const students = await Student.find();
  res.json(students);
});

app.post('/api/students', async (req, res) => {
  // Check if student exists by phone and dob
  const existing = await Student.findOne({ phone: req.body.phone, dob: req.body.dob });
  
  if (existing) {
    // Update existing student
    Object.assign(existing, req.body);
    await existing.save();
    res.status(200).json(existing);
  } else {
    // Create new student
    const student = new Student(req.body);
    await student.save();
    res.status(201).json(student);
  }
});

app.get('/api/locations', async (req, res) => {
  const locations = await Location.find();
  res.json(locations);
});

app.post('/api/locations', async (req, res) => {
  // Check if location exists by id
  const existing = await Location.findOne({ id: req.body.id });
  
  if (existing) {
    // Update existing location
    existing.name = req.body.name;
    existing.fee = req.body.fee;
    await existing.save();
    res.status(200).json(existing);
  } else {
    // Create new location
    const location = new Location(req.body);
    await location.save();
    res.status(201).json(location);
  }
});

app.delete('/api/locations/:id', async (req, res) => {
  const location = await Location.findOne({ id: req.params.id });
  if (location) {
    await RecycleBin.create({ type: 'location', data: location.toObject() });
    await Location.findOneAndDelete({ id: req.params.id });
  }
  res.status(204).send();
});

app.get('/api/recyclebin', async (req, res) => {
  const items = await RecycleBin.find().sort({ deletedAt: -1 });
  res.json(items);
});

app.post('/api/recyclebin/restore/:id', async (req, res) => {
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
});

app.delete('/api/recyclebin/:id', async (req, res) => {
  await RecycleBin.findByIdAndDelete(req.params.id);
  res.status(204).send();
});

app.put('/api/students/:phone', async (req, res) => {
  const student = await Student.findOneAndUpdate(
    { phone: req.params.phone },
    req.body,
    { new: true }
  );
  res.json(student);
});

app.delete('/api/locations', async (req, res) => {
  await Location.deleteMany({});
  res.status(204).send();
});

// Generate and save report
app.post('/api/reports', async (req, res) => {
  const report = new Report(req.body);
  await report.save();
  
  // Update student reportGenerated timestamp
  await Student.findOneAndUpdate(
    { phone: req.body.phone },
    { reportGenerated: new Date() }
  );
  
  res.status(201).json(report);
});

// Get all reports
app.get('/api/reports', async (req, res) => {
  const reports = await Report.find();
  res.json(reports);
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, '0.0.0.0', () => console.log(`Server running on port ${PORT}`));

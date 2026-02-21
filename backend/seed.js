const mongoose = require('mongoose');

mongoose.connect('mongodb://localhost:27017/karthick')
.then(() => console.log('Connected to MongoDB'))
.catch(err => console.log(err));

const studentSchema = new mongoose.Schema({
  id: String,
  name: String,
  rollNo: String,
  address: String,
  email: String,
  phone: String,
  parentName: String,
  studentClass: String,
  dob: String,
  location: String,
  amountPaid: Number,
  totalDue: Number,
  status: String,
  lastUpdated: Date,
  payments: Array,
  locationHistory: Array,
});

const Student = mongoose.model('Student', studentSchema);

const seedStudents = async () => {
  await Student.deleteMany({});
  console.log('✅ All students deleted from database');
  process.exit(0);
};

seedStudents();

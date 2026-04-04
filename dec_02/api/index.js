const express = require('express');
const { MongoClient, ObjectId } = require('mongodb');
const cors = require('cors');

const app = express();
app.use(cors());
app.use(express.json());

const uri = process.env.MONGODB_URI;
let cachedClient = null;
let cachedDb = null;

async function connectToDatabase() {
  if (cachedDb) return cachedDb;
  if (!uri) throw new Error('MONGODB_URI environment variable is not set');
  cachedClient = await MongoClient.connect(uri, { serverSelectionTimeoutMS: 5000 });
  cachedDb = cachedClient.db('karthick');
  return cachedDb;
}

// Students
app.get('/api/students', async (req, res) => {
  try {
    const db = await connectToDatabase();
    res.json(await db.collection('students').find({}).toArray());
  } catch (err) { res.status(500).json({ error: err.message }); }
});

app.post('/api/students', async (req, res) => {
  try {
    const db = await connectToDatabase();
    res.json(await db.collection('students').insertOne(req.body));
  } catch (err) { res.status(500).json({ error: err.message }); }
});

app.put('/api/students/:phone', async (req, res) => {
  try {
    const db = await connectToDatabase();
    await db.collection('students').updateOne({ phone: req.params.phone }, { $set: req.body });
    res.json({ success: true });
  } catch (err) { res.status(500).json({ error: err.message }); }
});

app.delete('/api/students/:id', async (req, res) => {
  try {
    const db = await connectToDatabase();
    // Try finding by MongoDB _id first, then by custom id field
    let student = null;
    try {
      student = await db.collection('students').findOne({ _id: new ObjectId(req.params.id) });
    } catch (_) {}
    if (!student) {
      student = await db.collection('students').findOne({ id: req.params.id });
    }
    if (student) {
      await db.collection('recyclebin').insertOne({ ...student, type: 'student', deletedAt: new Date().toISOString() });
      await db.collection('students').deleteOne({ _id: student._id });
    }
    res.json({ success: true });
  } catch (err) { res.status(500).json({ error: err.message }); }
});

app.delete('/api/students', async (req, res) => {
  try {
    const db = await connectToDatabase();
    const students = await db.collection('students').find({}).toArray();
    if (students.length > 0) {
      await db.collection('recyclebin').insertMany(students.map(s => ({ ...s, type: 'student', deletedAt: new Date().toISOString() })));
      await db.collection('students').deleteMany({});
    }
    res.json({ success: true });
  } catch (err) { res.status(500).json({ error: err.message }); }
});

// Locations
app.get('/api/locations', async (req, res) => {
  try {
    const db = await connectToDatabase();
    res.json(await db.collection('locations').find({}).toArray());
  } catch (err) { res.status(500).json({ error: err.message }); }
});

app.post('/api/locations', async (req, res) => {
  try {
    const db = await connectToDatabase();
    res.json(await db.collection('locations').insertOne(req.body));
  } catch (err) { res.status(500).json({ error: err.message }); }
});

app.delete('/api/locations/:id', async (req, res) => {
  try {
    const db = await connectToDatabase();
    // Try finding by MongoDB _id first, then by custom id field
    let location = null;
    try {
      location = await db.collection('locations').findOne({ _id: new ObjectId(req.params.id) });
    } catch (_) {}
    if (!location) {
      location = await db.collection('locations').findOne({ id: req.params.id });
    }
    if (location) {
      await db.collection('recyclebin').insertOne({ ...location, type: 'location', deletedAt: new Date().toISOString() });
      await db.collection('locations').deleteOne({ _id: location._id });
    }
    res.json({ success: true });
  } catch (err) { res.status(500).json({ error: err.message }); }
});

// Reports
app.get('/api/reports', async (req, res) => {
  try {
    const db = await connectToDatabase();
    res.json(await db.collection('reports').find({}).toArray());
  } catch (err) { res.status(500).json({ error: err.message }); }
});

app.post('/api/reports', async (req, res) => {
  try {
    const db = await connectToDatabase();
    res.json(await db.collection('reports').insertOne(req.body));
  } catch (err) { res.status(500).json({ error: err.message }); }
});

// Transactions
app.get('/api/transactions', async (req, res) => {
  try {
    const db = await connectToDatabase();
    res.json(await db.collection('transactions').find({}).toArray());
  } catch (err) { res.status(500).json({ error: err.message }); }
});

app.post('/api/transactions', async (req, res) => {
  try {
    const db = await connectToDatabase();
    res.json(await db.collection('transactions').insertOne(req.body));
  } catch (err) { res.status(500).json({ error: err.message }); }
});

// Recycle Bin
app.get('/api/recyclebin', async (req, res) => {
  try {
    const db = await connectToDatabase();
    res.json(await db.collection('recyclebin').find({}).toArray());
  } catch (err) { res.status(500).json({ error: err.message }); }
});

app.post('/api/recyclebin/restore/:id', async (req, res) => {
  try {
    const db = await connectToDatabase();
    const item = await db.collection('recyclebin').findOne({ _id: new ObjectId(req.params.id) });
    if (item) {
      const { type, deletedAt, ...data } = item;
      const collection = type === 'location' ? 'locations' : 'students';
      await db.collection(collection).insertOne(data);
      await db.collection('recyclebin').deleteOne({ _id: new ObjectId(req.params.id) });
    }
    res.json({ success: true });
  } catch (err) { res.status(500).json({ error: err.message }); }
});

app.delete('/api/recyclebin/:id', async (req, res) => {
  try {
    const db = await connectToDatabase();
    await db.collection('recyclebin').deleteOne({ _id: new ObjectId(req.params.id) });
    res.json({ success: true });
  } catch (err) { res.status(500).json({ error: err.message }); }
});

// Notifications
app.get('/api/notifications', async (req, res) => {
  try {
    const db = await connectToDatabase();
    res.json(await db.collection('notifications').find({}).toArray());
  } catch (err) { res.status(500).json({ error: err.message }); }
});

app.put('/api/notifications/:id', async (req, res) => {
  try {
    const db = await connectToDatabase();
    await db.collection('notifications').updateOne({ _id: new ObjectId(req.params.id) }, { $set: { read: true } });
    res.json({ success: true });
  } catch (err) { res.status(500).json({ error: err.message }); }
});

app.delete('/api/notifications/:id', async (req, res) => {
  try {
    const db = await connectToDatabase();
    await db.collection('notifications').deleteOne({ _id: new ObjectId(req.params.id) });
    res.json({ success: true });
  } catch (err) { res.status(500).json({ error: err.message }); }
});

module.exports = app;

const express = require('express');
const { MongoClient, ObjectId } = require('mongodb');
const cors = require('cors');

const app = express();
app.use(cors());
app.use(express.json());

const uri = 'mongodb://localhost:27017';
const dbName = 'bus_fees';
let db;

MongoClient.connect(uri).then(client => {
  db = client.db(dbName);
  console.log('Connected to MongoDB');
}).catch(err => console.error('MongoDB connection error:', err));

// Students endpoints
app.get('/students', async (req, res) => {
  try {
    const students = await db.collection('students').find({}).toArray();
    res.json(students);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.post('/students', async (req, res) => {
  try {
    const result = await db.collection('students').insertOne(req.body);
    res.json(result);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.delete('/students/:id', async (req, res) => {
  try {
    await db.collection('students').deleteOne({ _id: new ObjectId(req.params.id) });
    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Locations endpoints
app.get('/locations', async (req, res) => {
  try {
    const locations = await db.collection('locations').find({}).toArray();
    res.json(locations);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.post('/locations', async (req, res) => {
  try {
    const result = await db.collection('locations').insertOne(req.body);
    res.json(result);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.delete('/locations/:id', async (req, res) => {
  try {
    await db.collection('locations').deleteOne({ _id: new ObjectId(req.params.id) });
    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Reports endpoints
app.get('/reports', async (req, res) => {
  try {
    const reports = await db.collection('reports').find({}).toArray();
    res.json(reports);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.post('/reports', async (req, res) => {
  try {
    const result = await db.collection('reports').insertOne(req.body);
    res.json(result);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Transactions endpoints
app.get('/transactions', async (req, res) => {
  try {
    const transactions = await db.collection('transactions').find({}).toArray();
    res.json(transactions);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.post('/transactions', async (req, res) => {
  try {
    const result = await db.collection('transactions').insertOne(req.body);
    res.json(result);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

const PORT = process.env.PORT || 8080;
app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});
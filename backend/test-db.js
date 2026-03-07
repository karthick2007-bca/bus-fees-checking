const mongoose = require('mongoose');

const MONGODB_URI = 'mongodb://localhost:27017/transitpay';

console.log('Testing MongoDB connection...');

mongoose.connect(MONGODB_URI, {
  useNewUrlParser: true,
  useUnifiedTopology: true,
})
.then(() => {
  console.log('✅ MongoDB Connected Successfully!');
  process.exit(0);
})
.catch(err => {
  console.log('❌ MongoDB Connection Failed:', err.message);
  process.exit(1);
});
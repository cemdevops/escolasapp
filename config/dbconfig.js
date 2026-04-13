// Database configuration for MongoDB
// Connects to MongoDB service in docker-compose

module.exports = {
  // MongoDB connection URL with embedded credentials
  url: process.env.DB_URL || 'mongodb://admin:mongosecret@mongodb:27017/escolasapp',
  
  // MongoDB connection options (optimized for MongoDB 3.6 with Mongoose 5.13+)
  options: {
    authSource: 'admin',
    useNewUrlParser: true,
    useUnifiedTopology: true,
    // Connection pool settings
    maxPoolSize: 10,
    minPoolSize: 2,
    // Retry settings
    retryWrites: false, // MongoDB 3.6 doesn't support retryWrites well
    // Timeout settings
    serverSelectionTimeoutMS: 30000,
    socketTimeoutMS: 45000,
    // Prevent buffer overflow
    bufferMaxEntries: 0
  }
};

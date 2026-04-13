// Database configuration for MongoDB
// Connects to MongoDB service in docker-compose
// MongoDB 5.0+ optimized for modern Mongoose driver

module.exports = {
  // MongoDB connection URL with embedded credentials
  url: process.env.DB_URL || 'mongodb://admin:mongosecret@mongodb:27017/escolasapp',
  
  // MongoDB connection options (optimized for MongoDB5.0+)
  options: {
    authSource: 'admin',
    useNewUrlParser: true,
    useUnifiedTopology: true,
    // Connection pool settings (MongoDB 5.0 supports better pooling)
    maxPoolSize: 10,
    minPoolSize: 2,
    // Retry settings (retryWrites works better in MongoDB 5.0+)
    retryWrites: true,
    // Timeout settings
    serverSelectionTimeoutMS: 30000,
    socketTimeoutMS: 45000,
    // Prevent buffer overflow
    bufferMaxEntries: 0,
    // MongoDBname
    dbName: process.env.DB_NAME || 'escolasapp'
  }
};

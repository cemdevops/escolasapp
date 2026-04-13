// Database configuration for MongoDB
// Connects to MongoDB service in docker-compose

module.exports = {
  // MongoDB connection URL - use environment variable if provided
  url: process.env.DB_URL || 'mongodb://admin:mongosecret@mongodb:27017/escolasapp',
  
  // MongoDB connection options
  options: {
    authSource: 'admin',
    useNewUrlParser: true,
    useUnifiedTopology: true,
    useMongoClient: true,
    reconnectTries: 30,
    reconnectInterval: 500,
    bufferMaxEntries: 0,
    connectTimeoutMS: 30000,
    socketTimeoutMS: 30000
  }
};

// Database configuration for MongoDB
// Connects to MongoDB service in docker-compose

module.exports = {
  // MongoDB connection URL
  // In Docker: service name is 'mongodb'
  // In production: use environment variable
  url: process.env.DB_HOST || 'mongodb://mongodb:27017/escolasapp',
  
  // MongoDB connection options
  options: {
    useNewUrlParser: true,
    useUnifiedTopology: true,
    autoIndex: true,
    retryWrites: true,
    w: 'majority'
  }
};

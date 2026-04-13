// Database configuration for MongoDB
// Connects to MongoDB service in docker-compose
// MongoDB 5.0+ optimized for modern Mongoose driver

const isProduction = process.env.NODE_ENV === 'production';
const isDevelopment = process.env.NODE_ENV === 'development';

// Log configuration details in development
if (isDevelopment) {
  const url = process.env.DB_URL || 'mongodb://admin:mongosecret@mongodb:27017/escolasapp';
  console.log('[DB-CONFIG] MongoDB URL:', url.replace(/:[^@]*@/, ':***@'));
}

module.exports = {
  // MongoDB connection URL with embedded credentials
  url: process.env.DB_URL || 'mongodb://admin:mongosecret@mongodb:27017/escolasapp',
  
  // MongoDB connection options (optimized for MongoDB 5.0+)
  options: {
    authSource: 'admin',
    useNewUrlParser: true,
    useUnifiedTopology: true,
    
    // Connection pool settings (MongoDB 5.0 supports better pooling)
    maxPoolSize: 10,
    minPoolSize: 2,
    
    // Retry settings (retryWrites works better in MongoDB 5.0+)
    retryWrites: true,
    
    // Increased timeouts (Phase 5 optimization)
    // Docker startup can be slow, so we need generous timeouts
    serverSelectionTimeoutMS: 60000,    // 60s (was 30s) - for server discovery
    socketTimeoutMS: 90000,             // 90s (was 45s) - for operations
    connectTimeoutMS: 60000,            // 60s - for initial connection
    
    // Connection heartbeat (keep-alive)
    heartbeatFrequencyMS: 10000,        // Check server every 10s
    
    // Prevent buffer overflow
    bufferMaxEntries: 0,
    
    // MongoDB name
    dbName: process.env.DB_NAME || 'escolasapp',
    
    // Additional logging for debugging in development
    ...(isDevelopment && {
      loggerLevel: 'debug'  // Enable verbose logging
    })
  }
};

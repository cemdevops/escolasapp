#!/usr/bin/env node
/**
 * MongoDB Connection Diagnostic Tool
 * Tests connection parameters and provides detailed debug output
 */

const mongoose = require('mongoose');

// Get config
const db = require('./config/dbconfig.js');

console.log('════════════════════════════════════════════════');
console.log('MongoDB Connection Diagnostic');
console.log('════════════════════════════════════════════════');
console.log('');

// Print environment
console.log('📋 Environment:');
console.log(`  NODE_ENV: ${process.env.NODE_ENV}`);
console.log(`  DB_HOST: ${process.env.DB_HOST || 'mongodb'}`);
console.log(`  DB_PORT: ${process.env.DB_PORT || '27017'}`);
console.log(`  DB_NAME: ${process.env.DB_NAME || 'escolasapp'}`);
console.log(`  DB_USER: ${process.env.DB_USER || 'admin'}`);
console.log('');

// Print connection params
console.log('🔗 Connection Parameters:');
console.log(`  URL: ${db.url}`);
console.log('  Options:');
Object.entries(db.options).forEach(([key, val]) => {
  console.log(`    ${key}: ${val}`);
});
console.log('');

// Test connection
console.log('🔄 Testing connection...');
console.log('');

// Add event listeners
mongoose.connection.on('connecting', () => {
  console.log('  → Connecting...');
});

mongoose.connection.on('connected', () => {
  console.log('  ✓ Connected!');
  console.log(`  Host: ${mongoose.connection.host}`);
  console.log(`  Port: ${mongoose.connection.port}`);
  console.log(`  Database: ${mongoose.connection.db.name}`);
});

mongoose.connection.on('error', (err) => {
  console.error('  ✗ Error:', err.message);
  console.error('  Code:', err.code);
  if (err.reason) {
    console.error('  Reason:', err.reason);
  }
});

mongoose.connection.on('disconnected', () => {
  console.log('  ⚠ Disconnected');
});

// Attempt connection with timeout
const timeoutMs = 15000;
console.log(`⏱ Timeout: ${timeoutMs}ms`);
console.log('');

const connectPromise = mongoose.connect(db.url, {
  ...db.options,
  serverSelectionTimeoutMS: timeoutMs,
  socketTimeoutMS: timeoutMs
});

connectPromise
  .then(() => {
    console.log('');
    console.log('✅ SUCCESS - Connection established!');
    console.log('');
    
    // Test a simple query
    const schemas = mongoose.modelNames();
    console.log(`  Collections available: ${schemas.length}`);
    schemas.forEach(s => console.log(`    - ${s}`));
    
    process.exit(0);
  })
  .catch((err) => {
    console.log('');
    console.error('❌ FAILED - Connection failed');
    console.error('');
    console.error('Error Details:');
    console.error('  Message:', err.message);
    console.error('  Code:', err.code);
    console.error('  Name:', err.name);
    if (err.reason) {
      console.error('  Reason:', err.reason.error?.message);
    }
    console.error('');
    console.error('Possible causes:');
    console.error('  1. MongoDB server not running');
    console.error('  2. Wrong hostname/host mapping (try: nslookup mongodb)');
    console.error('  3. Wrong credentials (admin:mongosecret)');
    console.error('  4. Timeout too short for network latency');
    console.error('  5. Firewall blocking connection');
    console.error('');
    
    process.exit(1);
  });

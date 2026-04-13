# Multi-stage build for EscolasApp
# Express.js server with Angular application (no build compilation in Docker)

# ============================================================================
# Stage 1: Builder - Install dependencies
# ============================================================================
FROM node:12-alpine AS builder

LABEL stage=builder

WORKDIR /app

# Install build dependencies for native modules compilation
RUN apk add --no-cache python3 make g++ gcc

# Copy package files
COPY package*.json ./

# Install all dependencies (needed for Angular CLI and runtime)
# Skip install scripts to avoid inotify@1.4.6 compilation errors
RUN if [ -f package-lock.json ]; then npm ci --ignore-scripts; else npm install --legacy-peer-deps --ignore-scripts; fi

# ============================================================================
# Stage 2: Runtime - Express Server
# ============================================================================
FROM node:12-alpine

WORKDIR /app

# Set environment variables
ENV NODE_ENV=production
ENV PORT=3002
ENV LOG_LEVEL=info

# Install runtime build dependencies (needed for node-gyp at runtime)
RUN apk add --no-cache python3 make g++

# Create non-root user for security
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001

# Copy package files
COPY package*.json ./

# Install production dependencies (skip scripts to avoid compilation errors)
RUN if [ -f package-lock.json ]; then npm ci --only=production --ignore-scripts; else npm install --legacy-peer-deps --ignore-scripts; fi && \
    npm cache clean --force

# Copy application code from source
COPY --chown=nodejs:nodejs . .

# Copy node_modules from builder (optimization for production deps)
COPY --from=builder --chown=nodejs:nodejs /app/node_modules ./node_modules

# Create directory for Angular dist (if pre-built)
RUN mkdir -p ./dist ./public

# Switch to non-root user
USER nodejs

# Expose application port
EXPOSE 3002

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
    CMD node -e "require('http').get('http://localhost:3002/', (r) => {if (r.statusCode !== 200) throw new Error(r.statusCode)})"

# Start application
CMD ["node", "./bin/www"]

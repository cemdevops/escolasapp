# Multi-stage build for EscolasApp
# Stage 1: Build Angular SPA
# Stage 2: Runtime container with Node.js

# ============================================================================
# Stage 1: Build Angular SPA
# ============================================================================
FROM node:12-alpine AS builder

LABEL stage=builder

WORKDIR /app

# Install build dependencies needed for native modules (like inotify)
# Alpine: apk adds Python, make, g++, etc.
RUN apk add --no-cache python make g++ gcc

# Copy package.json and package-lock.json
COPY package*.json ./

# Install dependencies (all, needed for Angular CLI build)
# Use npm install as fallback if package-lock.json doesn't exist
# inotify and other native modules can now compile successfully
RUN if [ -f package-lock.json ]; then npm ci; else npm install --legacy-peer-deps; fi

# Copy source code
COPY . .

# Build Angular SPA for production
RUN npm run build

# ============================================================================
# Stage 2: Runtime - Express Server with Angular Static Files
# ============================================================================
FROM node:12-alpine

WORKDIR /app

# Set environment variables
ENV NODE_ENV production
ENV PORT 3002

# Install runtime dependencies for native modules
RUN apk add --no-cache python make g++

# Create app user for security (non-root)
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001

# Copy package.json and package-lock.json from builder
COPY package*.json ./

# Install production dependencies only
# Use npm install as fallback if package-lock.json doesn't exist
# inotify and other native modules can now compile successfully
RUN if [ -f package-lock.json ]; then npm ci --only=production; else npm install --legacy-peer-deps; fi && \
    npm cache clean --force

# Copy application code from source
COPY --chown=nodejs:nodejs . .

# Copy pre-built Angular dist folder from builder stage
COPY --from=builder --chown=nodejs:nodejs /app/dist ./dist

# Switch to non-root user
USER nodejs

# Expose application port
EXPOSE 3002

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
    CMD node -e "require('http').get('http://localhost:3002', (r) => { if (r.statusCode !== 200) throw new Error(r.statusCode)})"

# Start application
CMD ["npm", "start"]

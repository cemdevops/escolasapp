# Multi-stage build for EscolasApp
# Stage 1: Build Angular SPA
# Stage 2: Runtime container with Node.js

# ============================================================================
# Stage 1: Build Angular SPA
# ============================================================================
FROM node:12-alpine AS builder

LABEL stage=builder

WORKDIR /app

# Copy package.json and package-lock.json
COPY package*.json ./

# Install dependencies (all, needed for Angular CLI build)
RUN npm ci

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

# Create app user for security (non-root)
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001

# Copy package.json and package-lock.json from builder
COPY package*.json ./

# Install production dependencies only
RUN npm ci --only=production && \
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

# Multi-stage build for EscolasApp
# Stage 1: Dependencies (for backend only)
# Stage 2: Runtime - Express Server with simple SPA

# ============================================================================
# Stage 1: Dependencies Builder
# ============================================================================
FROM node:12-alpine AS deps-builder

LABEL stage=deps-builder

WORKDIR /app

# Install build dependencies for native modules
RUN apk add --no-cache python3 make g++ gcc

# Copy package files
COPY package*.json ./

# Install all dependencies
RUN if [ -f package-lock.json ]; then npm ci --legacy-peer-deps --ignore-scripts; else npm install --legacy-peer-deps --ignore-scripts; fi

# ============================================================================
# Stage 2: Runtime - Express Server with Static SPA
# ============================================================================
FROM node:12-alpine

WORKDIR /app

# Set environment variables
ENV NODE_ENV=production
ENV PORT=3002
ENV LOG_LEVEL=info

# Install runtime dependencies
RUN apk add --no-cache python3 make g++

# Create non-root user for security
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001

# Copy package files
COPY package*.json ./

# Copy prebuilt node_modules from deps-builder stage
COPY --from=deps-builder --chown=nodejs:nodejs /app/node_modules ./node_modules

# Copy application code
COPY --chown=nodejs:nodejs . .

# Ensure dist directory exists with SPA files
RUN mkdir -p ./dist && \
    if [ -f ./dist/index.html ]; then echo "✓ SPA found"; else echo "<!-- Empty SPA placeholder -->" > ./dist/index.html; fi && \
    ls -la ./dist/

# Clean up unnecessary files  
RUN npm cache clean --force && \
    rm -rf .git .github docs e2e src/app/layout src/app/shared karma.conf.js protractor.conf.js tsconfig.json tsconfig.*.json tslint.json .angular-cli.json 2>/dev/null || true

# Switch to non-root user
USER nodejs

# Expose application port
EXPOSE 3002

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
    CMD node -e "require('http').get('http://localhost:3002/', (r) => {if (r.statusCode !== 200) throw new Error(r.statusCode)})"

# Start application
CMD ["node", "./bin/www"]

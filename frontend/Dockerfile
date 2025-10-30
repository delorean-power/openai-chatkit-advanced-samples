# Multi-stage build for optimized frontend deployment
FROM node:20-slim AS builder

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm ci --only=production && npm cache clean --force

# Copy source code
COPY . .

# Build the application
ARG VITE_CHATKIT_API_URL
ARG VITE_CHATKIT_API_DOMAIN_KEY
ARG VITE_FACTS_API_URL

ENV VITE_CHATKIT_API_URL=${VITE_CHATKIT_API_URL}
ENV VITE_CHATKIT_API_DOMAIN_KEY=${VITE_CHATKIT_API_DOMAIN_KEY}
ENV VITE_FACTS_API_URL=${VITE_FACTS_API_URL}

RUN npm run build

# Production stage with nginx
FROM nginx:alpine

# Copy custom nginx config
COPY nginx.conf /etc/nginx/nginx.conf

# Copy built assets from builder
COPY --from=builder /app/dist /usr/share/nginx/html

# Add healthcheck
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:8080/health || exit 1

# Expose port
EXPOSE 8080

# Start nginx
CMD ["nginx", "-g", "daemon off;"]

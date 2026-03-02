# =============================================================================
# FRONTEND DOCKERFILE TEMPLATE
# Stack: React + Vite + Tailwind → served by Nginx
# Works for both user-facing and admin frontends — same pattern for both.
# =============================================================================
# HOW TO USE:
#   1. Copy this file into your frontend/ folder and rename it to "Dockerfile"
#   2. Copy nginx.conf (from this templates folder) into the same folder
#   3. Replace every value marked with <ANGLE_BRACKETS> with your own value
#   4. Delete all comments once you understand what each line does
# =============================================================================


# =============================================================================
# STAGE 1 — BUILD
# =============================================================================
# This stage uses Node.js to install deps and build the React app into
# static files (HTML + CSS + JS bundles) inside a dist/ folder.
# After this stage, Node.js is no longer needed.
# =============================================================================

# Same Node version rule as the backend — match your project's Node version.
FROM node:<NODE_VERSION>-alpine AS builder

WORKDIR /app

# -----------------------------------------------------------------------------
# Build-time environment variable for the API URL
# -----------------------------------------------------------------------------
# ARG  → declares a variable that can be passed in from docker-compose.yml
#         using the "args:" key under "build:". Only available during build.
# ENV  → turns the ARG into an environment variable so Vite can read it.
#
# WHY CAN'T WE JUST SET THIS AT RUNTIME?
# Vite bakes env variables into the JS bundle at BUILD time. The final JS
# files are plain static text — there is no runtime to inject variables into.
# Any variable with the VITE_ prefix gets embedded into the bundle during
# "npm run build". If you don't pass it at build time, it will be undefined.
#
# Add more ARG/ENV pairs here for every VITE_ variable your app uses.
# -----------------------------------------------------------------------------
ARG VITE_API_URL
ENV VITE_API_URL=$VITE_API_URL
# Add more if needed:
# ARG VITE_SOME_OTHER_VAR
# ENV VITE_SOME_OTHER_VAR=$VITE_SOME_OTHER_VAR

# Copy package files first for layer caching (same reason as backend).
COPY package*.json ./
RUN npm install

# Copy the rest of the source code and build.
COPY . .

# "npm run build" runs Vite which compiles everything into dist/
# The dist/ folder will contain: index.html, assets/*.js, assets/*.css
RUN npm run build


# =============================================================================
# STAGE 2 — SERVE
# =============================================================================
# Fresh image — no Node.js, no source code, no node_modules.
# Only Nginx + the built dist/ files are included.
# Final image size: ~25MB (vs ~400MB if we kept Node around).
# =============================================================================

# nginx:alpine is the standard production image for serving static files.
FROM nginx:alpine

# Copy the built static files from Stage 1 into Nginx's web root.
# /usr/share/nginx/html is where Nginx looks for files to serve by default.
# This path matches the "root" directive in nginx.conf.
COPY --from=builder /app/dist /usr/share/nginx/html

# Replace Nginx's default config with our custom one.
# /etc/nginx/conf.d/default.conf is the file Nginx loads for its default site.
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Document that Nginx listens on port 80 (standard HTTP port).
# Actual host-to-container port mapping is done in docker-compose.yml.
EXPOSE 80

# Start Nginx in the foreground.
# "daemon off" keeps the process running so Docker doesn't think it crashed.
# Without this flag, Nginx daemonizes (backgrounds itself) and exits,
# which Docker interprets as the container having stopped.
CMD ["nginx", "-g", "daemon off;"]

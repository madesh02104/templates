# =============================================================================
# BACKEND DOCKERFILE TEMPLATE
# Stack: Node.js + Express + Prisma + PostgreSQL
# =============================================================================
# HOW TO USE:
#   1. Copy this file into your backend/ folder and rename it to "Dockerfile"
#   2. Replace every value marked with <ANGLE_BRACKETS> with your own value
#   3. Delete all comments once you understand what each line does
# =============================================================================


# -----------------------------------------------------------------------------
# Base image
# -----------------------------------------------------------------------------
# node:<VERSION>-alpine
#   VERSION → match whatever is in your .nvmrc or package.json engines field
#   Common choices: 18, 20, 22
#   -alpine → keeps the image small (~120MB vs ~900MB for the default image)
# -----------------------------------------------------------------------------
FROM node:<NODE_VERSION>-alpine

# -----------------------------------------------------------------------------
# Working directory inside the container
# -----------------------------------------------------------------------------
# All subsequent COPY / RUN / CMD instructions run from this path.
# Convention is /app — don't change this unless you have a reason to.
# -----------------------------------------------------------------------------
WORKDIR /app

# -----------------------------------------------------------------------------
# Copy dependency manifests FIRST (before the rest of your source code)
# -----------------------------------------------------------------------------
# Why first? Docker caches each layer. If you copy everything at once,
# npm install reruns on every single code change. Copying package files
# separately means the npm install layer is only invalidated when
# package.json or package-lock.json actually changes → much faster rebuilds.
# -----------------------------------------------------------------------------
COPY package*.json ./

# -----------------------------------------------------------------------------
# Copy Prisma schema before running npm install
# -----------------------------------------------------------------------------
# The "prisma generate" step below needs schema.prisma to exist.
# Remove this block entirely if you are NOT using Prisma.
# -----------------------------------------------------------------------------
COPY prisma ./prisma/

# -----------------------------------------------------------------------------
# Install production dependencies
# -----------------------------------------------------------------------------
# If you want to install only production deps (no devDependencies), use:
#   RUN npm ci --omit=dev
# For development images where you need nodemon etc., use:
#   RUN npm install
# -----------------------------------------------------------------------------
RUN npm install

# -----------------------------------------------------------------------------
# Generate Prisma Client
# -----------------------------------------------------------------------------
# Prisma generates a custom JS/TS client from your schema at build time.
# This must run AFTER npm install and AFTER the prisma/ folder is copied.
# Remove this line if you are NOT using Prisma.
# -----------------------------------------------------------------------------
RUN npx prisma generate

# -----------------------------------------------------------------------------
# Copy the rest of your source code
# -----------------------------------------------------------------------------
# Comes AFTER npm install intentionally — see caching explanation above.
# The "." on the left is relative to your build context (the backend/ folder).
# The "." on the right is relative to WORKDIR (/app).
# -----------------------------------------------------------------------------
COPY . .

# -----------------------------------------------------------------------------
# Document the port your app listens on
# -----------------------------------------------------------------------------
# EXPOSE does NOT publish the port — it's just metadata / documentation.
# The actual port mapping is done in docker-compose.yml under "ports:".
# Change this to whatever PORT your Express app listens on.
# -----------------------------------------------------------------------------
EXPOSE <APP_PORT>
# e.g. EXPOSE 3000

# -----------------------------------------------------------------------------
# Startup command
# -----------------------------------------------------------------------------
# We use "sh -c" because we need to chain commands with &&.
# The two commands are:
#   1. npx prisma db push  → applies your schema to the database at runtime
#                            (can't do this at build time — the DB doesn't
#                            exist yet during the build step)
#   2. npm start           → runs the "start" script in your package.json
#
# If you are NOT using Prisma, simplify to:
#   CMD ["node", "src/<YOUR_ENTRY_FILE>.js"]
# Or if you have a start script:
#   CMD ["npm", "start"]
# -----------------------------------------------------------------------------
CMD ["sh", "-c", "npx prisma db push && npm start"]
# Without Prisma → CMD ["node", "src/<YOUR_ENTRY_FILE>.js"]

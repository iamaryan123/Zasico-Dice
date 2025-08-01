# Single stage for production
FROM node:18-alpine

WORKDIR /app

# Install dependencies first for better caching
COPY package*.json ./
RUN npm install --production

# Copy app source
COPY . .

# Use environment variables
ARG DB_URI
ARG JWT_SECRET
ENV DB_URI=$DB_URI
ENV JWT_SECRET=$JWT_SECRET

EXPOSE 3000

CMD ["npm", "start"]
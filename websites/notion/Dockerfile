FROM node:20-alpine
WORKDIR /app

COPY package*.json ./
COPY prisma ./prisma
RUN npm ci

COPY . .
RUN npm run prisma:generate
ENV NEXT_TELEMETRY_DISABLED=1
RUN npm run build

EXPOSE 3000
CMD ["npm", "run", "start"]

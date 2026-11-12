FROM node:20-alpine
WORKDIR /app

# npm 为最通用的安装方式（无需 corepack / pnpm 全局安装）
COPY package.json build.js tsconfig.json ./
COPY src ./src

RUN npm install --no-audit --no-fund && npm run build

ENV NODE_ENV=production
ENV PORT=8080
EXPOSE 8080

CMD ["node", "dist/index.js"]

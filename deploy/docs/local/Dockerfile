FROM node:20-alpine

RUN apk add --no-cache make

WORKDIR /docs

COPY package*.json ./
RUN npm install

EXPOSE 8000

CMD ["npx", "serve", "-p", "8000", "."]
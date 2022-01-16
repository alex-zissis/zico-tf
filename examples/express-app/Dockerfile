ARG NODE_VERSION=16.13.2

FROM node:${NODE_VERSION}-alpine
WORKDIR /app
COPY src src
COPY package.json .
COPY yarn.lock .
RUN yarn install
EXPOSE 3000
ENTRYPOINT ["yarn", "-s", "start:prod"]
ARG NODE_VERSION=16.13.2

FROM node:${NODE_VERSION}-alpine
ARG COMMIT_SHA
ENV COMMIT_SHA ${COMMIT_SHA}
WORKDIR /app
COPY src src
COPY package.json .
COPY yarn.lock .
RUN yarn install
EXPOSE 3000
ENTRYPOINT ["yarn", "-s", "start:prod"]
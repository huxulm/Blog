FROM node:10

WORKDIR /app
COPY . .

RUN npm i -g yarn hexo-cli && \
    npm i

EXPOSE 4000
CMD ["hexo", "server"]
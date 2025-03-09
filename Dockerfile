# 1. Сборка фронтенда (если нужен веб-интерфейс)
FROM node:20.9.0-alpine AS client_builder
WORKDIR /app
COPY ./web/client .
RUN yarn install --immutable
RUN yarn build
RUN yarn cache clean

# 2. Сборка PhoneInfoga (Go)
FROM golang:1.20.6-alpine AS go_builder
WORKDIR /app
RUN apk add --update --no-cache git make bash build-base
COPY . .
COPY --from=client_builder /app/dist ./web/client/dist
RUN go get -v -t -d ./...
RUN make install-tools
RUN make build

# 3. Финальный образ (Запуск API)
FROM alpine:3.18
COPY --from=go_builder /app/bin/phoneinfoga /app/phoneinfoga

# Исправляем порт (меняем с 5000 на 8080)
EXPOSE 8080

# Запускаем API-сервер
CMD ["/app/phoneinfoga", "serve"]

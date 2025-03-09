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
RUN go mod tidy
RUN go get -v -t -d ./...
RUN make install-tools
RUN make build

# 3. Финальный образ (Alpine)
FROM alpine:3.18
WORKDIR /root/

# 4. Добавляем необходимые зависимости
RUN apk add --no-cache bash ca-certificates

# 5. Копируем скомпилированный Go-бинарник
COPY --from=go_builder /app/bin/phoneinfoga /usr/local/bin/phoneinfoga
RUN chmod +x /usr/local/bin/phoneinfoga

# 6. Открываем порт 8080
EXPOSE 8080

# 7. Запускаем API
# CMD ["/usr/local/bin/phoneinfoga", "serve"]
# CMD ["/usr/local/bin/phoneinfoga", "serve", "--port", "8080"]
CMD ["/usr/local/bin/phoneinfoga", "serve", "--port", "8080", "--debug"]

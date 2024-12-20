FROM golang:1.23 AS builder

WORKDIR /app

COPY go.mod go.sum ./
RUN go mod download

COPY . .

RUN CGO_ENABLED=0 GOOS=linux go build -o task-tracker ./cmd/web

# Second stage: Create a smaller image to run the app
FROM alpine:latest

WORKDIR /app

COPY --from=builder /app/task-tracker .

COPY --from=builder /app/migrations ./migrations

COPY --from=builder /app/ui ./ui

EXPOSE 4000

CMD ["./task-tracker"]
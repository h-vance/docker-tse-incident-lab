FROM python:3.12-alpine@sha256:6d43704baacd1bfbe7c295d7f13079d5d8104ed33568873133f8fc69980419df

RUN apk add --no-cache postgresql16-client=16.14-r0 \
    && addgroup -S app \
    && adduser -S -G app app

WORKDIR /app
COPY app.py /app/app.py

EXPOSE 8080
USER app
CMD ["python", "/app/app.py"]

## Rocky Monitor

Real-time cat detection and monitoring system for Rocky, the neighborhood cat who visits our balcony.

## Architecture
```
Camera (C200) → Python Detector → Elixir Microservice → Next.js
                (YOLO + Motion)   (Sessions + Analytics)  (Webhooks)
```

## Features

- Motion-triggered YOLO detection
- Active hours scheduling (0700 - 23:00)
- Visit session tracking
- Analytics (duration, frequency, location preference)
- Webhook notifications to Next.js

## Stack

- **Detection:** Python 3.11 + YOLOv8 + OpenCV
- **Backend:** Elixir 1.15 + Phoenix + Ecto
- **Database:** SQLite
- **Deployment:** Docker + Alpine Linux on Raspberry Pi 4

## License

Private project - Not licensed for public use

## About Rocky

Rocky is a neighborhood cat who regularly visits our balcony. He either waits patiently at the glass door or relaxes on the balcony sofa. This system helps us know when he's around so we can say hello! 🐱

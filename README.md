## ANDRHELPER — Android helper во время интервью

Мобильное Flutter‑приложение + Node.js/TypeScript backend.
Приложение автоматически слушает микрофон, распознаёт речь (Google STT),
находит вопросы интервьюера и даёт краткие ответы (OpenAI gpt-4o-mini),
показывая их в Markdown (код, формулы, mermaid) и дублируя в Telegram.

### Структура

- `backend` — Node.js + TypeScript, WebSocket‑сервер, Google STT, OpenAI, Telegram.
- `client` — Flutter‑клиент (Android), авто‑стрим аудио, рендер ответов, настройки.

### .env (в корне проекта или скопировать в backend/.env)

```env
PORT=3100
OPENAI_API_KEY=sk-...
TELEGRAM_TOKEN=123456:ABC...
TELEGRAM_CHAT_ID=123456789
GCLOUD_PROJECT=gen-lang-client-0208700641
GOOGLE_APPLICATION_CREDENTIALS=/app/gcp-key.json   # при деплое, если нужно
```

В режиме без `OPENAI_API_KEY` backend стартует в "demo mode" — без QA.

### Запуск backend локально

```bash
cd backend
npm install
npm run dev
```

Сервер поднимется на `http://localhost:3100` (`/health` для проверки).

### Запуск backend в Docker

```bash
cd backend
docker build -t andrhelper-backend .

# если .env лежит в backend/.env
docker run --rm -p 3100:3100 --env-file .env andrhelper-backend

# пример для прод-сервера mail.s0me.uk:
# контейнер слушает 3100, nginx проксирует 443 -> 3100
docker run -d --name andrhelper-backend \ 
  --env-file .env -p 3100:3100 andrhelper-backend
```

В Dockerfile настроен `HEALTHCHECK` на `http://127.0.0.1:PORT/health`.

### Запуск Flutter‑клиента

```bash
cd client
flutter pub get
flutter run   # устройство или эмулятор Android
```

По умолчанию клиент подключается к `ws://10.0.2.2:3100`
(backend на localhost, Android‑эмулятор).

Для прод-сборки под `mail.s0me.uk` (nginx с прокси `443 -> 3100`) можно собрать:

```bash
flutter build apk --release \
  --dart-define=WS_URI=wss://mail.s0me.uk
```

и тогда клиент будет подключаться к `wss://mail.s0me.uk`.

### Основные фичи

- Автоматический старт микрофона при запуске приложения.
- Стрим аудио по WebSocket на backend, Google Speech‑to‑Text.
- Детекция вопросов (эвристики + LLM) и сверхкраткие ответы (gpt‑4o‑mini).
- Рендер markdown, кода, формул и mermaid‑диаграмм.
- Дублирование ответов в Telegram‑бот.
- Настройки: размер шрифта, 5 цветовых тем, авто‑скролл с регулируемой скоростью.
- Индикация подключения к backend и состояние микрофона (mute).



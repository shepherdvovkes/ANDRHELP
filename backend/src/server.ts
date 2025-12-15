import express from "express";
import http from "http";
import WebSocket, { WebSocketServer } from "ws";
import { config } from "./config";
import { IncomingMessage, OutgoingMessage } from "./types";
import { SpeechToTextService } from "./speechToTextService";
import { OpenAiClient } from "./openAiClient";
import { QuestionDetector } from "./questionDetector";
import { QuestionAnswerService } from "./questionAnswerService";
import { TelegramNotifier } from "./telegramNotifier";
import { logger } from "./logger";

interface SessionContext {
  stt: SpeechToTextService;
  sessionId?: string;
  audioChunks: number;
}

const app = express();
const server = http.createServer(app);
const wss = new WebSocketServer({ server });

const openAiClient = new OpenAiClient();
const detector = new QuestionDetector(openAiClient);
const qaService = new QuestionAnswerService(openAiClient, detector);
const telegramNotifier = new TelegramNotifier();

const sessions = new Map<WebSocket, SessionContext>();

function send(ws: WebSocket, message: OutgoingMessage) {
  if (ws.readyState === WebSocket.OPEN) {
    ws.send(JSON.stringify(message));
  }
}

wss.on("connection", (ws) => {
  const stt = new SpeechToTextService({
    languageCode: "ru-RU",
    alternativeLanguageCodes: ["en-US"],
  });

  sessions.set(ws, { stt, audioChunks: 0 });
  logger.info("server", "WebSocket connection established");

  // отправляем клиенту статус интеграции Telegram
  const statusMessage: OutgoingMessage = {
    type: "status",
    sessionId: "",
    status: telegramNotifier.isEnabled
      ? "telegram_enabled"
      : "telegram_disabled",
  };
  send(ws, statusMessage);

  // Listen for STT events and try to detect/answer questions
  stt.on("transcript", async (event) => {
    if (event.type !== "final") return;

    const session = sessions.get(ws);
    const sessionId = session?.sessionId ?? "";

    const contextText = stt.getBufferedText();
    try {
      const qaResult = await qaService.processTranscriptContext(contextText);
      if (!qaResult) return;

      const payload: OutgoingMessage = {
        type: "answer",
        sessionId,
        question: qaResult.question,
        answerMarkdown: qaResult.answerMarkdown,
        timestamp: Date.now(),
      };

      send(ws, payload);
      await telegramNotifier.sendQuestionAnswer(
        qaResult.question,
        qaResult.answerMarkdown
      );
    } catch (err) {
      logger.error("server", "QA processing error", err);
    }
  });

  ws.on("message", (data) => {
    try {
      const parsed: IncomingMessage = JSON.parse(
        data.toString()
      ) as IncomingMessage;

      if (parsed.type === "audio_chunk") {
        const session = sessions.get(ws);
        if (!session) {
          logger.warn("server", "Received audio_chunk but no session found");
          return;
        }

        // привязываем sessionId из первого сообщения к контексту сессии
        if (!session.sessionId) {
          session.sessionId = parsed.sessionId;
          logger.info("server", `Session ID set: ${parsed.sessionId}`);
        }

        const buffer = Buffer.from(parsed.data, "base64");
        // игнорируем слишком короткие чанки, чтобы не зашумлять STT
        if (buffer.length < 200) {
          logger.debug("server", `Ignoring too-small audio chunk (${buffer.length} bytes)`);
          return;
        }

        session.audioChunks += 1;
        if (session.audioChunks % 50 === 0 || session.audioChunks === 1) {
          logger.info(
            "server",
            `Received ${session.audioChunks} audio chunks for session ${session.sessionId} (chunk size: ${buffer.length} bytes)`
          );
        }

        session.stt.addAudioChunk(buffer);
      } else {
        logger.debug("server", `Received unknown message type: ${parsed.type}`);
      }
    } catch (err) {
      logger.error("server", "Failed to handle message", err);
    }
  });

  ws.on("close", () => {
    const session = sessions.get(ws);
    if (session) {
      session.stt.end();
      sessions.delete(ws);
    }
    logger.info("server", "WebSocket connection closed");
  });
});

app.get("/health", (_req, res) => {
  res.json({ status: "ok" });
});

server.listen(config.port, () => {
  logger.info("server", `ANDRHELPER backend listening on port ${config.port}`);
});



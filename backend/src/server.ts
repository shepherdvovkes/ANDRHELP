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

  sessions.set(ws, { stt });
  logger.info("server", "WebSocket connection established");

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
        if (!session) return;

        // привязываем sessionId из первого сообщения к контексту сессии
        if (!session.sessionId) {
          session.sessionId = parsed.sessionId;
        }

        const buffer = Buffer.from(parsed.data, "base64");
        // игнорируем слишком короткие чанки, чтобы не зашумлять STT
        if (buffer.length < 200) {
          logger.debug("server", "Ignoring too-small audio chunk");
          return;
        }

        session.stt.addAudioChunk(buffer);
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



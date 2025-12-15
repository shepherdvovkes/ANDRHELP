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

interface SessionContext {
  stt: SpeechToTextService;
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

  // Listen for STT events and try to detect/answer questions
  stt.on("transcript", async (event) => {
    if (event.type !== "final") return;

    const contextText = stt.getBufferedText();
    try {
      const qaResult = await qaService.processTranscriptContext(contextText);
      if (!qaResult) return;

      const payload: OutgoingMessage = {
        type: "answer",
        sessionId: "", // client provides its own id; we keep this simple here
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
      // eslint-disable-next-line no-console
      console.error("[server] QA processing error", err);
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
        const buffer = Buffer.from(parsed.data, "base64");
        session.stt.addAudioChunk(buffer);
      }
    } catch (err) {
      // eslint-disable-next-line no-console
      console.error("[server] Failed to handle message", err);
    }
  });

  ws.on("close", () => {
    const session = sessions.get(ws);
    if (session) {
      session.stt.end();
      sessions.delete(ws);
    }
  });
});

app.get("/health", (_req, res) => {
  res.json({ status: "ok" });
});

server.listen(config.port, () => {
  // eslint-disable-next-line no-console
  console.log(`ANDRHELPER backend listening on port ${config.port}`);
});



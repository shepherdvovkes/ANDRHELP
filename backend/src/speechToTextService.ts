import { EventEmitter } from "events";
import { v1p1beta1 as speech } from "@google-cloud/speech";
import { TranscriptEvent } from "./types";
import { logger } from "./logger";

export interface SpeechToTextOptions {
  languageCode?: string;
  alternativeLanguageCodes?: string[];
}

/**
 * Wraps Google Cloud Streaming Speech-to-Text for a single interview session.
 * Emits TranscriptEvent objects: { type: "partial" | "final", text }.
 */
export class SpeechToTextService extends EventEmitter {
  private client: speech.SpeechClient;
  private recognizeStream?: NodeJS.WritableStream;
  private buffer: string[] = [];

  constructor(private options: SpeechToTextOptions = {}) {
    super();
    this.client = new speech.SpeechClient();
    this.startStream();
  }

  private startStream() {
    // Тип берём как any, чтобы не зависеть от деталей версий @google-cloud/speech.
    const request: any = {
      streamingConfig: {
        config: {
          encoding: "LINEAR16",
          sampleRateHertz: 16000,
          languageCode: this.options.languageCode || "ru-RU",
          alternativeLanguageCodes:
            this.options.alternativeLanguageCodes || ["en-US"],
          enableAutomaticPunctuation: true,
        },
        interimResults: true,
      },
    };

    const stream = this.client
      .streamingRecognize(request)
      .on("error", (err) => {
        logger.error("STT", "streaming error, restarting stream", err);
        this.recognizeStream = undefined;
        // простая попытка перезапуска стрима
        this.startStream();
      })
      .on("data", (data) => {
        const results = data.results ?? [];
        for (const result of results) {
          const alt = result.alternatives?.[0];
          if (!alt?.transcript) continue;

          const text = alt.transcript;
          const isFinal = result.isFinal ?? false;

          const event: TranscriptEvent = {
            type: isFinal ? "final" : "partial",
            text,
          };

          if (isFinal) {
            this.buffer.push(text);
            this.emit("transcript", event);
          } else {
            this.emit("transcript", event);
          }
        }
      });

    this.recognizeStream = stream;
  }

  addAudioChunk(chunk: Buffer) {
    if (!this.recognizeStream) return;
    this.recognizeStream.write(chunk);
  }

  getBufferedText(lastChars = 1000): string {
    const full = this.buffer.join(" ");
    if (full.length <= lastChars) return full;
    return full.slice(-lastChars);
  }

  end() {
    if (this.recognizeStream) {
      this.recognizeStream.end();
      this.recognizeStream = undefined;
    }
  }
}



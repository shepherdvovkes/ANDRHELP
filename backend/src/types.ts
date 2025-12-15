export type TranscriptEventType = "partial" | "final";

export interface TranscriptEvent {
  type: TranscriptEventType;
  text: string;
}

export interface AudioChunkMessage {
  type: "audio_chunk";
  sessionId: string;
  chunkId: number;
  data: string; // base64-encoded audio bytes
}

export interface AnswerMessage {
  type: "answer";
  sessionId: string;
  question: string;
  answerMarkdown: string;
  timestamp: number;
}

export interface ServerStatusMessage {
  type: "status";
  sessionId: string;
  status: string;
}

export type IncomingMessage = AudioChunkMessage;

export type OutgoingMessage = AnswerMessage | ServerStatusMessage;



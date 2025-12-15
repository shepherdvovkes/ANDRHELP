import { OpenAiClient } from "./openAiClient";
import { QuestionDetector } from "./questionDetector";
import { logger } from "./logger";

export interface QaResult {
  question: string;
  answerMarkdown: string;
}

export class QuestionAnswerService {
  private lastCallAt = 0;
  private minIntervalMs = 2000;

  constructor(
    private openAiClient: OpenAiClient,
    private detector: QuestionDetector
  ) {}

  async processTranscriptContext(context: string): Promise<QaResult | null> {
    const now = Date.now();
    if (now - this.lastCallAt < this.minIntervalMs) {
      logger.debug(
        "QuestionAnswerService",
        "Skipping QA call due to rate limit window"
      );
      return null;
    }

    const question = await this.detector.detectQuestionFromContext(context);
    if (!question) return null;

    const answer = await this.openAiClient.answerQuestion(question, context);
    if (!answer) return null;

    this.lastCallAt = now;

    return {
      question,
      answerMarkdown: answer,
    };
  }
}



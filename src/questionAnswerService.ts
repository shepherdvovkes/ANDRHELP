import { OpenAiClient } from "./openAiClient";
import { QuestionDetector } from "./questionDetector";

export interface QaResult {
  question: string;
  answerMarkdown: string;
}

export class QuestionAnswerService {
  constructor(
    private openAiClient: OpenAiClient,
    private detector: QuestionDetector
  ) {}

  async processTranscriptContext(context: string): Promise<QaResult | null> {
    const question = await this.detector.detectQuestionFromContext(context);
    if (!question) return null;

    const answer = await this.openAiClient.answerQuestion(question, context);
    if (!answer) return null;

    return {
      question,
      answerMarkdown: answer,
    };
  }
}



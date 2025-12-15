import { OpenAiClient } from "./openAiClient";

export class QuestionDetector {
  constructor(private openAiClient: OpenAiClient) {}

  /**
   * Very simple heuristic pre-filter before calling LLM.
   */
  private hasQuestionMarkers(text: string): boolean {
    const lowered = text.toLowerCase();
    if (text.includes("?")) return true;
    const markers = [
      "what",
      "why",
      "how",
      "when",
      "где",
      "почему",
      "как",
      "что такое",
      "объясни",
      "можешь рассказать",
    ];
    return markers.some((m) => lowered.includes(m));
  }

  async detectQuestionFromContext(context: string): Promise<string | null> {
    const trimmed = context.trim();
    if (!trimmed) return null;

    if (!this.hasQuestionMarkers(trimmed)) {
      return null;
    }

    return this.openAiClient.detectQuestion(trimmed);
  }
}



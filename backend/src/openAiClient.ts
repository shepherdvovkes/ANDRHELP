import OpenAI from "openai";
import { config } from "./config";

export class OpenAiClient {
  private client: OpenAI | null;

  constructor() {
    if (!config.openAiApiKey) {
      this.client = null;
    } else {
      this.client = new OpenAI({ apiKey: config.openAiApiKey });
    }
  }

  async detectQuestion(context: string): Promise<string | null> {
    if (!this.client) return null;

    const systemPrompt =
      "Ты анализируешь последние реплики технического интервьюера. " +
      "Найди и переформулируй явный вопрос (одним предложением). " +
      "Если вопроса нет, верни ровно строку NO_QUESTION.";

    const completion = await this.client.chat.completions.create({
      model: "gpt-4o-mini",
      messages: [
        { role: "system", content: systemPrompt },
        {
          role: "user",
          content:
            "Последние реплики интервьюера:\n\n" +
            context +
            "\n\nОтветь только вопросом или NO_QUESTION.",
        },
      ],
      max_tokens: 64,
      temperature: 0.1,
    });

    const text = completion.choices[0]?.message?.content?.trim() ?? "";
    if (!text || /^NO_QUESTION$/i.test(text)) {
      return null;
    }
    return text;
  }

  async answerQuestion(question: string, dialogueContext: string): Promise<string | null> {
    if (!this.client) return null;

    const systemPrompt =
      "Ты ассистент, который помогает кандидату на техническом интервью. " +
      "Отвечай ОЧЕНЬ кратко, по существу, в 1-3 предложения. " +
      "Используй markdown. При необходимости можешь использовать код-блоки, формулы ($...$), " +
      "и mermaid-диаграммы (```mermaid ... ```). Если вопрос непонятен, попроси кратко уточнить.";

    const completion = await this.client.chat.completions.create({
      model: "gpt-4o-mini",
      messages: [
        { role: "system", content: systemPrompt },
        {
          role: "user",
          content:
            "Контекст предыдущего диалога (если есть):\n" +
            dialogueContext +
            "\n\nВопрос интервьюера:\n" +
            question,
        },
      ],
      max_tokens: 256,
      temperature: 0.2,
    });

    const text = completion.choices[0]?.message?.content?.trim() ?? "";
    return text || null;
  }
}



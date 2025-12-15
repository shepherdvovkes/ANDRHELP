import { Telegraf } from "telegraf";
import { config } from "./config";

export class TelegramNotifier {
  private bot: Telegraf | null;

  constructor() {
    if (!config.telegramToken || !config.telegramChatId) {
      this.bot = null;
      // eslint-disable-next-line no-console
      console.warn(
        "[TelegramNotifier] TELEGRAM_TOKEN or TELEGRAM_CHAT_ID is not set. Telegram notifications disabled."
      );
    } else {
      this.bot = new Telegraf(config.telegramToken);
    }
  }

  async sendQuestionAnswer(question: string, answerMarkdown: string) {
    if (!this.bot || !config.telegramChatId) return;

    const text = `*Вопрос:*\n${question}\n\n*Ответ:*\n${answerMarkdown}`;
    try {
      await this.bot.telegram.sendMessage(config.telegramChatId, text, {
        parse_mode: "Markdown",
        disable_web_page_preview: true,
      });
    } catch (err) {
      // eslint-disable-next-line no-console
      console.error("[TelegramNotifier] Failed to send message", err);
    }
  }
}



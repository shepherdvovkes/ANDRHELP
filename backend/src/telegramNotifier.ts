import { Telegraf } from "telegraf";
import { config } from "./config";
import { logger } from "./logger";

export class TelegramNotifier {
  private bot: Telegraf | null;

  constructor() {
    if (!config.telegramToken || !config.telegramChatId) {
      this.bot = null;
      logger.warn(
        "TelegramNotifier",
        "TELEGRAM_TOKEN or TELEGRAM_CHAT_ID is not set. Telegram notifications disabled."
      );
    } else {
      this.bot = new Telegraf(config.telegramToken);
    }
  }

  get isEnabled(): boolean {
    return !!this.bot && !!config.telegramChatId;
  }

  async sendQuestionAnswer(question: string, answerMarkdown: string) {
    if (!this.bot || !config.telegramChatId) return;

    const text = `*Вопрос:*\n${question}\n\n*Ответ:*\n${answerMarkdown}`;
    try {
      await this.bot.telegram.sendMessage(config.telegramChatId, text, {
        parse_mode: "Markdown",
      });
    } catch (err) {
      logger.error("TelegramNotifier", "Failed to send message", err);
    }
  }
}



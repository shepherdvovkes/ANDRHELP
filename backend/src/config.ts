import dotenv from "dotenv";
import { logger } from "./logger";

dotenv.config();

export const config = {
  port: Number(process.env.PORT) || 4000,
  openAiApiKey: process.env.OPENAI_API_KEY || "",
  telegramToken: process.env.TELEGRAM_TOKEN || "",
  telegramChatId:
    process.env.TELEGRAM_CHAT_ID || process.env.TELEGRAM_BOT || "",
  googleProjectId:
    process.env.GCLOUD_PROJECT || process.env.GOOGLE_CLOUD_PROJECT || "",
  googleApplicationCredentials:
    process.env.GOOGLE_APPLICATION_CREDENTIALS ||
    process.env.GOOGLE_CREDENTIALS_PATH ||
    "./speech-to-text-key.json",
};

export const runtimeFlags = {
  demoMode: !config.openAiApiKey,
};

if (!config.openAiApiKey) {
  logger.warn(
    "config",
    "OPENAI_API_KEY is not set. QA features will be disabled (demo mode)."
  );
}

if (!config.telegramToken || !config.telegramChatId) {
  logger.warn(
    "config",
    "TELEGRAM_TOKEN or TELEGRAM_CHAT_ID is not set. Telegram notifications disabled."
  );
}


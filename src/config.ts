import dotenv from "dotenv";

dotenv.config();

export const config = {
  port: Number(process.env.PORT) || 4000,
  openAiApiKey: process.env.OPENAI_API_KEY || "",
  telegramToken: process.env.TELEGRAM_TOKEN || "",
  telegramChatId: process.env.TELEGRAM_CHAT_ID || process.env.TELEGRAM_BOT || "",
  googleProjectId: process.env.GCLOUD_PROJECT || process.env.GOOGLE_CLOUD_PROJECT || "",
};

if (!config.openAiApiKey) {
  // We intentionally do not throw here to keep server start simple;
  // but log a clear warning.
  // eslint-disable-next-line no-console
  console.warn("[config] OPENAI_API_KEY is not set. QA features will not work.");
}



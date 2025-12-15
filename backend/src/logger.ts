type LogLevel = "debug" | "info" | "warn" | "error";

function log(level: LogLevel, scope: string, message: string, meta?: unknown) {
  const prefix = `[${scope}]`;
  const text = `${prefix} ${message}`;

  switch (level) {
    case "debug":
      // eslint-disable-next-line no-console
      console.debug(text, meta ?? "");
      break;
    case "info":
      // eslint-disable-next-line no-console
      console.info(text, meta ?? "");
      break;
    case "warn":
      // eslint-disable-next-line no-console
      console.warn(text, meta ?? "");
      break;
    case "error":
      // eslint-disable-next-line no-console
      console.error(text, meta ?? "");
      break;
  }
}

export const logger = {
  debug(scope: string, message: string, meta?: unknown) {
    log("debug", scope, message, meta);
  },
  info(scope: string, message: string, meta?: unknown) {
    log("info", scope, message, meta);
  },
  warn(scope: string, message: string, meta?: unknown) {
    log("warn", scope, message, meta);
  },
  error(scope: string, message: string, meta?: unknown) {
    log("error", scope, message, meta);
  },
};



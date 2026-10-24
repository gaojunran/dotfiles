import { appendFileSync } from "node:fs";
import { homedir } from "node:os";
import { join } from "node:path";

// Provider "venus" occasionally emits duplicated SSE bytes ("data:data:" or "}{"),
// which surfaces as provider.invalid-output and is never retried by core. Retry it.
const PROVIDER_ID = "venus";
const RETRY_DELAY_MS = 1500;
const MAX_RETRIES_PER_STEP = 5;
const MAX_RETRIES_PER_SESSION = 8;
const SESSION_WINDOW_MS = 120_000;
const LOG_PATH = join(homedir(), ".local", "share", "opencode", "venus-retry.log");

const log = (entry: Record<string, unknown>) => {
  try {
    appendFileSync(LOG_PATH, `${JSON.stringify({ at: new Date().toISOString(), pid: process.pid, ...entry })}\n`);
  } catch {
    // logging must never break a retry decision
  }
};

const isVenusBadFrame = (error: { type?: unknown; message?: unknown } | undefined) => {
  if (!error || typeof error.type !== "string") return false;
  if (error.type !== "provider.invalid-output") return false;
  const message = typeof error.message === "string" ? error.message : "";
  return /stream event|SchemaError|valid JSON string|venus/i.test(message);
};

export default {
  id: "venus-retry",
  setup: async (ctx: any) => {
    const session = ctx?.session;
    if (!session || typeof session.hook !== "function") {
      log({ event: "setup-skipped", reason: "session domain unavailable" });
      return () => {};
    }
    log({ event: "setup", opencode: process.env.OPENCODE_PID ?? null });
    const counters = new Map<string, { count: number; last: number }>();
    const registration = await session.hook(
      "retry",
      (event: any) => {
        try {
          const model = event?.model;
          if (model?.providerID !== PROVIDER_ID) return;
          if (!isVenusBadFrame(event?.error)) return;
          if (event?.decision?.retry === true) return;

          const sessionID = String(event?.sessionID ?? "unknown");
          const now = Date.now();
          const previous = counters.get(sessionID);
          const counter =
            previous && now - previous.last < SESSION_WINDOW_MS
              ? { count: previous.count + 1, last: now }
              : { count: 1, last: now };
          counters.set(sessionID, counter);

          const attempt = Number(event?.attempt ?? 0);
          if (attempt > MAX_RETRIES_PER_STEP + 1 || counter.count > MAX_RETRIES_PER_SESSION) {
            log({
              event: "give-up",
              sessionID,
              agent: event?.agent,
              model: `${model.providerID}/${model.id}`,
              type: event?.error?.type,
              message: event?.error?.message,
              attempt,
              sessionRetries: counter.count,
            });
            return;
          }

          event.decision = { retry: true, delay: RETRY_DELAY_MS };
          log({
            event: "retry",
            sessionID,
            agent: event?.agent,
            model: `${model.providerID}/${model.id}`,
            type: event?.error?.type,
            message: event?.error?.message,
            attempt,
            sessionRetries: counter.count,
            delay: RETRY_DELAY_MS,
          });
        } catch (error) {
          log({ event: "handler-error", error: String(error) });
        }
      },
      { providerID: PROVIDER_ID },
    );
    return () => {
      try {
        registration?.dispose?.();
      } catch (error) {
        log({ event: "dispose-error", error: String(error) });
      }
    };
  },
};
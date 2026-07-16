#!/usr/bin/env bun

const DEFAULT_TIMEOUT_MS = 30_000;
const DEFAULT_LIMIT = "100";
// The `business` field requires the optional `business_management` permission.
// Keep baseline account discovery compatible with an `ads_read`-only grant;
// Business Portfolio discovery is available through the explicit commands below.
const ACCOUNT_FIELDS = "id,account_id,name,account_status,currency,timezone_id,timezone_name";
const BUSINESS_FIELDS = "id,name,verification_status,created_time,updated_time";
const CAMPAIGN_FIELDS = "id,name,account_id,objective,status,effective_status,configured_status,buying_type,created_time,updated_time,daily_budget,lifetime_budget";
const ADSET_FIELDS = "id,name,account_id,campaign_id,status,effective_status,configured_status,optimization_goal,billing_event,daily_budget,lifetime_budget,start_time,end_time,created_time,updated_time";
const AD_FIELDS = "id,name,account_id,campaign_id,adset_id,status,effective_status,configured_status,created_time,updated_time";
const INSIGHT_FIELDS = "account_id,account_name,campaign_id,campaign_name,adset_id,adset_name,ad_id,ad_name,date_start,date_stop,spend,impressions,reach,frequency,clicks,inline_link_clicks,ctr,cpc,cpm,actions,cost_per_action_type,action_values,purchase_roas";
const DATE_PRESETS = new Set([
  "today", "yesterday", "this_month", "last_month", "this_quarter",
  "last_3d", "last_7d", "last_14d", "last_28d", "last_30d", "last_90d",
  "this_week_sun_today", "this_week_mon_today", "last_week_sun_sat", "last_week_mon_sun",
]);
const LEVELS = new Set(["account", "campaign", "adset", "ad"]);

type CommandResult = { exitCode: number; stdout: string; stderr: string };
type CommandRunner = (argv: string[], timeoutMs: number) => Promise<CommandResult>;
type CliDependencies = { runCommand?: CommandRunner; timeoutMs?: number };
type IntegrationResponse = {
  ok: boolean;
  status: number;
  body: unknown;
  requestId?: string | null;
};
type CollectionCommand = "accounts" | "campaigns" | "adsets" | "ads";
type ParsedCommand =
  | { command: "status" }
  | { command: "accounts"; after?: string }
  | { command: "businesses"; after?: string }
  | {
      command: "business-accounts";
      businessId: string;
      relationship: "owned" | "client";
      after?: string;
    }
  | { command: Exclude<CollectionCommand, "accounts">; accountId: string; after?: string }
  | {
      command: "insights";
      accountId: string;
      level: string;
      datePreset?: string;
      since?: string;
      until?: string;
      after?: string;
    };

export class MetaAdsCliError extends Error {
  constructor(
    message: string,
    readonly code: string,
    readonly status?: number,
    readonly requestId?: string,
  ) {
    super(message);
    this.name = "MetaAdsCliError";
  }
}

export async function runMetaAdsCli(
  argv: string[],
  dependencies: CliDependencies = {},
): Promise<unknown> {
  const parsed = parseCommand(argv);
  const runCommand = dependencies.runCommand ?? runProcess;
  const timeoutMs = dependencies.timeoutMs ?? DEFAULT_TIMEOUT_MS;

  if (parsed.command === "status") {
    const connection = asRecord(await runMasterclawJson(
      runCommand,
      timeoutMs,
      ["masterclaw", "connections", "check", "--provider", "meta-ads"],
    ));
    const connected = stringArray(connection.connectedProviderIds);
    const missing = stringArray(connection.missingProviderIds);
    return {
      connected: connection.ready === true
        && connected.includes("meta-ads")
        && !missing.includes("meta-ads"),
      provider: "meta-ads",
      mode: "read-only",
      connection,
    };
  }

  if (parsed.command === "accounts") {
    return requestCollection(runCommand, timeoutMs, "me/adaccounts", {
      fields: ACCOUNT_FIELDS,
      limit: DEFAULT_LIMIT,
      after: parsed.after,
    });
  }

  if (parsed.command === "businesses") {
    return requestCollection(runCommand, timeoutMs, "me/businesses", {
      fields: BUSINESS_FIELDS,
      limit: DEFAULT_LIMIT,
      after: parsed.after,
    });
  }

  if (parsed.command === "business-accounts") {
    const businessId = normalizeBusinessId(parsed.businessId);
    const edge = parsed.relationship === "owned"
      ? "owned_ad_accounts"
      : "client_ad_accounts";
    return requestCollection(runCommand, timeoutMs, `${businessId}/${edge}`, {
      fields: ACCOUNT_FIELDS,
      limit: DEFAULT_LIMIT,
      after: parsed.after,
    });
  }

  const accountId = normalizeAccountId(parsed.accountId);
  if (parsed.command !== "insights") {
    const fields = parsed.command === "campaigns"
      ? CAMPAIGN_FIELDS
      : parsed.command === "adsets"
        ? ADSET_FIELDS
        : AD_FIELDS;
    return requestCollection(runCommand, timeoutMs, `${accountId}/${parsed.command}`, {
      fields,
      limit: DEFAULT_LIMIT,
      after: parsed.after,
    }, accountId);
  }

  const query: Record<string, string | undefined> = {
    fields: INSIGHT_FIELDS,
    limit: DEFAULT_LIMIT,
    level: parsed.level,
    after: parsed.after,
  };
  if (parsed.datePreset) query.date_preset = parsed.datePreset;
  if (parsed.since && parsed.until) {
    query.time_range = JSON.stringify({ since: parsed.since, until: parsed.until });
  }
  return requestCollection(
    runCommand,
    timeoutMs,
    `${accountId}/insights`,
    query,
    accountId,
  );
}

function parseCommand(argv: string[]): ParsedCommand {
  const [command, ...rest] = argv;
  if (command === "status") {
    parseFlags(rest, new Set());
    return { command };
  }
  if (command === "accounts") {
    const flags = parseFlags(rest, new Set(["after"]));
    return { command, after: flags.after };
  }
  if (command === "businesses") {
    const flags = parseFlags(rest, new Set(["after"]));
    return { command, after: flags.after };
  }
  if (command === "business-accounts") {
    const flags = parseFlags(rest, new Set(["business-id", "relationship", "after"]));
    const relationship = flags.relationship ?? "owned";
    if (relationship !== "owned" && relationship !== "client") {
      usage("--relationship must be owned or client");
    }
    return {
      command,
      businessId: requiredFlag(flags, "business-id"),
      relationship,
      after: flags.after,
    };
  }
  if (command === "campaigns" || command === "adsets" || command === "ads") {
    const flags = parseFlags(rest, new Set(["account-id", "after"]));
    return {
      command,
      accountId: requiredFlag(flags, "account-id"),
      after: flags.after,
    };
  }
  if (command === "insights") {
    const flags = parseFlags(
      rest,
      new Set(["account-id", "level", "date-preset", "since", "until", "after"]),
    );
    const level = flags.level ?? "campaign";
    if (!LEVELS.has(level)) usage("--level must be account, campaign, adset, or ad");
    const datePreset = flags["date-preset"];
    const since = flags.since;
    const until = flags.until;
    if (datePreset) {
      if (!DATE_PRESETS.has(datePreset)) usage("Unsupported --date-preset");
      if (since || until) usage("Use either --date-preset or --since/--until, not both");
    } else if (Boolean(since) !== Boolean(until)) {
      usage("--since and --until must be provided together");
    }
    if (!datePreset && !since) usage("Insights require --date-preset or --since/--until");
    if (since && until) validateDateRange(since, until);
    return {
      command,
      accountId: requiredFlag(flags, "account-id"),
      level,
      datePreset,
      since,
      until,
      after: flags.after,
    };
  }
  usage("Usage: meta_ads.ts status | accounts|businesses [--after CURSOR] | business-accounts --business-id ID [--relationship owned|client] [--after CURSOR] | campaigns|adsets|ads --account-id ID [--after CURSOR] | insights --account-id ID [--level LEVEL] (--date-preset PRESET | --since YYYY-MM-DD --until YYYY-MM-DD) [--after CURSOR]");
}

function parseFlags(argv: string[], allowed: Set<string>): Record<string, string> {
  const flags: Record<string, string> = {};
  for (let index = 0; index < argv.length; index += 2) {
    const raw = argv[index];
    const value = argv[index + 1];
    if (!raw?.startsWith("--") || !value) usage("Every option requires a value");
    const name = raw.slice(2);
    if (!allowed.has(name)) usage(`Unsupported option: --${name}`);
    if (flags[name]) usage(`Duplicate option: --${name}`);
    flags[name] = value;
  }
  return flags;
}

function requiredFlag(flags: Record<string, string>, name: string): string {
  const value = flags[name];
  if (!value) usage(`Missing --${name}`);
  return value;
}

function usage(message: string): never {
  throw new MetaAdsCliError(message, "META_ADS_USAGE");
}

function normalizeAccountId(value: string): string {
  const normalized = value.trim().replace(/^act_/, "");
  if (!/^\d+$/.test(normalized)) usage("Meta ad account ID must contain only digits");
  return `act_${normalized}`;
}

function normalizeBusinessId(value: string): string {
  const normalized = value.trim();
  if (!/^\d+$/.test(normalized)) usage("Meta business ID must contain only digits");
  return normalized;
}

function validateDateRange(since: string, until: string): void {
  const start = parseDate(since, "--since");
  const end = parseDate(until, "--until");
  const days = Math.floor((end.getTime() - start.getTime()) / 86_400_000) + 1;
  if (days < 1 || days > 90) usage("Custom insight range must be between 1 and 90 days");
}

function parseDate(value: string, label: string): Date {
  if (!/^\d{4}-\d{2}-\d{2}$/.test(value)) usage(`${label} must use YYYY-MM-DD`);
  const parsed = new Date(`${value}T00:00:00.000Z`);
  if (Number.isNaN(parsed.getTime()) || parsed.toISOString().slice(0, 10) !== value) {
    usage(`${label} is invalid`);
  }
  return parsed;
}

async function requestCollection(
  runCommand: CommandRunner,
  timeoutMs: number,
  path: string,
  query: Record<string, string | undefined>,
  accountId?: string,
): Promise<Record<string, unknown>> {
  const body = await requestMetaAds(runCommand, timeoutMs, path, query);
  const record = asRecord(body);
  const paging = asRecord(record.paging);
  const cursors = asRecord(paging.cursors);
  return {
    data: Array.isArray(record.data) ? record.data : [],
    nextCursor: typeof cursors.after === "string" ? cursors.after : null,
    ...(accountId ? { accountId } : {}),
  };
}

async function requestMetaAds(
  runCommand: CommandRunner,
  timeoutMs: number,
  path: string,
  query: Record<string, string | undefined>,
): Promise<unknown> {
  const argv = [
    "masterclaw", "integrations", "request",
    "--provider", "meta-ads",
    "--method", "GET",
    "--path", path,
  ];
  for (const [key, value] of Object.entries(query)) {
    if (value !== undefined) argv.push("--query", `${key}:${value}`);
  }
  const response = parseIntegrationResponse(await runMasterclawJson(runCommand, timeoutMs, argv));
  if (!response.ok) {
    throw metaResponseError(response.status, response.body, response.requestId ?? undefined);
  }
  return response.body;
}

function metaResponseError(
  status: number,
  payload: unknown,
  proxyRequestId?: string,
): MetaAdsCliError {
  const error = asRecord(asRecord(payload).error);
  const message = typeof error.message === "string" ? error.message : "Meta Ads request failed";
  const numericCode = typeof error.code === "number" ? String(error.code) : undefined;
  const subcode = typeof error.error_subcode === "number" ? String(error.error_subcode) : undefined;
  const type = typeof error.type === "string" ? error.type : undefined;
  const trace = typeof error.fbtrace_id === "string" ? error.fbtrace_id : undefined;
  return new MetaAdsCliError(
    message,
    subcode ? `META_${numericCode ?? "ERROR"}_${subcode}` : type ?? (numericCode ? `META_${numericCode}` : "META_ADS_REQUEST_FAILED"),
    status,
    trace ?? proxyRequestId,
  );
}

function parseIntegrationResponse(value: unknown): IntegrationResponse {
  const response = asRecord(value);
  if (
    typeof response.ok !== "boolean"
    || typeof response.status !== "number"
    || !("body" in response)
    || (response.requestId !== undefined
      && response.requestId !== null
      && typeof response.requestId !== "string")
  ) {
    throw new MetaAdsCliError(
      "Chorus returned an invalid integration response",
      "META_ADS_PROXY_INVALID",
    );
  }
  return {
    ok: response.ok,
    status: response.status,
    body: response.body,
    requestId: response.requestId as string | null | undefined,
  };
}

async function runMasterclawJson(
  runCommand: CommandRunner,
  timeoutMs: number,
  argv: string[],
): Promise<unknown> {
  let result: CommandResult;
  try {
    result = await runCommand(argv, timeoutMs);
  } catch (error) {
    if (error instanceof MetaAdsCliError) throw error;
    throw new MetaAdsCliError(
      error instanceof Error ? error.message : "Masterclaw command failed",
      "META_ADS_RUNTIME_ERROR",
    );
  }
  if (result.exitCode !== 0) {
    const payload = parseJson(result.stderr) ?? parseJson(result.stdout);
    const error = asRecord(asRecord(payload).error);
    const details = asRecord(error.details);
    if (
      error.code === "INTEGRATION_REQUEST_FAILED"
      && typeof details.status === "number"
      && "body" in details
    ) {
      throw metaResponseError(
        details.status,
        details.body,
        typeof details.requestId === "string" ? details.requestId : undefined,
      );
    }
    throw new MetaAdsCliError(
      typeof error.message === "string" ? error.message : "Masterclaw command failed",
      typeof error.code === "string" ? error.code : "META_ADS_RUNTIME_ERROR",
    );
  }
  const payload = parseJson(result.stdout);
  if (payload === null) {
    throw new MetaAdsCliError("Masterclaw returned invalid JSON", "META_ADS_RUNTIME_INVALID");
  }
  return payload;
}

async function runProcess(argv: string[], timeoutMs: number): Promise<CommandResult> {
  const child = Bun.spawn(argv, { stdin: "ignore", stdout: "pipe", stderr: "pipe" });
  let timedOut = false;
  const timer = setTimeout(() => {
    timedOut = true;
    child.kill();
  }, timeoutMs);
  try {
    const [stdout, stderr, exitCode] = await Promise.all([
      new Response(child.stdout).text(),
      new Response(child.stderr).text(),
      child.exited,
    ]);
    if (timedOut) throw new MetaAdsCliError("Meta Ads request timed out", "META_ADS_TIMEOUT");
    return { exitCode, stdout, stderr };
  } finally {
    clearTimeout(timer);
  }
}

function parseJson(value: string): unknown | null {
  const text = value.trim();
  if (!text) return null;
  try {
    return JSON.parse(text) as unknown;
  } catch {
    return extractEmbeddedJson(text);
  }
}

function extractEmbeddedJson(text: string): unknown | null {
  for (let start = 0; start < text.length; start += 1) {
    const opening = text[start];
    if (opening !== "{" && opening !== "[") continue;

    const stack: string[] = [];
    let inString = false;
    let escaped = false;
    for (let index = start; index < text.length; index += 1) {
      const character = text[index];
      if (inString) {
        if (escaped) {
          escaped = false;
        } else if (character === "\\") {
          escaped = true;
        } else if (character === '"') {
          inString = false;
        }
        continue;
      }
      if (character === '"') {
        inString = true;
        continue;
      }
      if (character === "{" || character === "[") {
        stack.push(character);
        continue;
      }
      if (character !== "}" && character !== "]") continue;
      const expectedOpening = character === "}" ? "{" : "[";
      if (stack.pop() !== expectedOpening) break;
      if (stack.length > 0) continue;

      try {
        return JSON.parse(text.slice(start, index + 1)) as unknown;
      } catch {
        break;
      }
    }
  }
  return null;
}

function asRecord(value: unknown): Record<string, unknown> {
  return value && typeof value === "object" && !Array.isArray(value)
    ? value as Record<string, unknown>
    : {};
}

function stringArray(value: unknown): string[] {
  return Array.isArray(value)
    ? value.filter((item): item is string => typeof item === "string")
    : [];
}

function serializedError(error: unknown): Record<string, unknown> {
  if (error instanceof MetaAdsCliError) {
    return {
      error: error.message,
      code: error.code,
      status: error.status ?? null,
      requestId: error.requestId ?? null,
    };
  }
  return { error: "Meta Ads command failed", code: "META_ADS_UNKNOWN_ERROR" };
}

if (import.meta.main) {
  runMetaAdsCli(process.argv.slice(2))
    .then((result) => process.stdout.write(`${JSON.stringify(result, null, 2)}\n`))
    .catch((error) => {
      process.stderr.write(`${JSON.stringify(serializedError(error))}\n`);
      process.exitCode = 1;
    });
}

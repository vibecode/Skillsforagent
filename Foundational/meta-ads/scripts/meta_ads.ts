#!/usr/bin/env bun

import { createHash } from "node:crypto";
import { homedir } from "node:os";
import { mkdir, readFile, rename, unlink, writeFile } from "node:fs/promises";
import { join } from "node:path";

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
const CAMPAIGN_OBJECTIVES = new Set([
  "APP_INSTALLS", "BRAND_AWARENESS", "CONVERSIONS", "EVENT_RESPONSES",
  "LEAD_GENERATION", "LINK_CLICKS", "LOCAL_AWARENESS", "MESSAGES",
  "OFFER_CLAIMS", "OUTCOME_APP_PROMOTION", "OUTCOME_AWARENESS",
  "OUTCOME_ENGAGEMENT", "OUTCOME_LEADS", "OUTCOME_SALES", "OUTCOME_TRAFFIC",
  "PAGE_LIKES", "POST_ENGAGEMENT", "PRODUCT_CATALOG_SALES", "REACH",
  "STORE_VISITS", "VIDEO_VIEWS",
]);
const SPECIAL_AD_CATEGORIES = new Set([
  "NONE", "EMPLOYMENT", "HOUSING", "CREDIT", "ISSUES_ELECTIONS_POLITICS",
  "ONLINE_GAMBLING_AND_GAMING", "FINANCIAL_PRODUCTS_SERVICES",
]);
const CAMPAIGN_STATUSES = new Set(["ACTIVE", "PAUSED", "ARCHIVED"]);
const BID_STRATEGIES = new Set([
  "LOWEST_COST_WITHOUT_CAP", "LOWEST_COST_WITH_BID_CAP", "COST_CAP",
  "LOWEST_COST_WITH_MIN_ROAS",
]);
const PLAN_TTL_MS = 30 * 60 * 1000;

type CommandResult = { exitCode: number; stdout: string; stderr: string };
type CommandRunner = (argv: string[], timeoutMs: number) => Promise<CommandResult>;
type CliDependencies = {
  runCommand?: CommandRunner;
  timeoutMs?: number;
  planDir?: string;
  now?: () => Date;
};
type IntegrationResponse = {
  ok: boolean;
  status: number;
  body: unknown;
  requestId?: string | null;
};
type CollectionCommand = "accounts" | "campaigns" | "adsets" | "ads";
type CampaignMutationBody = Record<string, string | string[] | boolean>;
type StoredCampaignPlan = {
  version: 1;
  provider: "meta-ads";
  operation: "create-campaign" | "update-campaign";
  path: string;
  body: CampaignMutationBody;
  backendPlanId: string;
  createdAt: string;
  expiresAt: string;
  planId: string;
};
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
    }
  | {
      command: "campaign-plan-create";
      accountId: string;
      body: CampaignMutationBody;
    }
  | {
      command: "campaign-plan-update";
      campaignId: string;
      body: CampaignMutationBody;
    }
  | { command: "campaign-apply"; planId: string; confirmation: string };

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
  const chorusDataDir = process.env.CHORUS_DATA_DIR ?? join(homedir(), ".chorus");
  const planDir = dependencies.planDir ?? join(chorusDataDir, "meta-ads", "plans");
  const now = dependencies.now ?? (() => new Date());

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
      mode: "campaign-management",
      connection,
    };
  }

  if (parsed.command === "campaign-plan-create") {
    const accountId = normalizeAccountId(parsed.accountId);
    return validateAndStorePlan({
      runCommand,
      timeoutMs,
      planDir,
      now: now(),
      operation: "create-campaign",
      path: `${accountId}/campaigns`,
      body: parsed.body,
    });
  }

  if (parsed.command === "campaign-plan-update") {
    const campaignId = normalizeCampaignId(parsed.campaignId);
    return validateAndStorePlan({
      runCommand,
      timeoutMs,
      planDir,
      now: now(),
      operation: "update-campaign",
      path: campaignId,
      body: parsed.body,
    });
  }

  if (parsed.command === "campaign-apply") {
    return applyStoredPlan({
      runCommand,
      timeoutMs,
      planDir,
      now: now(),
      planId: parsed.planId,
      confirmation: parsed.confirmation,
    });
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
  if (command === "campaign-plan-create") {
    const flags = parseFlags(rest, new Set([
      "account-id", "name", "objective", "special-ad-categories", "daily-budget",
      "lifetime-budget", "spend-cap", "bid-strategy", "adset-budget-sharing",
    ]));
    return {
      command,
      accountId: requiredFlag(flags, "account-id"),
      body: campaignCreateBody(flags),
    };
  }
  if (command === "campaign-plan-update") {
    const flags = parseFlags(rest, new Set([
      "campaign-id", "name", "status", "daily-budget", "lifetime-budget", "spend-cap",
    ]));
    return {
      command,
      campaignId: requiredFlag(flags, "campaign-id"),
      body: campaignUpdateBody(flags),
    };
  }
  if (command === "campaign-apply") {
    const flags = parseFlags(rest, new Set(["plan-id", "confirm"]));
    return {
      command,
      planId: requiredFlag(flags, "plan-id"),
      confirmation: requiredFlag(flags, "confirm"),
    };
  }
  usage("Usage: meta_ads.ts status | accounts|businesses [--after CURSOR] | business-accounts --business-id ID [--relationship owned|client] [--after CURSOR] | campaigns|adsets|ads --account-id ID [--after CURSOR] | insights --account-id ID [--level LEVEL] (--date-preset PRESET | --since YYYY-MM-DD --until YYYY-MM-DD) [--after CURSOR] | campaign-plan-create --account-id ID --name NAME --objective OBJECTIVE --special-ad-categories NONE [budget options] | campaign-plan-update --campaign-id ID [changes] | campaign-apply --plan-id ID --confirm ID");
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

function optionalMoney(flags: Record<string, string>, name: string): string | undefined {
  const value = flags[name];
  if (value === undefined) return undefined;
  if (!/^[1-9]\d{0,17}$/.test(value)) {
    usage(`--${name} must be a positive integer in account currency subunits`);
  }
  return value;
}

function campaignCreateBody(flags: Record<string, string>): CampaignMutationBody {
  const name = requiredFlag(flags, "name").trim();
  if (!name || name.length > 255) usage("--name must be between 1 and 255 characters");
  const objective = requiredFlag(flags, "objective");
  if (!CAMPAIGN_OBJECTIVES.has(objective)) usage("Unsupported --objective");
  const categories = requiredFlag(flags, "special-ad-categories")
    .split(",")
    .map((value) => value.trim())
    .filter(Boolean);
  if (
    categories.length === 0
    || new Set(categories).size !== categories.length
    || categories.some((value) => !SPECIAL_AD_CATEGORIES.has(value))
    || (categories.includes("NONE") && categories.length > 1)
  ) {
    usage("Unsupported --special-ad-categories");
  }
  const dailyBudget = optionalMoney(flags, "daily-budget");
  const lifetimeBudget = optionalMoney(flags, "lifetime-budget");
  if (dailyBudget && lifetimeBudget) usage("Use either --daily-budget or --lifetime-budget, not both");
  const body: CampaignMutationBody = {
    name,
    objective,
    status: "PAUSED",
    special_ad_categories: categories,
  };
  if (dailyBudget) body.daily_budget = dailyBudget;
  if (lifetimeBudget) body.lifetime_budget = lifetimeBudget;
  const spendCap = optionalMoney(flags, "spend-cap");
  if (spendCap) body.spend_cap = spendCap;
  const bidStrategy = flags["bid-strategy"];
  if (bidStrategy) {
    if (!BID_STRATEGIES.has(bidStrategy)) usage("Unsupported --bid-strategy");
    body.bid_strategy = bidStrategy;
  }
  const sharing = flags["adset-budget-sharing"];
  if (sharing !== undefined) {
    if (sharing !== "true" && sharing !== "false") {
      usage("--adset-budget-sharing must be true or false");
    }
    body.is_adset_budget_sharing_enabled = sharing === "true";
  }
  return body;
}

function campaignUpdateBody(flags: Record<string, string>): CampaignMutationBody {
  const body: CampaignMutationBody = {};
  if (flags.name !== undefined) {
    const name = flags.name.trim();
    if (!name || name.length > 255) usage("--name must be between 1 and 255 characters");
    body.name = name;
  }
  if (flags.status !== undefined) {
    if (!CAMPAIGN_STATUSES.has(flags.status)) usage("--status must be ACTIVE, PAUSED, or ARCHIVED");
    body.status = flags.status;
  }
  const dailyBudget = optionalMoney(flags, "daily-budget");
  const lifetimeBudget = optionalMoney(flags, "lifetime-budget");
  if (dailyBudget && lifetimeBudget) usage("Use either --daily-budget or --lifetime-budget, not both");
  if (dailyBudget) body.daily_budget = dailyBudget;
  if (lifetimeBudget) body.lifetime_budget = lifetimeBudget;
  const spendCap = optionalMoney(flags, "spend-cap");
  if (spendCap) body.spend_cap = spendCap;
  if (Object.keys(body).length === 0) usage("Campaign update requires at least one change");
  return body;
}

function usage(message: string): never {
  throw new MetaAdsCliError(message, "META_ADS_USAGE");
}

function normalizeAccountId(value: string): string {
  const normalized = value.trim().replace(/^act_/, "");
  if (!/^\d+$/.test(normalized)) usage("Meta ad account ID must contain only digits");
  return `act_${normalized}`;
}

function normalizeCampaignId(value: string): string {
  const normalized = value.trim();
  if (!/^\d+$/.test(normalized)) usage("Meta campaign ID must contain only digits");
  return normalized;
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

function planHash(plan: Omit<StoredCampaignPlan, "planId">): string {
  return createHash("sha256").update(JSON.stringify(plan)).digest("hex").slice(0, 24);
}

function planPath(planDir: string, planId: string): string {
  if (!/^[a-f0-9]{24}$/.test(planId)) usage("Invalid Meta Ads plan ID");
  return join(planDir, `${planId}.json`);
}

function claimedPlanPath(planDir: string, planId: string): string {
  return join(planDir, `${planId}.applying.json`);
}

function nodeErrorCode(error: unknown): string | undefined {
  return error && typeof error === "object" && "code" in error
    ? String((error as { code?: unknown }).code ?? "")
    : undefined;
}

function planPathMatchesOperation(plan: Omit<StoredCampaignPlan, "planId">): boolean {
  return plan.operation === "create-campaign"
    ? /^act_\d+\/campaigns$/.test(plan.path)
    : plan.operation === "update-campaign" && /^\d+$/.test(plan.path);
}

function isAmbiguousMutationOutcome(error: unknown): boolean {
  if (!(error instanceof MetaAdsCliError)) return false;
  return new Set([
    "INTEGRATION_PROXY_TIMEOUT",
    "INTEGRATION_PROXY_UPSTREAM_ERROR",
    "INTEGRATION_PROXY_RESPONSE_TOO_LARGE",
  ]).has(error.code);
}

async function validateAndStorePlan(input: {
  runCommand: CommandRunner;
  timeoutMs: number;
  planDir: string;
  now: Date;
  operation: StoredCampaignPlan["operation"];
  path: string;
  body: CampaignMutationBody;
}): Promise<Record<string, unknown>> {
  const validationResponse = await requestMetaAdsMutation(
    input.runCommand,
    input.timeoutMs,
    input.path,
    { ...input.body, execution_options: ["validate_only"] },
  );
  const validationRecord = asRecord(validationResponse);
  const backendPlanId = typeof validationRecord.chorusMutationPlanId === "string"
    ? validationRecord.chorusMutationPlanId
    : null;
  if (!backendPlanId) {
    throw new MetaAdsCliError(
      "Chorus did not issue a one-time Meta Ads mutation plan",
      "META_ADS_PLAN_NOT_ISSUED",
    );
  }
  const { chorusMutationPlanId: _internalPlanId, ...validation } = validationRecord;
  const unsigned: Omit<StoredCampaignPlan, "planId"> = {
    version: 1,
    provider: "meta-ads",
    operation: input.operation,
    path: input.path,
    body: input.body,
    backendPlanId,
    createdAt: input.now.toISOString(),
    expiresAt: new Date(input.now.getTime() + PLAN_TTL_MS).toISOString(),
  };
  const plan: StoredCampaignPlan = { ...unsigned, planId: planHash(unsigned) };
  await mkdir(input.planDir, { recursive: true, mode: 0o700 });
  const serializedPlan = `${JSON.stringify(plan, null, 2)}\n`;
  const filePath = planPath(input.planDir, plan.planId);
  try {
    await writeFile(filePath, serializedPlan, { flag: "wx", mode: 0o600 });
  } catch (error) {
    if (nodeErrorCode(error) === "EEXIST") {
      const existing = await readFile(filePath, "utf8").catch(() => "");
      if (existing !== serializedPlan) {
        throw new MetaAdsCliError(
          "A different Meta Ads plan already uses this plan ID; create a new plan",
          "META_ADS_PLAN_COLLISION",
        );
      }
    } else {
      throw new MetaAdsCliError("Meta Ads plan could not be stored", "META_ADS_PLAN_STORE_FAILED");
    }
  }
  const { backendPlanId: _hiddenBackendPlanId, ...publicPlan } = plan;
  return {
    validated: true,
    validation,
    plan: publicPlan,
    approvalRequired: true,
    approvalPhrase: `Approve Meta Ads plan ${plan.planId}`,
    applyCommand: `bun \"$META_ADS_CLI\" campaign-apply --plan-id ${plan.planId} --confirm ${plan.planId}`,
  };
}

async function applyStoredPlan(input: {
  runCommand: CommandRunner;
  timeoutMs: number;
  planDir: string;
  now: Date;
  planId: string;
  confirmation: string;
}): Promise<Record<string, unknown>> {
  if (input.confirmation !== input.planId) usage("--confirm must exactly match --plan-id");
  const filePath = planPath(input.planDir, input.planId);
  const claimedPath = claimedPlanPath(input.planDir, input.planId);
  try {
    // Atomic rename is the one-time execution barrier. Once claimed, another
    // process cannot read the normal plan path and replay the same approval.
    await rename(filePath, claimedPath);
  } catch {
    throw new MetaAdsCliError(
      "Meta Ads plan was not found or is already being applied",
      "META_ADS_PLAN_NOT_FOUND",
    );
  }
  let parsed: unknown;
  try {
    parsed = JSON.parse(await readFile(claimedPath, "utf8"));
  } catch (error) {
    await unlink(claimedPath).catch(() => {});
    throw new MetaAdsCliError(
      error instanceof SyntaxError ? "Meta Ads plan is invalid" : "Meta Ads plan was not found",
      error instanceof SyntaxError ? "META_ADS_PLAN_INVALID" : "META_ADS_PLAN_NOT_FOUND",
    );
  }
  const record = asRecord(parsed);
  const body = asRecord(record.body) as CampaignMutationBody;
  const unsigned: Omit<StoredCampaignPlan, "planId"> = {
    version: record.version as 1,
    provider: record.provider as "meta-ads",
    operation: record.operation as StoredCampaignPlan["operation"],
    path: String(record.path ?? ""),
    body,
    backendPlanId: String(record.backendPlanId ?? ""),
    createdAt: String(record.createdAt ?? ""),
    expiresAt: String(record.expiresAt ?? ""),
  };
  if (
    unsigned.version !== 1
    || unsigned.provider !== "meta-ads"
    || !new Set(["create-campaign", "update-campaign"]).has(unsigned.operation)
    || !planPathMatchesOperation(unsigned)
    || !/^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i.test(unsigned.backendPlanId)
    || planHash(unsigned) !== input.planId
    || record.planId !== input.planId
  ) {
    await unlink(claimedPath).catch(() => {});
    throw new MetaAdsCliError("Meta Ads plan integrity check failed", "META_ADS_PLAN_INVALID");
  }
  const expiresAt = new Date(unsigned.expiresAt);
  if (Number.isNaN(expiresAt.getTime()) || expiresAt.getTime() < input.now.getTime()) {
    await unlink(claimedPath).catch(() => {});
    throw new MetaAdsCliError("Meta Ads plan expired; create and approve a new plan", "META_ADS_PLAN_EXPIRED");
  }
  let response: unknown;
  try {
    response = await requestMetaAdsMutation(
      input.runCommand,
      input.timeoutMs,
      unsigned.path,
      body,
      unsigned.backendPlanId,
    );
  } catch (error) {
    if (isAmbiguousMutationOutcome(error)) {
      await unlink(claimedPath).catch(() => {});
      throw new MetaAdsCliError(
        "Meta Ads mutation outcome is unknown; inspect the account before creating a new plan",
        "META_ADS_MUTATION_OUTCOME_UNKNOWN",
      );
    }
    try {
      await rename(claimedPath, filePath);
    } catch {
      throw new MetaAdsCliError(
        "Meta Ads request failed and the plan could not be restored; create a new plan",
        "META_ADS_PLAN_RECOVERY_FAILED",
      );
    }
    throw error;
  }
  // Cleanup is best-effort after a confirmed upstream success. The claimed
  // filename is never accepted by campaign-apply, so cleanup failure cannot
  // make the approved mutation replayable.
  await unlink(claimedPath).catch(() => {});
  return {
    applied: true,
    planId: input.planId,
    operation: unsigned.operation,
    response,
  };
}

async function requestMetaAdsMutation(
  runCommand: CommandRunner,
  timeoutMs: number,
  path: string,
  body: CampaignMutationBody & { execution_options?: string[] },
  mutationPlanId?: string,
): Promise<unknown> {
  const argv = [
    "masterclaw", "integrations", "request",
    "--provider", "meta-ads",
    "--method", "POST",
    "--path", path,
    "--body", JSON.stringify(body),
  ];
  if (mutationPlanId) {
    argv.push("--header", `x-chorus-mutation-plan-id:${mutationPlanId}`);
  }
  const response = parseIntegrationResponse(await runMasterclawJson(runCommand, timeoutMs, argv));
  if (!response.ok) {
    throw metaResponseError(response.status, response.body, response.requestId ?? undefined);
  }
  return response.body;
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
  let start = -1;
  let stack: string[] = [];
  let inString = false;
  let escaped = false;
  let lineHasNonWhitespace = false;
  for (let index = 0; index < text.length; index += 1) {
    const character = text[index]!;
    if (start < 0) {
      if (character === "\n") {
        lineHasNonWhitespace = false;
        continue;
      }
      if (!lineHasNonWhitespace && (character === " " || character === "\t")) continue;
      if (!lineHasNonWhitespace && (character === "{" || character === "[")) {
        start = index;
        stack = [character];
        lineHasNonWhitespace = true;
        continue;
      }
      lineHasNonWhitespace = true;
      continue;
    }
    if (inString) {
      if (escaped) escaped = false;
      else if (character === "\\") escaped = true;
      else if (character === '"') inString = false;
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
    if (stack.pop() !== expectedOpening) {
      start = -1;
      stack = [];
      continue;
    }
    if (stack.length > 0) continue;
    try {
      return JSON.parse(text.slice(start, index + 1)) as unknown;
    } catch {
      start = -1;
      stack = [];
      inString = false;
      escaped = false;
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

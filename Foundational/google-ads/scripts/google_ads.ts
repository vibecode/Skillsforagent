#!/usr/bin/env bun

const DEFAULT_TIMEOUT_MS = 30_000;
const MAX_QUERY_ROWS = 100;
const MAX_QUERY_LENGTH = 10_000;
const MAX_HIERARCHY_MANAGERS = 100;
const MAX_HIERARCHY_REQUESTS = 500;

type CommandResult = {
  exitCode: number;
  stdout: string;
  stderr: string;
};

type CommandRunner = (argv: string[], timeoutMs: number) => Promise<CommandResult>;

type CliDependencies = {
  runCommand?: CommandRunner;
  timeoutMs?: number;
};

type IntegrationResponse = {
  ok: boolean;
  status: number;
  body: unknown;
  requestId?: string | null;
};

type ParsedCommand =
  | { command: "status" }
  | { command: "accounts"; loginCustomerId?: string }
  | {
      command: "report";
      customerId: string;
      loginCustomerId?: string;
      query: string;
      pageToken?: string;
    };

export class GoogleAdsCliError extends Error {
  constructor(
    message: string,
    readonly code: string,
    readonly status?: number,
    readonly requestId?: string,
  ) {
    super(message);
    this.name = "GoogleAdsCliError";
  }
}

export async function runGoogleAdsCli(
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
      ["masterclaw", "connections", "check", "--provider", "google-ads"],
    ));
    const connectedProviderIds = stringArray(connection.connectedProviderIds);
    const missingProviderIds = stringArray(connection.missingProviderIds);
    return {
      connected: connection.ready === true
        && connectedProviderIds.includes("google-ads")
        && !missingProviderIds.includes("google-ads"),
      provider: "google-ads",
      mode: "read-only",
      connection,
    };
  }

  if (parsed.command === "accounts") {
    const accessible = await requestGoogleAds(
      runCommand,
      timeoutMs,
      "customers:listAccessibleCustomers",
      { method: "GET" },
    );
    const resourceNames = readResourceNames(accessible);
    const directCustomerIds = resourceNames.map(normalizeResourceName);

    if (!parsed.loginCustomerId) {
      return { accounts: directCustomerIds.map((customerId) => ({ customerId })), direct: true };
    }

    const loginCustomerId = normalizeCustomerId(parsed.loginCustomerId, "login customer ID");
    if (!directCustomerIds.includes(loginCustomerId)) {
      throw new GoogleAdsCliError(
        "Manager account is not directly accessible through this connection",
        "GOOGLE_ADS_MANAGER_NOT_ACCESSIBLE",
      );
    }

    return discoverAccountHierarchy(
      runCommand,
      timeoutMs,
      loginCustomerId,
    );
  }

  const customerId = normalizeCustomerId(parsed.customerId, "customer ID");
  const loginCustomerId = parsed.loginCustomerId
    ? normalizeCustomerId(parsed.loginCustomerId, "login customer ID")
    : undefined;
  const body: Record<string, string> = { query: boundedGaql(parsed.query) };
  if (parsed.pageToken) body.pageToken = parsed.pageToken;
  const report = await requestGoogleAds(
    runCommand,
    timeoutMs,
    `customers/${customerId}/googleAds:search`,
    { method: "POST", loginCustomerId, body },
  );
  return {
    ...asRecord(report),
    customerId,
    loginCustomerId: loginCustomerId ?? null,
  };
}

export function boundedGaql(query: string): string {
  const normalized = query.trim();
  if (!normalized || normalized.length > MAX_QUERY_LENGTH) {
    throw new GoogleAdsCliError("GAQL query length is invalid", "GOOGLE_ADS_QUERY_INVALID");
  }
  if (!/^SELECT\b/i.test(normalized) || normalized.includes(";")) {
    throw new GoogleAdsCliError(
      "GAQL must be one SELECT statement without a semicolon",
      "GOOGLE_ADS_QUERY_INVALID",
    );
  }
  const limits = findUnquotedLimits(normalized);
  if (limits.length > 1) {
    throw new GoogleAdsCliError("GAQL must contain at most one LIMIT", "GOOGLE_ADS_QUERY_INVALID");
  }
  if (limits.length === 1) {
    const limit = limits[0]?.value;
    if (!Number.isSafeInteger(limit) || limit < 1 || limit > MAX_QUERY_ROWS) {
      throw new GoogleAdsCliError(
        `GAQL LIMIT must be between 1 and ${MAX_QUERY_ROWS}`,
        "GOOGLE_ADS_QUERY_INVALID",
      );
    }
    return normalized;
  }
  return `${normalized} LIMIT ${MAX_QUERY_ROWS}`;
}

function parseCommand(argv: string[]): ParsedCommand {
  const [command, ...rest] = argv;
  if (command === "status") {
    rejectUnexpected(rest, new Set());
    return { command };
  }
  if (command === "accounts") {
    const flags = parseFlags(rest, new Set(["login-customer-id"]));
    return {
      command,
      loginCustomerId: flags["login-customer-id"],
    };
  }
  if (command === "report") {
    const flags = parseFlags(
      rest,
      new Set(["customer-id", "login-customer-id", "query", "page-token"]),
    );
    const customerId = requiredFlag(flags, "customer-id");
    const query = requiredFlag(flags, "query");
    return {
      command,
      customerId,
      loginCustomerId: flags["login-customer-id"],
      query,
      pageToken: flags["page-token"],
    };
  }
  throw new GoogleAdsCliError(
    "Usage: google_ads.ts status | accounts [--login-customer-id ID] | report --customer-id ID --query GAQL [--login-customer-id ID] [--page-token TOKEN]",
    "GOOGLE_ADS_USAGE",
  );
}

type DiscoveredCustomer = Record<string, unknown> & {
  customerId: string;
  manager: boolean | null;
  level: number | null;
};

async function discoverAccountHierarchy(
  runCommand: CommandRunner,
  timeoutMs: number,
  loginCustomerId: string,
): Promise<Record<string, unknown>> {
  // Google documents account hierarchy discovery as a breadth-first traversal:
  // query the selected manager and each directly linked sub-manager with
  // `customer_client.level <= 1`. A single query cannot return every nested
  // descendant. Keep this traversal bounded so a malformed or cyclic upstream
  // response cannot make one agent command run forever.
  const managerQueue: Array<{ customerId: string; depth: number }> = [
    { customerId: loginCustomerId, depth: 0 },
  ];
  const visitedManagers = new Set<string>();
  const discovered = new Map<string, Record<string, unknown>>();
  let truncated = false;
  let requestCount = 0;

  while (managerQueue.length > 0) {
    const current = managerQueue.shift()!;
    if (visitedManagers.has(current.customerId)) continue;
    if (visitedManagers.size >= MAX_HIERARCHY_MANAGERS) {
      truncated = true;
      break;
    }
    visitedManagers.add(current.customerId);

    let pageToken: string | undefined;
    const seenPageTokens = new Set<string>();
    do {
      if (requestCount >= MAX_HIERARCHY_REQUESTS) {
        truncated = true;
        break;
      }
      requestCount += 1;
      const body: Record<string, string> = { query: accountHierarchyQuery() };
      if (pageToken) body.pageToken = pageToken;
      const hierarchy = await requestGoogleAds(
        runCommand,
        timeoutMs,
        `customers/${current.customerId}/googleAds:search`,
        {
          method: "POST",
          loginCustomerId,
          body,
        },
      );

      for (const child of parseCustomerClients(hierarchy) as DiscoveredCustomer[]) {
        // The <= 1 query includes the selected manager at level 0. Only level-1
        // rows are direct children and are safe to add to the hierarchy.
        if (child.level !== 1 || child.customerId === current.customerId) continue;
        if (!discovered.has(child.customerId)) {
          discovered.set(child.customerId, {
            ...child,
            parentManagerCustomerId: current.customerId,
            hierarchyDepth: current.depth + 1,
          });
        }
        if (child.manager === true && !visitedManagers.has(child.customerId)) {
          managerQueue.push({ customerId: child.customerId, depth: current.depth + 1 });
        }
      }

      const nextPageToken = stringOrNull(asRecord(hierarchy).nextPageToken) ?? undefined;
      if (nextPageToken && seenPageTokens.has(nextPageToken)) {
        truncated = true;
        break;
      }
      if (nextPageToken) seenPageTokens.add(nextPageToken);
      pageToken = nextPageToken;
    } while (pageToken);

    if (requestCount >= MAX_HIERARCHY_REQUESTS) break;
  }

  const descendants = [...discovered.values()];
  return {
    managerCustomerId: loginCustomerId,
    immediateClients: descendants.filter((account) => account.hierarchyDepth === 1),
    descendants,
    direct: false,
    truncated,
    visitedManagerCount: visitedManagers.size,
    requestCount,
  };
}

function accountHierarchyQuery(): string {
  return [
    "SELECT customer_client.client_customer, customer_client.descriptive_name,",
    "customer_client.currency_code, customer_client.time_zone, customer_client.manager,",
    "customer_client.test_account, customer_client.level",
    "FROM customer_client WHERE customer_client.level <= 1 LIMIT 100",
  ].join(" ");
}

type GaqlLimit = { value: number };

/**
 * Find LIMIT clauses outside GAQL string literals.
 *
 * Google Ads filters commonly contain quoted user text, so a raw regex can
 * mistake `campaign.name = 'LIMIT 5'` for the result bound and leave the real
 * query unbounded. GAQL uses backslash escaping; accepting doubled quotes as
 * well keeps the scanner conservative for SQL-style strings produced by
 * agents. A real LIMIT keyword without one positive integer is rejected by
 * returning NaN, which the normal bound validation handles.
 */
function findUnquotedLimits(query: string): GaqlLimit[] {
  const limits: GaqlLimit[] = [];
  let quote: "'" | '"' | null = null;

  for (let index = 0; index < query.length; index += 1) {
    const character = query[index]!;

    if (quote) {
      if (character === "\\") {
        index += 1;
        continue;
      }
      if (character === quote) {
        if (query[index + 1] === quote) {
          index += 1;
        } else {
          quote = null;
        }
      }
      continue;
    }

    if (character === "'" || character === '"') {
      quote = character;
      continue;
    }

    if (query.slice(index, index + 5).toUpperCase() !== "LIMIT") continue;
    const previous = query[index - 1];
    const next = query[index + 5];
    if ((previous && /[A-Za-z0-9_]/.test(previous)) || (next && /[A-Za-z0-9_]/.test(next))) {
      continue;
    }

    let cursor = index + 5;
    while (cursor < query.length && /\s/.test(query[cursor]!)) cursor += 1;
    const digitsStart = cursor;
    while (cursor < query.length && /\d/.test(query[cursor]!)) cursor += 1;
    const digits = query.slice(digitsStart, cursor);
    const boundary = query[cursor];
    const validBoundary = !boundary || !/[A-Za-z0-9_]/.test(boundary);
    limits.push({ value: digits && validBoundary ? Number(digits) : Number.NaN });
    index = Math.max(index + 4, cursor - 1);
  }

  return limits;
}

function parseFlags(argv: string[], allowed: Set<string>): Record<string, string> {
  const flags: Record<string, string> = {};
  for (let index = 0; index < argv.length; index += 2) {
    const raw = argv[index];
    const value = argv[index + 1];
    if (!raw?.startsWith("--") || !value) {
      throw new GoogleAdsCliError("Every option requires a value", "GOOGLE_ADS_USAGE");
    }
    const name = raw.slice(2);
    if (!allowed.has(name)) {
      throw new GoogleAdsCliError(`Unsupported option: --${name}`, "GOOGLE_ADS_USAGE");
    }
    if (flags[name]) {
      throw new GoogleAdsCliError(`Duplicate option: --${name}`, "GOOGLE_ADS_USAGE");
    }
    flags[name] = value;
  }
  return flags;
}

function rejectUnexpected(argv: string[], allowed: Set<string>): void {
  if (argv.length > 0) parseFlags(argv, allowed);
}

function requiredFlag(flags: Record<string, string>, name: string): string {
  const value = flags[name];
  if (!value) throw new GoogleAdsCliError(`Missing --${name}`, "GOOGLE_ADS_USAGE");
  return value;
}

async function requestGoogleAds(
  runCommand: CommandRunner,
  timeoutMs: number,
  path: string,
  options: {
    method: "GET" | "POST";
    loginCustomerId?: string;
    body?: Record<string, string>;
  },
): Promise<unknown> {
  const argv = [
    "masterclaw",
    "integrations",
    "request",
    "--provider",
    "google-ads",
    "--method",
    options.method,
    "--path",
    path,
  ];
  if (options.loginCustomerId) {
    argv.push("--header", `login-customer-id:${options.loginCustomerId}`);
  }
  if (options.body) argv.push("--body", JSON.stringify(options.body));

  const response = parseIntegrationResponse(await runMasterclawJson(
    runCommand,
    timeoutMs,
    argv,
  ));
  if (!response.ok) {
    throw googleAdsResponseError(
      response.status,
      response.body,
      response.requestId ?? undefined,
    );
  }
  return response.body;
}

function googleAdsResponseError(
  status: number,
  payload: unknown,
  proxyRequestId?: string,
): GoogleAdsCliError {
  const record = asRecord(payload);
  const error = asRecord(record.error);
  const details = Array.isArray(error.details) ? error.details : [];
  let requestId: string | undefined = proxyRequestId;
  let code = typeof error.status === "string" ? error.status : "GOOGLE_ADS_REQUEST_FAILED";
  let message = typeof error.message === "string" ? error.message : "Google Ads request failed";

  for (const detail of details) {
    const detailRecord = asRecord(detail);
    if (typeof detailRecord.requestId === "string") requestId = detailRecord.requestId;
    const errors = Array.isArray(detailRecord.errors) ? detailRecord.errors : [];
    const first = asRecord(errors[0]);
    if (typeof first.message === "string") message = first.message;
    const errorCode = asRecord(first.errorCode);
    const specificCode = Object.values(errorCode).find((value) => typeof value === "string");
    if (typeof specificCode === "string") code = specificCode;
  }

  return new GoogleAdsCliError(message, code, status, requestId);
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
    throw new GoogleAdsCliError(
      "Chorus returned an invalid integration response",
      "GOOGLE_ADS_PROXY_INVALID",
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
    if (error instanceof GoogleAdsCliError) throw error;
    throw new GoogleAdsCliError(
      error instanceof Error ? error.message : "Masterclaw command failed",
      "GOOGLE_ADS_RUNTIME_ERROR",
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
      throw googleAdsResponseError(
        details.status,
        details.body,
        typeof details.requestId === "string" ? details.requestId : undefined,
      );
    }
    const message = typeof error.message === "string"
      ? error.message
      : "Masterclaw command failed";
    const code = typeof error.code === "string"
      ? error.code
      : "GOOGLE_ADS_RUNTIME_ERROR";
    throw new GoogleAdsCliError(message, code);
  }

  const payload = parseJson(result.stdout);
  if (payload === null) {
    throw new GoogleAdsCliError(
      "Masterclaw returned invalid JSON",
      "GOOGLE_ADS_RUNTIME_INVALID",
    );
  }
  return payload;
}

async function runProcess(argv: string[], timeoutMs: number): Promise<CommandResult> {
  const process = Bun.spawn(argv, {
    stdin: "ignore",
    stdout: "pipe",
    stderr: "pipe",
  });
  let timedOut = false;
  const timer = setTimeout(() => {
    timedOut = true;
    process.kill();
  }, timeoutMs);

  try {
    const [stdout, stderr, exitCode] = await Promise.all([
      new Response(process.stdout).text(),
      new Response(process.stderr).text(),
      process.exited,
    ]);
    if (timedOut) {
      throw new GoogleAdsCliError("Google Ads request timed out", "GOOGLE_ADS_TIMEOUT");
    }
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
    // The Masterclaw process starts an in-process Gateway relay before it runs
    // the command. Relay lifecycle messages currently share stdout with the
    // command's structured result, so a successful invocation can look like:
    //
    //   [relay] connecting ...
    //   [relay] gateway authenticated ...
    //   { "ok": true, ... }
    //
    // Only accept a complete JSON document at a line boundary after that
    // preamble. Parsing a complete suffix keeps arbitrary log fragments from
    // being mistaken for the command response.
    for (const match of text.matchAll(/(?:^|\n)(?=[ \t]*[\[{])/g)) {
      const candidate = text.slice((match.index ?? 0) + (match[0] === "\n" ? 1 : 0)).trim();
      try {
        return JSON.parse(candidate) as unknown;
      } catch {
        // Keep looking for the start of the final structured document.
      }
    }
    return null;
  }
}

function readResourceNames(payload: unknown): string[] {
  const names = asRecord(payload).resourceNames;
  if (!Array.isArray(names) || !names.every((name) => typeof name === "string")) {
    throw new GoogleAdsCliError(
      "Google Ads returned invalid account data",
      "GOOGLE_ADS_UPSTREAM_INVALID",
    );
  }
  return names;
}

function normalizeResourceName(resourceName: string): string {
  const match = /^customers\/(\d{10})$/.exec(resourceName);
  if (!match?.[1]) {
    throw new GoogleAdsCliError(
      "Google Ads returned an invalid customer resource",
      "GOOGLE_ADS_UPSTREAM_INVALID",
    );
  }
  return match[1];
}

function normalizeCustomerId(value: string, label: string): string {
  const normalized = value.replace(/-/g, "").trim();
  if (!/^\d{10}$/.test(normalized)) {
    throw new GoogleAdsCliError(`${label} must contain exactly 10 digits`, "GOOGLE_ADS_USAGE");
  }
  return normalized;
}

function parseCustomerClients(payload: unknown): Array<Record<string, unknown>> {
  const results = asRecord(payload).results;
  if (!Array.isArray(results)) return [];
  return results.flatMap((result) => {
    const customerClient = asRecord(asRecord(result).customerClient);
    const clientCustomer = customerClient.clientCustomer;
    if (typeof clientCustomer !== "string") return [];
    return [{
      customerId: normalizeResourceName(clientCustomer),
      descriptiveName: stringOrNull(customerClient.descriptiveName),
      currencyCode: stringOrNull(customerClient.currencyCode),
      timeZone: stringOrNull(customerClient.timeZone),
      manager: booleanOrNull(customerClient.manager),
      testAccount: booleanOrNull(customerClient.testAccount),
      level: numberOrNull(customerClient.level),
    }];
  });
}

function asRecord(value: unknown): Record<string, unknown> {
  return value && typeof value === "object" && !Array.isArray(value)
    ? value as Record<string, unknown>
    : {};
}

function stringOrNull(value: unknown): string | null {
  return typeof value === "string" ? value : null;
}

function booleanOrNull(value: unknown): boolean | null {
  return typeof value === "boolean" ? value : null;
}

function numberOrNull(value: unknown): number | null {
  if (typeof value === "number" && Number.isFinite(value)) return value;
  if (typeof value === "string" && /^\d+$/.test(value)) return Number(value);
  return null;
}

function stringArray(value: unknown): string[] {
  return Array.isArray(value)
    ? value.filter((item): item is string => typeof item === "string")
    : [];
}

function serializedError(error: unknown): Record<string, unknown> {
  if (error instanceof GoogleAdsCliError) {
    return {
      error: error.message,
      code: error.code,
      status: error.status ?? null,
      requestId: error.requestId ?? null,
    };
  }
  return { error: "Google Ads command failed", code: "GOOGLE_ADS_UNKNOWN_ERROR" };
}

if (import.meta.main) {
  runGoogleAdsCli(process.argv.slice(2))
    .then((result) => process.stdout.write(`${JSON.stringify(result, null, 2)}\n`))
    .catch((error) => {
      process.stderr.write(`${JSON.stringify(serializedError(error))}\n`);
      process.exitCode = 1;
    });
}

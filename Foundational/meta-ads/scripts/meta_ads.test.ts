import { describe, expect, test } from "bun:test";
import { runMetaAdsCli } from "./meta_ads";

type CapturedCommand = { argv: string[]; timeoutMs: number };
type MockResponse = { exitCode?: number; stdout?: unknown; stderr?: unknown };

function mockCommands(responses: MockResponse[]) {
  const calls: CapturedCommand[] = [];
  return {
    calls,
    runCommand: async (argv: string[], timeoutMs: number) => {
      const response = responses.shift();
      if (!response) throw new Error("Unexpected command");
      calls.push({ argv, timeoutMs });
      return {
        exitCode: response.exitCode ?? 0,
        stdout: serialize(response.stdout),
        stderr: serialize(response.stderr),
      };
    },
  };
}

function serialize(value: unknown): string {
  if (value === undefined) return "";
  return typeof value === "string" ? value : JSON.stringify(value);
}

function proxyResponse(body: unknown, options: { ok?: boolean; status?: number; requestId?: string } = {}) {
  return {
    stdout: {
      ok: options.ok ?? true,
      status: options.status ?? 200,
      body,
      requestId: options.requestId ?? "proxy-request-1",
    },
  };
}

function queryMap(argv: string[]): Record<string, string> {
  const result: Record<string, string> = {};
  argv.forEach((value, index) => {
    if (value !== "--query") return;
    const pair = argv[index + 1] ?? "";
    const separator = pair.indexOf(":");
    result[pair.slice(0, separator)] = pair.slice(separator + 1);
  });
  return result;
}

describe("meta ads skill CLI", () => {
  test("checks the agent-scoped Nango connection", async () => {
    const commands = mockCommands([{
      stdout: {
        ready: true,
        connectedProviderIds: ["meta-ads"],
        missingProviderIds: [],
        action: { type: "none" },
      },
    }]);

    await expect(runMetaAdsCli(["status"], commands)).resolves.toMatchObject({
      connected: true,
      provider: "meta-ads",
      mode: "read-only",
    });
    expect(commands.calls[0]).toEqual({
      argv: ["masterclaw", "connections", "check", "--provider", "meta-ads"],
      timeoutMs: 30_000,
    });
  });

  test("accepts structured output after Gateway relay logs", async () => {
    const commands = mockCommands([{
      stdout: [
        "[relay] connecting to gateway (attempt=1)",
        JSON.stringify({
          ready: false,
          connectedProviderIds: [],
          missingProviderIds: ["meta-ads"],
        }, null, 2),
      ].join("\n"),
    }]);

    await expect(runMetaAdsCli(["status"], commands)).resolves.toMatchObject({
      connected: false,
      provider: "meta-ads",
    });
  });

  test("lists accounts through the generic proxy and strips paging URLs", async () => {
    const commands = mockCommands([proxyResponse({
      data: [{ id: "act_123", name: "Launch", currency: "USD" }],
      paging: {
        cursors: { before: "before-secret", after: "next-page" },
        next: "https://graph.facebook.com/v25.0/me/adaccounts?access_token=never-expose",
      },
    })]);

    await expect(runMetaAdsCli(["accounts", "--after", "page-1"], commands)).resolves.toEqual({
      data: [{ id: "act_123", name: "Launch", currency: "USD" }],
      nextCursor: "next-page",
    });
    const argv = commands.calls[0]?.argv ?? [];
    expect(argv).toContain("me/adaccounts");
    expect(argv.join(" ")).not.toContain("access_token");
    expect(queryMap(argv)).toMatchObject({
      limit: "100",
      after: "page-1",
    });
    expect(queryMap(argv).fields).not.toContain("business");
  });

  test("lists campaign objects with a normalized ad account selector", async () => {
    const commands = mockCommands([proxyResponse({ data: [{ id: "campaign-1" }] })]);

    await expect(runMetaAdsCli([
      "campaigns",
      "--account-id",
      "123456789",
    ], commands)).resolves.toEqual({
      data: [{ id: "campaign-1" }],
      nextCursor: null,
      accountId: "act_123456789",
    });
    expect(commands.calls[0]?.argv).toContain("act_123456789/campaigns");
  });

  test("discovers Business Portfolios and bounded owned accounts", async () => {
    const businesses = mockCommands([proxyResponse({ data: [{ id: "987", name: "Chorus" }] })]);
    await runMetaAdsCli(["businesses"], businesses);
    expect(businesses.calls[0]?.argv).toContain("me/businesses");
    expect(queryMap(businesses.calls[0]?.argv ?? []).fields).toContain("verification_status");

    const accounts = mockCommands([proxyResponse({ data: [{ id: "act_123" }] })]);
    await runMetaAdsCli([
      "business-accounts",
      "--business-id",
      "987",
      "--relationship",
      "owned",
    ], accounts);
    expect(accounts.calls[0]?.argv).toContain("987/owned_ad_accounts");
    expect(queryMap(accounts.calls[0]?.argv ?? []).limit).toBe("100");
  });

  test("runs a bounded last-30-day campaign insights report", async () => {
    const commands = mockCommands([proxyResponse({
      data: [{ campaign_id: "7", spend: "25.00", actions: [] }],
      paging: { cursors: { after: "insights-page-2" } },
    })]);

    const result = await runMetaAdsCli([
      "insights",
      "--account-id",
      "act_123456789",
      "--level",
      "campaign",
      "--date-preset",
      "last_30d",
    ], commands);

    expect(result).toMatchObject({ accountId: "act_123456789", nextCursor: "insights-page-2" });
    const argv = commands.calls[0]?.argv ?? [];
    expect(argv).toContain("act_123456789/insights");
    expect(queryMap(argv)).toMatchObject({
      limit: "100",
      level: "campaign",
      date_preset: "last_30d",
    });
    expect(queryMap(argv).fields).toContain("cost_per_action_type");
  });

  test("serializes a validated custom date range", async () => {
    const commands = mockCommands([proxyResponse({ data: [] })]);
    await runMetaAdsCli([
      "insights",
      "--account-id",
      "act_123",
      "--level",
      "adset",
      "--since",
      "2026-06-15",
      "--until",
      "2026-07-13",
      "--after",
      "next",
    ], commands);

    expect(queryMap(commands.calls[0]?.argv ?? [])).toMatchObject({
      level: "adset",
      time_range: '{"since":"2026-06-15","until":"2026-07-13"}',
      after: "next",
    });
  });

  test("rejects invalid or unbounded insight inputs before proxy access", async () => {
    for (const argv of [
      ["insights", "--account-id", "act_123"],
      ["insights", "--account-id", "act_123", "--date-preset", "all_time"],
      ["insights", "--account-id", "act_123", "--date-preset", "last_30d", "--since", "2026-07-01", "--until", "2026-07-13"],
      ["insights", "--account-id", "act_123", "--since", "2026-01-01", "--until", "2026-07-13"],
      ["insights", "--account-id", "act_123", "--level", "creative", "--date-preset", "last_30d"],
    ]) {
      await expect(runMetaAdsCli(argv, mockCommands([]))).rejects.toMatchObject({
        code: "META_ADS_USAGE",
      });
    }
  });

  test("does not accept credential or transport options", async () => {
    await expect(runMetaAdsCli(
      ["accounts", "--access-token", "nope"],
      mockCommands([]),
    )).rejects.toMatchObject({ code: "META_ADS_USAGE" });
  });

  test("preserves structured Meta errors without token material", async () => {
    const commands = mockCommands([{
      exitCode: 1,
      stderr: {
        error: {
          code: "INTEGRATION_REQUEST_FAILED",
          message: "Meta rejected the request",
          details: {
            status: 400,
            requestId: "proxy-400",
            body: {
              error: {
                message: "The access token has expired",
                type: "OAuthException",
                code: 190,
                error_subcode: 463,
                fbtrace_id: "meta-trace-1",
              },
            },
          },
        },
      },
    }]);

    await expect(runMetaAdsCli(["accounts"], commands)).rejects.toMatchObject({
      message: "The access token has expired",
      code: "META_190_463",
      status: 400,
      requestId: "meta-trace-1",
    });
  });

  test("preserves pretty-printed Meta errors surrounded by relay lifecycle logs", async () => {
    const payload = {
      error: {
        code: "INTEGRATION_REQUEST_FAILED",
        message: "Meta rejected the request",
        details: {
          status: 400,
          body: {
            error: {
              message: "Requires business_management permission to access the field.",
              type: "OAuthException",
              code: 100,
              fbtrace_id: "meta-trace-2",
            },
          },
        },
      },
    };
    const commands = mockCommands([{
      exitCode: 1,
      stdout: [
        "[relay] connecting to gateway (attempt=1)",
        JSON.stringify(payload, null, 2),
        "[relay] gateway WS closed code=1000 reason=none",
      ].join("\n"),
      stderr: 'error: script "start" exited with code 1',
    }]);

    await expect(runMetaAdsCli(["accounts"], commands)).rejects.toMatchObject({
      message: "Requires business_management permission to access the field.",
      code: "OAuthException",
      status: 400,
      requestId: "meta-trace-2",
    });
  });
});

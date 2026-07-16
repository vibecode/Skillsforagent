import { describe, expect, test } from "bun:test";
import { mkdtemp, rm } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { runMetaAdsCli } from "./meta_ads";

type CapturedCommand = { argv: string[]; timeoutMs: number };
type MockResponse = { exitCode?: number; stdout?: unknown; stderr?: unknown };
const BACKEND_PLAN_ID = "123e4567-e89b-42d3-a456-426614174000";

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

function validationProxyResponse(body: Record<string, unknown> = { success: true }) {
  return proxyResponse({
    ...body,
    chorusMutationPlanId: BACKEND_PLAN_ID,
    chorusApprovalUrl: `https://chorus.com/a/${BACKEND_PLAN_ID}`,
  });
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

function requestBody(argv: string[]): Record<string, unknown> {
  const index = argv.indexOf("--body");
  return JSON.parse(argv[index + 1] ?? "{}") as Record<string, unknown>;
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
      mode: "campaign-management",
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

  test("validates, stores, and applies an immutable paused campaign plan", async () => {
    const planDir = await mkdtemp(join(tmpdir(), "meta-ads-plans-"));
    try {
      const validateCommands = mockCommands([validationProxyResponse()]);
      const planned = await runMetaAdsCli([
        "campaign-plan-create",
        "--account-id", "123456789",
        "--name", "Launch campaign",
        "--objective", "OUTCOME_TRAFFIC",
        "--special-ad-categories", "NONE",
        "--daily-budget", "5000",
      ], {
        ...validateCommands,
        planDir,
        now: () => new Date("2026-07-16T12:00:00.000Z"),
      }) as { plan: { planId: string }; approvalPhrase: string; approvalUrl: string };

      expect(planned.plan.planId).toMatch(/^[a-f0-9]{24}$/);
      expect(planned.plan).not.toHaveProperty("backendPlanId");
      expect(planned.approvalPhrase).toBe(`Approve Meta Ads plan ${planned.plan.planId}`);
      expect(planned.approvalUrl).toBe(`https://chorus.com/a/${BACKEND_PLAN_ID}`);
      const validationArgv = validateCommands.calls[0]?.argv ?? [];
      expect(validationArgv).toContain("POST");
      expect(validationArgv).toContain("act_123456789/campaigns");
      expect(requestBody(validationArgv)).toMatchObject({
        name: "Launch campaign",
        objective: "OUTCOME_TRAFFIC",
        status: "PAUSED",
        daily_budget: "5000",
        execution_options: ["validate_only"],
      });

      const applyCommands = mockCommands([proxyResponse({ id: "987654321" })]);
      await expect(runMetaAdsCli([
        "campaign-apply",
        "--plan-id", planned.plan.planId,
        "--confirm", planned.plan.planId,
      ], {
        ...applyCommands,
        planDir,
        now: () => new Date("2026-07-16T12:05:00.000Z"),
      })).resolves.toMatchObject({
        applied: true,
        planId: planned.plan.planId,
        operation: "create-campaign",
        response: { id: "987654321" },
      });
      expect(requestBody(applyCommands.calls[0]?.argv ?? [])).not.toHaveProperty("execution_options");
      expect(applyCommands.calls[0]?.argv).toContain(`x-chorus-mutation-plan-id:${BACKEND_PLAN_ID}`);

      await expect(runMetaAdsCli([
        "campaign-apply",
        "--plan-id", planned.plan.planId,
        "--confirm", planned.plan.planId,
      ], { ...mockCommands([]), planDir })).rejects.toMatchObject({
        code: "META_ADS_PLAN_NOT_FOUND",
      });
    } finally {
      await rm(planDir, { recursive: true, force: true });
    }
  });

  test("plans activation and budget changes without mutating during validation", async () => {
    const planDir = await mkdtemp(join(tmpdir(), "meta-ads-plans-"));
    try {
      const commands = mockCommands([validationProxyResponse()]);
      await runMetaAdsCli([
        "campaign-plan-update",
        "--campaign-id", "987654321",
        "--status", "ACTIVE",
        "--daily-budget", "7500",
      ], { ...commands, planDir });
      expect(commands.calls[0]?.argv).toContain("987654321");
      expect(requestBody(commands.calls[0]?.argv ?? [])).toEqual({
        status: "ACTIVE",
        daily_budget: "7500",
        execution_options: ["validate_only"],
      });
    } finally {
      await rm(planDir, { recursive: true, force: true });
    }
  });

  test("rejects missing or insecure approval links before storing a plan", async () => {
    const planDir = await mkdtemp(join(tmpdir(), "meta-ads-plans-"));
    const argv = [
      "campaign-plan-update",
      "--campaign-id", "987654321",
      "--status", "PAUSED",
    ];
    try {
      const missing = proxyResponse({ chorusMutationPlanId: BACKEND_PLAN_ID });
      await expect(runMetaAdsCli(argv, { ...mockCommands([missing]), planDir }))
        .rejects.toMatchObject({ code: "META_ADS_APPROVAL_NOT_ISSUED" });

      const insecure = proxyResponse({
        chorusMutationPlanId: BACKEND_PLAN_ID,
        chorusApprovalUrl: `http://chorus.example/a/${BACKEND_PLAN_ID}`,
      });
      await expect(runMetaAdsCli(argv, { ...mockCommands([insecure]), planDir }))
        .rejects.toMatchObject({ code: "META_ADS_APPROVAL_NOT_ISSUED" });
    } finally {
      await rm(planDir, { recursive: true, force: true });
    }
  });

  test("reuses an identical plan when the deterministic plan file already exists", async () => {
    const planDir = await mkdtemp(join(tmpdir(), "meta-ads-plans-"));
    const argv = [
      "campaign-plan-create",
      "--account-id", "123456789",
      "--name", "Collision-safe plan",
      "--objective", "OUTCOME_TRAFFIC",
      "--special-ad-categories", "NONE",
    ];
    const now = () => new Date("2026-07-16T12:00:00.000Z");
    try {
      const first = await runMetaAdsCli(argv, {
        ...mockCommands([validationProxyResponse()]), planDir, now,
      }) as { plan: { planId: string } };
      const second = await runMetaAdsCli(argv, {
        ...mockCommands([validationProxyResponse()]), planDir, now,
      }) as { plan: { planId: string } };
      expect(second.plan.planId).toBe(first.plan.planId);
    } finally {
      await rm(planDir, { recursive: true, force: true });
    }
  });

  test("atomically claims a plan so concurrent apply cannot replay it", async () => {
    const planDir = await mkdtemp(join(tmpdir(), "meta-ads-plans-"));
    try {
      const planned = await runMetaAdsCli([
        "campaign-plan-update",
        "--campaign-id", "987654321",
        "--status", "PAUSED",
      ], {
        ...mockCommands([validationProxyResponse()]), planDir,
      }) as { plan: { planId: string } };
      let releaseMutation!: () => void;
      let signalStarted!: () => void;
      const mutationStarted = new Promise<void>((resolve) => { signalStarted = resolve; });
      const mutationReleased = new Promise<void>((resolve) => { releaseMutation = resolve; });
      const firstApply = runMetaAdsCli([
        "campaign-apply", "--plan-id", planned.plan.planId, "--confirm", planned.plan.planId,
      ], {
        planDir,
        runCommand: async () => {
          signalStarted();
          await mutationReleased;
          return { exitCode: 0, stdout: serialize(proxyResponse({ success: true }).stdout), stderr: "" };
        },
      });
      await mutationStarted;
      await expect(runMetaAdsCli([
        "campaign-apply", "--plan-id", planned.plan.planId, "--confirm", planned.plan.planId,
      ], { ...mockCommands([]), planDir })).rejects.toMatchObject({
        code: "META_ADS_PLAN_NOT_FOUND",
      });
      releaseMutation();
      await expect(firstApply).resolves.toMatchObject({ applied: true });
    } finally {
      await rm(planDir, { recursive: true, force: true });
    }
  });

  test("restores a claimed plan when Meta rejects the mutation", async () => {
    const planDir = await mkdtemp(join(tmpdir(), "meta-ads-plans-"));
    try {
      const planned = await runMetaAdsCli([
        "campaign-plan-update",
        "--campaign-id", "987654321",
        "--status", "PAUSED",
      ], {
        ...mockCommands([validationProxyResponse()]), planDir,
      }) as { plan: { planId: string } };
      const failed = mockCommands([proxyResponse(
        { error: { message: "Temporary Meta failure", code: 2 } },
        { ok: false, status: 500 },
      )]);
      await expect(runMetaAdsCli([
        "campaign-apply", "--plan-id", planned.plan.planId, "--confirm", planned.plan.planId,
      ], { ...failed, planDir })).rejects.toMatchObject({ message: "Temporary Meta failure" });

      const retry = mockCommands([proxyResponse({ success: true })]);
      await expect(runMetaAdsCli([
        "campaign-apply", "--plan-id", planned.plan.planId, "--confirm", planned.plan.planId,
      ], { ...retry, planDir })).resolves.toMatchObject({ applied: true });
    } finally {
      await rm(planDir, { recursive: true, force: true });
    }
  });

  test("does not restore a plan when the mutation outcome is ambiguous", async () => {
    const planDir = await mkdtemp(join(tmpdir(), "meta-ads-plans-"));
    try {
      const planned = await runMetaAdsCli([
        "campaign-plan-update",
        "--campaign-id", "987654321",
        "--status", "PAUSED",
      ], {
        ...mockCommands([validationProxyResponse()]), planDir,
      }) as { plan: { planId: string } };
      const ambiguous = mockCommands([{
        exitCode: 1,
        stderr: {
          error: {
            code: "INTEGRATION_PROXY_UPSTREAM_ERROR",
            message: "Provider response failed",
          },
        },
      }]);
      await expect(runMetaAdsCli([
        "campaign-apply", "--plan-id", planned.plan.planId, "--confirm", planned.plan.planId,
      ], { ...ambiguous, planDir })).rejects.toMatchObject({
        code: "META_ADS_MUTATION_OUTCOME_UNKNOWN",
      });
      await expect(runMetaAdsCli([
        "campaign-apply", "--plan-id", planned.plan.planId, "--confirm", planned.plan.planId,
      ], { ...mockCommands([]), planDir })).rejects.toMatchObject({
        code: "META_ADS_PLAN_NOT_FOUND",
      });
    } finally {
      await rm(planDir, { recursive: true, force: true });
    }
  });

  test("requires the exact plan id as apply confirmation", async () => {
    await expect(runMetaAdsCli([
      "campaign-apply",
      "--plan-id", "0123456789abcdef01234567",
      "--confirm", "wrong",
    ], mockCommands([]))).rejects.toMatchObject({ code: "META_ADS_USAGE" });
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

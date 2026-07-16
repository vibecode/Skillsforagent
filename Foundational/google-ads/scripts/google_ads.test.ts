import { describe, expect, test } from "bun:test";
import { boundedGaql, GoogleAdsCliError, runGoogleAdsCli } from "./google_ads";

type CapturedCommand = {
  argv: string[];
  timeoutMs: number;
};

type MockResponse = {
  exitCode?: number;
  stdout?: unknown;
  stderr?: unknown;
};

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
        stdout: response.stdout === undefined
          ? ""
          : typeof response.stdout === "string"
            ? response.stdout
            : JSON.stringify(response.stdout),
        stderr: response.stderr === undefined
          ? ""
          : typeof response.stderr === "string"
            ? response.stderr
            : JSON.stringify(response.stderr),
      };
    },
  };
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

describe("google ads skill CLI", () => {
  test("checks the agent-scoped Nango connection through Masterclaw", async () => {
    const commands = mockCommands([{
      stdout: {
        ready: true,
        requirements: [],
        connectedProviderIds: ["google-ads"],
        missingProviderIds: [],
        unresolvedProviderIds: [],
        unresolvedSkillKeys: [],
        action: { type: "none" },
      },
    }]);
    const result = await runGoogleAdsCli(["status"], commands);

    expect(result).toMatchObject({
      connected: true,
      provider: "google-ads",
      mode: "read-only",
    });
    expect(commands.calls).toEqual([{
      argv: ["masterclaw", "connections", "check", "--provider", "google-ads"],
      timeoutMs: 30_000,
    }]);
  });

  test("accepts Masterclaw JSON after relay lifecycle logs", async () => {
    const commands = mockCommands([{
      stdout: [
        "[relay] connecting to gateway (attempt=1)",
        "[relay] gateway authenticated — ready (attempt=1 closeCount=0)",
        JSON.stringify({
          ready: true,
          connectedProviderIds: ["google-ads"],
          missingProviderIds: [],
          action: { type: "none" },
        }, null, 2),
      ].join("\n"),
    }]);

    await expect(runGoogleAdsCli(["status"], commands)).resolves.toMatchObject({
      connected: true,
      provider: "google-ads",
    });
  });

  test("reports a missing connection without reading runtime credentials", async () => {
    const commands = mockCommands([{
      stdout: {
        ready: false,
        connectedProviderIds: [],
        missingProviderIds: ["google-ads"],
        action: { type: "open_connections", providerIds: ["google-ads"] },
      },
    }]);

    await expect(runGoogleAdsCli(["status"], commands)).resolves.toMatchObject({
      connected: false,
      provider: "google-ads",
    });
  });

  test("lists directly accessible accounts through the generic integration proxy", async () => {
    const commands = mockCommands([
      proxyResponse({ resourceNames: ["customers/1234567890"] }),
    ]);
    const result = await runGoogleAdsCli(["accounts"], commands);

    expect(result).toEqual({ accounts: [{ customerId: "1234567890" }], direct: true });
    expect(commands.calls[0]?.argv).toEqual([
      "masterclaw",
      "integrations",
      "request",
      "--provider",
      "google-ads",
      "--method",
      "GET",
      "--path",
      "customers:listAccessibleCustomers",
    ]);
  });

  test("discovers nested manager accounts with bounded breadth-first traversal", async () => {
    const commands = mockCommands([
      proxyResponse({ resourceNames: ["customers/1234567890"] }),
      proxyResponse({
        results: [
          {
            customerClient: {
              clientCustomer: "customers/1234567890",
              descriptiveName: "Root manager",
              manager: true,
              level: "0",
            },
          },
          {
            customerClient: {
              clientCustomer: "customers/3334445555",
              descriptiveName: "Direct client",
              manager: false,
              level: "1",
            },
          },
        ],
        nextPageToken: "root-page-2",
      }),
      proxyResponse({
        results: [{
          customerClient: {
            clientCustomer: "customers/2223334444",
            descriptiveName: "Nested manager",
            currencyCode: "USD",
            timeZone: "America/New_York",
            manager: true,
            testAccount: false,
            level: "1",
          },
        }],
      }),
      proxyResponse({
        results: [
          {
            customerClient: {
              clientCustomer: "customers/2223334444",
              descriptiveName: "Nested manager",
              manager: true,
              level: "0",
            },
          },
          {
            customerClient: {
              clientCustomer: "customers/4445556666",
              descriptiveName: "Nested client",
              manager: false,
              level: "1",
            },
          },
        ],
      }),
    ]);

    const result = await runGoogleAdsCli([
      "accounts",
      "--login-customer-id",
      "123-456-7890",
    ], commands);

    expect(result).toMatchObject({
      managerCustomerId: "1234567890",
      direct: false,
      truncated: false,
      visitedManagerCount: 2,
      requestCount: 3,
      immediateClients: [expect.objectContaining({
        customerId: "3334445555",
        hierarchyDepth: 1,
      }), {
        customerId: "2223334444",
        descriptiveName: "Nested manager",
        currencyCode: "USD",
        timeZone: "America/New_York",
        manager: true,
        testAccount: false,
        level: 1,
        parentManagerCustomerId: "1234567890",
        hierarchyDepth: 1,
      }],
      descendants: [
        expect.objectContaining({ customerId: "3334445555", hierarchyDepth: 1 }),
        expect.objectContaining({ customerId: "2223334444", hierarchyDepth: 1 }),
        expect.objectContaining({
          customerId: "4445556666",
          parentManagerCustomerId: "2223334444",
          hierarchyDepth: 2,
        }),
      ],
    });
    expect(commands.calls).toHaveLength(4);
    for (const managerArgv of commands.calls.slice(1).map((call) => call.argv)) {
      expect(managerArgv).toContain("login-customer-id:1234567890");
      const body = JSON.parse(managerArgv[managerArgv.indexOf("--body") + 1] ?? "{}") as {
        query?: string;
      };
      expect(body.query).toContain("FROM customer_client");
      expect(body.query).toContain("customer_client.level <= 1");
    }
    const secondPageBody = JSON.parse(
      commands.calls[2]?.argv[(commands.calls[2]?.argv.indexOf("--body") ?? -1) + 1] ?? "{}",
    ) as { pageToken?: string };
    expect(secondPageBody.pageToken).toBe("root-page-2");
    expect(commands.calls[3]?.argv).toContain("customers/2223334444/googleAds:search");
  });

  test("rejects manual pagination for recursively discovered accounts", async () => {
    await expect(runGoogleAdsCli(
      ["accounts", "--login-customer-id", "1234567890", "--page-token", "orphan-page"],
      mockCommands([]),
    )).rejects.toMatchObject({ code: "GOOGLE_ADS_USAGE" });
  });

  test("marks a hierarchy partial when Google repeats a pagination token", async () => {
    const commands = mockCommands([
      proxyResponse({ resourceNames: ["customers/1234567890"] }),
      proxyResponse({ results: [], nextPageToken: "more-results" }),
      proxyResponse({ results: [], nextPageToken: "more-results" }),
    ]);

    await expect(runGoogleAdsCli([
      "accounts",
      "--login-customer-id",
      "1234567890",
    ], commands)).resolves.toMatchObject({ truncated: true });
  });

  test("rejects a manager that is not directly accessible", async () => {
    const commands = mockCommands([
      proxyResponse({ resourceNames: ["customers/9999999999"] }),
    ]);
    await expect(runGoogleAdsCli(
      ["accounts", "--login-customer-id", "1234567890"],
      commands,
    )).rejects.toMatchObject({ code: "GOOGLE_ADS_MANAGER_NOT_ACCESSIBLE" });
    expect(commands.calls).toHaveLength(1);
  });

  test("runs a bounded report with normalized customer selectors", async () => {
    const commands = mockCommands([
      proxyResponse({ results: [{ campaign: { id: "7" } }], nextPageToken: "next" }),
    ]);
    const result = await runGoogleAdsCli([
      "report",
      "--customer-id",
      "222-333-4444",
      "--login-customer-id",
      "123-456-7890",
      "--query",
      "SELECT campaign.id FROM campaign",
      "--page-token",
      "page-1",
    ], commands);

    expect(result).toMatchObject({
      customerId: "2223334444",
      loginCustomerId: "1234567890",
      nextPageToken: "next",
    });
    const argv = commands.calls[0]?.argv ?? [];
    expect(argv).toContain("login-customer-id:1234567890");
    expect(argv).not.toContain("Bearer");
    const body = JSON.parse(argv[argv.indexOf("--body") + 1] ?? "{}") as unknown;
    expect(body).toEqual({
      query: "SELECT campaign.id FROM campaign LIMIT 100",
      pageToken: "page-1",
    });
  });

  test("bounds GAQL and rejects mutation-shaped or excessive queries", () => {
    expect(boundedGaql("SELECT campaign.id FROM campaign")).toEndWith("LIMIT 100");
    expect(boundedGaql("SELECT campaign.id FROM campaign LIMIT 25")).toEndWith("LIMIT 25");
    expect(() => boundedGaql("UPDATE campaign SET name = 'x'")).toThrow(GoogleAdsCliError);
    expect(() => boundedGaql("SELECT campaign.id FROM campaign;")).toThrow(GoogleAdsCliError);
    expect(() => boundedGaql("SELECT campaign.id FROM campaign LIMIT 101")).toThrow(
      /between 1 and 100/,
    );
    expect(() => boundedGaql("SELECT campaign.id FROM campaign LIMIT 1 LIMIT 2")).toThrow(
      /at most one LIMIT/,
    );
    expect(() => boundedGaql(`SELECT ${"x".repeat(10_000)}`)).toThrow(
      /length is invalid/,
    );
  });

  test("ignores LIMIT text inside quoted GAQL values", () => {
    expect(boundedGaql(
      "SELECT campaign.id FROM campaign WHERE campaign.name = 'LIMIT 7'",
    )).toEndWith("LIMIT 100");
    expect(boundedGaql(
      "SELECT campaign.id FROM campaign WHERE campaign.name = 'launch \\'LIMIT 8\\''",
    )).toEndWith("LIMIT 100");
    expect(boundedGaql(
      "SELECT campaign.id FROM campaign WHERE campaign.name = 'launch ''LIMIT 9'''",
    )).toEndWith("LIMIT 100");
  });

  test("counts only real LIMIT clauses when quoted text also contains LIMIT", () => {
    expect(boundedGaql(
      "SELECT campaign.id FROM campaign WHERE campaign.name = 'LIMIT 99' LIMIT 25",
    )).toEndWith("LIMIT 25");
    expect(() => boundedGaql(
      "SELECT campaign.id FROM campaign WHERE campaign.name = 'LIMIT 99' LIMIT 10 LIMIT 20",
    )).toThrow(/at most one LIMIT/);
  });

  test("does not accept transport or credential-like command-line options", async () => {
    await expect(runGoogleAdsCli(
      ["accounts", "--authorization", "do-not-accept"],
      mockCommands([]),
    )).rejects.toMatchObject({ code: "GOOGLE_ADS_USAGE" });
  });

  test("preserves Google errors from a failed integration command", async () => {
    const googleError = {
      error: {
        status: "PERMISSION_DENIED",
        message: "Google Ads rejected the request",
        details: [{
          requestId: "google-request-123",
          errors: [{
            errorCode: { authorizationError: "ACCOUNT_INACTIVE" },
            message: "The Google Ads account is inactive",
          }],
        }],
      },
    };
    const commands = mockCommands([{
      exitCode: 1,
      stderr: {
        error: {
          code: "INTEGRATION_REQUEST_FAILED",
          status: 403,
          message: "Google Ads rejected the request",
          details: {
            provider: "google-ads",
            status: 403,
            body: googleError,
            requestId: "proxy-request-403",
          },
        },
      },
    }]);

    await expect(runGoogleAdsCli(["accounts"], commands)).rejects.toMatchObject({
      code: "ACCOUNT_INACTIVE",
      status: 403,
      requestId: "google-request-123",
      message: "The Google Ads account is inactive",
    });
  });

  test("uses the proxy request ID when Google does not return one", async () => {
    const commands = mockCommands([
      proxyResponse({ error: { status: "PERMISSION_DENIED", message: "Rejected" } }, {
        ok: false,
        status: 403,
        requestId: "proxy-request-403",
      }),
    ]);

    await expect(runGoogleAdsCli(["accounts"], commands)).rejects.toMatchObject({
      code: "PERMISSION_DENIED",
      status: 403,
      requestId: "proxy-request-403",
    });
  });

  test("surfaces structured Masterclaw command failures", async () => {
    const commands = mockCommands([{
      exitCode: 1,
      stderr: { error: { code: "CONNECTION_REQUIRED", message: "Connect Google Ads first" } },
    }]);

    await expect(runGoogleAdsCli(["accounts"], commands)).rejects.toMatchObject({
      code: "CONNECTION_REQUIRED",
      message: "Connect Google Ads first",
    });
  });

  test("rejects malformed proxy output", async () => {
    const commands = mockCommands([{ stdout: { status: 200, body: {} } }]);
    await expect(runGoogleAdsCli(["accounts"], commands)).rejects.toMatchObject({
      code: "GOOGLE_ADS_PROXY_INVALID",
    });
  });
});

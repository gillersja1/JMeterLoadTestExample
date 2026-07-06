# JMeter Load Test Example

A sample load test project using [Apache JMeter](https://jmeter.apache.org/),
demonstrating a parameterized thread group, HTTP request defaults, header
management, response assertions, and CLI-driven execution with an HTML
dashboard report — plus a CI workflow to run it on demand.

## What's being tested

The test plan (`test-plans/reqres-api-load-test.jmx`) targets the public
[reqres.in](https://reqres.in/) test API with two requests per loop:

1. `GET /api/users?page=2` — list users
2. `GET /api/users/2` — fetch a single user, with a JSON path assertion
   checking that an `email` field is present

Both requests assert an HTTP 200 response. A configurable think time sits
between them to more realistically simulate user pacing.

> **Be a good citizen with shared public APIs.** reqres.in is a free,
> shared test service — keep the load light (the defaults here are modest)
> and don't hammer it. For real load testing, point this test plan at your
> own staging/test environment by changing the `BASE_DOMAIN` user-defined
> variable in the Test Plan element.

## Project structure

```
JMeterLoadTestExample/
├── test-plans/
│   └── reqres-api-load-test.jmx   # The JMeter test plan
├── scripts/
│   └── run-load-test.sh           # CLI runner + HTML report generation
├── .github/workflows/load-test.yml
└── results/, reports/             # Generated at runtime (gitignored)
```

## Prerequisites

- Java 8+ (JMeter runs on the JVM)
- [Apache JMeter](https://jmeter.apache.org/download_jmeter.cgi) 5.6.x, with its `bin/` directory on your `PATH`

## Running locally

**Option 1 — CLI (recommended for actual load generation):**

```bash
./scripts/run-load-test.sh                # defaults: 10 threads, 10s ramp-up, 5 loops
./scripts/run-load-test.sh 50 20 10        # 50 threads, 20s ramp-up, 10 loops each
```

This runs JMeter in non-GUI mode, writes raw results to `results/`, and
generates an HTML dashboard report at `reports/<timestamp>/index.html`.

**Option 2 — GUI (for building/debugging the test plan):**

```bash
jmeter -t test-plans/reqres-api-load-test.jmx
```

> Apache JMeter's own documentation recommends **against** using GUI mode
> to actually generate load — it consumes far more resources than CLI mode
> and can skew your results. Use the GUI for authoring and debugging only.

## How parameterization works

The thread group's user count, ramp-up time, and loop count are driven by
JMeter properties rather than hardcoded values:

```
${__P(threads,10)}       <!-- number of virtual users, default 10 -->
${__P(rampup,10)}        <!-- ramp-up period in seconds, default 10 -->
${__P(loops,5)}          <!-- loop count per user, default 5 -->
${__P(thinkTimeMs,300)}  <!-- pause between requests, default 300ms -->
```

Override any of them from the command line with `-J`:

```bash
jmeter -n -t test-plans/reqres-api-load-test.jmx -l results.jtl \
  -Jthreads=100 -Jrampup=30 -Jloops=20 -JthinkTimeMs=500
```

## CI/CD

`.github/workflows/load-test.yml` runs the load test:

- Automatically on pushes to `main` that touch the test plan
- On demand via **Actions → JMeter Load Test → Run workflow**, with
  `threads`, `rampup`, and `loops` as configurable inputs

It downloads and caches JMeter, runs the test in CLI mode, and uploads both
the raw `.jtl` results and the generated HTML report as build artifacts.

## Possible extensions

- Add a CSV Data Set Config element to drive requests with data-driven parameters
- Add pass/fail thresholds (e.g. via the `jmeter-maven-plugin` or a script that parses the `.jtl` for error rate / p95 latency and fails the CI job if exceeded)
- Add a Backend Listener to stream real-time metrics to InfluxDB + Grafana
- Add distributed/remote testing across multiple JMeter load-generation nodes for higher throughput
- Swap in [Taurus](https://gettaurus.org/) as a higher-level wrapper around this same `.jmx` file for cleaner CI configuration

import { Request, Response, NextFunction } from "express";
import client from "prom-client";

const collectDefaultMetrics = client.collectDefaultMetrics;
collectDefaultMetrics();

const httpRequestsTotal = new client.Counter({
  name: "flash_sales_http_requests_total",
  help: "Total number of completed HTTP requests",
  labelNames: ["method", "route", "status_code"],
});

const httpRequestDurationMilliseconds = new client.Histogram({
  name: "http_request_duration_ms",
  help: "Duration of HTTP requests in ms",
  labelNames: ["method", "route", "status_code"],
  buckets: [10, 50, 100, 300, 500, 1000, 2000, 5000],
});

function getRouteLabel(req: Request): string {
  return typeof req.route?.path === "string" ? req.route.path : "unmatched";
}

export function requestMetrics(
  req: Request,
  res: Response,
  next: NextFunction,
) {
  const start = process.hrtime.bigint();

  res.on("finish", () => {
    const durationMilliseconds =
      Number(process.hrtime.bigint() - start) / 1_000_000;
    const labels = {
      method: req.method,
      route: getRouteLabel(req),
      status_code: res.statusCode.toString(),
    };

    httpRequestsTotal.labels(labels).inc();
    httpRequestDurationMilliseconds
      .labels(labels)
      .observe(durationMilliseconds);
  });

  next();
}

export async function metricsController(req: Request, res: Response) {
  res.set("Content-Type", client.register.contentType);
  const metrics = await client.register.metrics();
  res.end(metrics);
}

import { EventEmitter } from "node:events";
import { Request, Response } from "express";
import client from "prom-client";
import { requestMetrics } from "../../src/middlewares/metricsMiddleware";

describe("requestMetrics", () => {
  beforeEach(() => {
    client.register.resetMetrics();
  });

  it("records request metrics using the route template", async () => {
    const req = {
      method: "GET",
      route: { path: "/orders/:orderId" },
      path: "/orders/unique-order-id",
    } as Request;
    const res = Object.assign(new EventEmitter(), {
      statusCode: 200,
    }) as Response;
    const next = jest.fn();

    requestMetrics(req, res, next);
    res.emit("finish");

    expect(next).toHaveBeenCalledTimes(1);

    const metrics = await client.register.metrics();
    expect(metrics).toContain(
      'flash_sales_http_requests_total{method="GET",route="/orders/:orderId",status_code="200"} 1',
    );
    expect(metrics).toContain(
      'http_request_duration_ms_count{method="GET",route="/orders/:orderId",status_code="200"} 1',
    );
    expect(metrics).not.toContain("unique-order-id");
  });

  it("uses a bounded label for unmatched request paths", async () => {
    const req = {
      method: "GET",
      path: "/not-found/unique-order-id",
    } as Request;
    const res = Object.assign(new EventEmitter(), {
      statusCode: 404,
    }) as Response;

    requestMetrics(req, res, jest.fn());
    res.emit("finish");

    const metrics = await client.register.metrics();
    expect(metrics).toContain(
      'flash_sales_http_requests_total{method="GET",route="unmatched",status_code="404"} 1',
    );
    expect(metrics).toContain(
      'http_request_duration_ms_count{method="GET",route="unmatched",status_code="404"} 1',
    );
    expect(metrics).not.toContain("unique-order-id");
  });
});

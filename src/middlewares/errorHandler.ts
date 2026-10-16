import { Request, Response, NextFunction } from "express";

export function errorHandler(
  err: Error,
  req: Request,
  res: Response,
  next: NextFunction,
) {
  void next;
  console.error("Global Error Handler:", err);

  res.status(500).json({
    status: "error",
    message: "Internal server error",
  });
}

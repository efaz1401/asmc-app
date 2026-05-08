import type { Request, Response, NextFunction, RequestHandler } from 'express';

type AsyncHandler<TReq extends Request = Request> = (
  req: TReq,
  res: Response,
  next: NextFunction,
) => Promise<unknown>;

export function asyncHandler<TReq extends Request = Request>(fn: AsyncHandler<TReq>): RequestHandler {
  return (req, res, next) => {
    Promise.resolve(fn(req as TReq, res, next)).catch(next);
  };
}

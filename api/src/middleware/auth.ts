import type { Request, Response, NextFunction } from 'express';
import { verifyToken, JwtPayload } from '../utils/jwt';
import { HttpError } from './error';

export interface AuthRequest extends Request {
  user?: JwtPayload;
}

export function requireAuth(req: AuthRequest, _res: Response, next: NextFunction): void {
  const header = req.header('authorization') ?? req.header('Authorization');
  if (!header || !header.startsWith('Bearer ')) {
    return next(new HttpError(401, 'Missing or invalid Authorization header', 'AUTH_REQUIRED'));
  }
  const token = header.slice('Bearer '.length).trim();
  try {
    req.user = verifyToken(token);
    next();
  } catch {
    next(new HttpError(401, 'Invalid or expired token', 'AUTH_INVALID'));
  }
}

export type AppRole = 'SUPER_ADMIN' | 'HR_ADMIN' | 'SUPERVISOR' | 'CLIENT' | 'EMPLOYEE';

export function requireRole(...roles: AppRole[]) {
  return (req: AuthRequest, _res: Response, next: NextFunction): void => {
    if (!req.user) return next(new HttpError(401, 'Not authenticated', 'AUTH_REQUIRED'));
    if (!roles.includes(req.user.role as AppRole)) {
      return next(new HttpError(403, 'Forbidden', 'FORBIDDEN'));
    }
    next();
  };
}

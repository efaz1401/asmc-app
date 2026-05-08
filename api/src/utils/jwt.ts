import jwt, { SignOptions } from 'jsonwebtoken';
import { env } from '../config/env';

export interface JwtPayload {
  sub: string; // user id
  role: string;
  email: string;
}

export function signAccessToken(payload: JwtPayload): string {
  const opts: SignOptions = { expiresIn: env.jwt.accessExpiresIn as SignOptions['expiresIn'] };
  return jwt.sign(payload, env.jwt.secret, opts);
}

export function signRefreshToken(payload: JwtPayload): string {
  const opts: SignOptions = { expiresIn: env.jwt.refreshExpiresIn as SignOptions['expiresIn'] };
  return jwt.sign(payload, env.jwt.secret, opts);
}

export function verifyToken(token: string): JwtPayload {
  return jwt.verify(token, env.jwt.secret) as JwtPayload;
}

import type { Request, Response } from 'express';
import * as service from './auth.service';
import {
  registerSchema,
  loginSchema,
  refreshSchema,
  forgotPasswordSchema,
  verifyOtpSchema,
  resetPasswordSchema,
} from './auth.schemas';
import { asyncHandler } from '../../utils/asyncHandler';
import { prisma } from '../../config/prisma';
import type { AuthRequest } from '../../middleware/auth';
import { HttpError } from '../../middleware/error';

export const register = asyncHandler(async (req: Request, res: Response) => {
  const input = registerSchema.parse(req.body);
  const result = await service.registerUser(input);
  res.status(201).json(result);
});

export const login = asyncHandler(async (req: Request, res: Response) => {
  const input = loginSchema.parse(req.body);
  const result = await service.loginUser(input);
  res.json(result);
});

export const refresh = asyncHandler(async (req: Request, res: Response) => {
  const { refreshToken } = refreshSchema.parse(req.body);
  const result = await service.refresh(refreshToken);
  res.json(result);
});

export const logout = asyncHandler(async (req: Request, res: Response) => {
  const { refreshToken } = refreshSchema.parse(req.body);
  await service.logout(refreshToken);
  res.json({ ok: true });
});

export const forgotPassword = asyncHandler(async (req: Request, res: Response) => {
  const { email } = forgotPasswordSchema.parse(req.body);
  const result = await service.requestPasswordReset(email);
  res.json(result);
});

export const verifyOtp = asyncHandler(async (req: Request, res: Response) => {
  const { email, code, purpose } = verifyOtpSchema.parse(req.body);
  const result = await service.verifyOtp(email, code, purpose);
  res.json({ ok: true, otpId: result.otpId });
});

export const resetPassword = asyncHandler(async (req: Request, res: Response) => {
  const { email, code, newPassword } = resetPasswordSchema.parse(req.body);
  const result = await service.resetPassword(email, code, newPassword);
  res.json(result);
});

export const me = asyncHandler(async (req: AuthRequest, res: Response) => {
  if (!req.user) throw new HttpError(401, 'Not authenticated');
  const user = await prisma.user.findUnique({
    where: { id: req.user.sub },
    include: { employee: true, client: true },
  });
  if (!user) throw new HttpError(404, 'User not found');
  res.json({
    user: service.publicUser(user),
    employee: user.employee ?? null,
    client: user.client ?? null,
  });
});

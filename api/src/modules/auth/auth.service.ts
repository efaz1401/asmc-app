import { prisma } from '../../config/prisma';
import { hashPassword, verifyPassword } from '../../utils/password';
import { signAccessToken, signRefreshToken } from '../../utils/jwt';
import { HttpError } from '../../middleware/error';
import type { RegisterInput, LoginInput } from './auth.schemas';

function makeTokens(user: { id: string; role: string; email: string }) {
  const payload = { sub: user.id, role: user.role, email: user.email };
  return {
    accessToken: signAccessToken(payload),
    refreshToken: signRefreshToken(payload),
  };
}

export async function registerUser(input: RegisterInput) {
  const existing = await prisma.user.findUnique({ where: { email: input.email } });
  if (existing) throw new HttpError(409, 'Email already registered', 'EMAIL_TAKEN');

  const passwordHash = await hashPassword(input.password);
  const user = await prisma.user.create({
    data: {
      email: input.email,
      phone: input.phone,
      fullName: input.fullName,
      passwordHash,
      role: input.role,
    },
  });

  const tokens = makeTokens(user);
  await prisma.refreshToken.create({
    data: {
      userId: user.id,
      token: tokens.refreshToken,
      expiresAt: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000),
    },
  });

  return {
    user: publicUser(user),
    ...tokens,
  };
}

export async function loginUser(input: LoginInput) {
  const user = await prisma.user.findUnique({ where: { email: input.email } });
  if (!user || !user.isActive) throw new HttpError(401, 'Invalid credentials', 'INVALID_CREDENTIALS');

  const ok = await verifyPassword(input.password, user.passwordHash);
  if (!ok) throw new HttpError(401, 'Invalid credentials', 'INVALID_CREDENTIALS');

  await prisma.user.update({ where: { id: user.id }, data: { lastLoginAt: new Date() } });

  const tokens = makeTokens(user);
  await prisma.refreshToken.create({
    data: {
      userId: user.id,
      token: tokens.refreshToken,
      expiresAt: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000),
    },
  });

  return { user: publicUser(user), ...tokens };
}

export async function refresh(refreshToken: string) {
  const stored = await prisma.refreshToken.findUnique({ where: { token: refreshToken } });
  if (!stored || stored.revokedAt || stored.expiresAt < new Date()) {
    throw new HttpError(401, 'Refresh token invalid or expired', 'REFRESH_INVALID');
  }
  const user = await prisma.user.findUnique({ where: { id: stored.userId } });
  if (!user || !user.isActive) throw new HttpError(401, 'User inactive', 'USER_INACTIVE');

  const tokens = makeTokens(user);
  // Rotate
  await prisma.refreshToken.update({
    where: { id: stored.id },
    data: { revokedAt: new Date() },
  });
  await prisma.refreshToken.create({
    data: {
      userId: user.id,
      token: tokens.refreshToken,
      expiresAt: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000),
    },
  });
  return { user: publicUser(user), ...tokens };
}

export async function logout(refreshToken: string) {
  const stored = await prisma.refreshToken.findUnique({ where: { token: refreshToken } });
  if (stored && !stored.revokedAt) {
    await prisma.refreshToken.update({
      where: { id: stored.id },
      data: { revokedAt: new Date() },
    });
  }
}

function generateOtp(): string {
  return Math.floor(100000 + Math.random() * 900000).toString();
}

export async function requestPasswordReset(email: string) {
  const user = await prisma.user.findUnique({ where: { email } });
  // Don't leak existence — pretend success either way.
  if (!user) return { sent: true };

  const code = generateOtp();
  await prisma.otpCode.create({
    data: {
      userId: user.id,
      code,
      purpose: 'RESET_PASSWORD',
      expiresAt: new Date(Date.now() + 15 * 60 * 1000),
    },
  });

  // In a real deployment, send via email/SMS. For now we surface the code in logs
  // so you can wire SMTP / Twilio / FCM later.
  console.log(`[otp] password reset for ${email}: ${code}`);
  return { sent: true };
}

export async function verifyOtp(email: string, code: string, purpose: string) {
  const user = await prisma.user.findUnique({ where: { email } });
  if (!user) throw new HttpError(400, 'Invalid OTP', 'OTP_INVALID');

  const otp = await prisma.otpCode.findFirst({
    where: { userId: user.id, code, purpose, consumedAt: null },
    orderBy: { createdAt: 'desc' },
  });
  if (!otp || otp.expiresAt < new Date()) {
    throw new HttpError(400, 'Invalid or expired OTP', 'OTP_INVALID');
  }
  return { otpId: otp.id, userId: user.id };
}

export async function resetPassword(email: string, code: string, newPassword: string) {
  const { otpId, userId } = await verifyOtp(email, code, 'RESET_PASSWORD');
  const passwordHash = await hashPassword(newPassword);
  await prisma.$transaction([
    prisma.user.update({ where: { id: userId }, data: { passwordHash } }),
    prisma.otpCode.update({ where: { id: otpId }, data: { consumedAt: new Date() } }),
    prisma.refreshToken.updateMany({
      where: { userId, revokedAt: null },
      data: { revokedAt: new Date() },
    }),
  ]);
  return { ok: true };
}

export function publicUser(u: {
  id: string;
  email: string;
  fullName: string;
  role: string;
  phone: string | null;
  isActive: boolean;
  lastLoginAt: Date | null;
  createdAt: Date;
}) {
  return {
    id: u.id,
    email: u.email,
    fullName: u.fullName,
    role: u.role,
    phone: u.phone,
    isActive: u.isActive,
    lastLoginAt: u.lastLoginAt,
    createdAt: u.createdAt,
  };
}

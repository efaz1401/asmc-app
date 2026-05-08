import { Router } from 'express';
import { requireAuth, requireRole } from '../../middleware/auth';
import { prisma } from '../../config/prisma';
import { asyncHandler } from '../../utils/asyncHandler';
import { publicUser } from '../auth/auth.service';

const router = Router();

router.get(
  '/',
  requireAuth,
  requireRole('SUPER_ADMIN', 'HR_ADMIN'),
  asyncHandler(async (_req, res) => {
    const users = await prisma.user.findMany({ orderBy: { createdAt: 'desc' } });
    res.json({ items: users.map(publicUser) });
  }),
);

export default router;

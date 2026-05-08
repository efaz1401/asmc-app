import { Router } from 'express';
import * as ctrl from './deployments.controller';
import { requireAuth, requireRole } from '../../middleware/auth';

const router = Router();

router.get('/', requireAuth, ctrl.list);
router.get('/stats', requireAuth, ctrl.stats);
router.get('/availability', requireAuth, ctrl.availability);
router.get('/:id', requireAuth, ctrl.getById);
router.post('/', requireAuth, requireRole('SUPER_ADMIN', 'HR_ADMIN', 'SUPERVISOR'), ctrl.create);
router.patch('/:id', requireAuth, requireRole('SUPER_ADMIN', 'HR_ADMIN', 'SUPERVISOR'), ctrl.update);
router.delete('/:id', requireAuth, requireRole('SUPER_ADMIN', 'HR_ADMIN'), ctrl.remove);

export default router;

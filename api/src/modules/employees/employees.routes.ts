import { Router } from 'express';
import * as ctrl from './employees.controller';
import { requireAuth, requireRole } from '../../middleware/auth';

const router = Router();

router.get('/', requireAuth, ctrl.list);
router.get('/:id', requireAuth, ctrl.getById);
router.post('/', requireAuth, requireRole('SUPER_ADMIN', 'HR_ADMIN'), ctrl.create);
router.patch('/:id', requireAuth, requireRole('SUPER_ADMIN', 'HR_ADMIN'), ctrl.update);
router.delete('/:id', requireAuth, requireRole('SUPER_ADMIN', 'HR_ADMIN'), ctrl.remove);

export default router;

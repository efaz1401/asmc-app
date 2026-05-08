import { Router } from 'express';
import authRoutes from '../modules/auth/auth.routes';
import userRoutes from '../modules/users/users.routes';
import employeeRoutes from '../modules/employees/employees.routes';
import clientRoutes from '../modules/clients/clients.routes';
import deploymentRoutes from '../modules/deployments/deployments.routes';

const router = Router();

router.get('/health', (_req, res) => {
  res.json({ status: 'ok', service: 'asmc-api', time: new Date().toISOString() });
});

router.use('/auth', authRoutes);
router.use('/users', userRoutes);
router.use('/employees', employeeRoutes);
router.use('/clients', clientRoutes);
router.use('/deployments', deploymentRoutes);

export default router;

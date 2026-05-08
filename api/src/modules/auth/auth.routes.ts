import { Router } from 'express';
import * as ctrl from './auth.controller';
import { requireAuth } from '../../middleware/auth';

const router = Router();

router.post('/register', ctrl.register);
router.post('/login', ctrl.login);
router.post('/refresh', ctrl.refresh);
router.post('/logout', ctrl.logout);
router.post('/forgot-password', ctrl.forgotPassword);
router.post('/verify-otp', ctrl.verifyOtp);
router.post('/reset-password', ctrl.resetPassword);
router.get('/me', requireAuth, ctrl.me);

export default router;

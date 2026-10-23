// Admin router (R2): one auth-gated mount point composing the per-domain
// sub-routers. Replaces the former 1431-line admin.ts.
import { Router } from 'express';
import { requireAuth, requireAdminOrDemo } from '../../middleware/auth';
import moderationRouter from './moderation';
import operationsRouter from './operations';
import catalogRouter from './catalog';

const router = Router();
router.use(requireAuth);
router.use(requireAdminOrDemo);
router.use(moderationRouter);
router.use(operationsRouter);
router.use(catalogRouter);

export default router;

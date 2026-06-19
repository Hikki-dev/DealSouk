import { Router } from 'express';
import {
  TOKENS_PER_LEVEL,
  MAX_LEVEL,
  PRICE_FRESHNESS_MS,
  HOUR_MS,
} from '../config/constants';

const router = Router();

// GET /config — public client configuration. Single source of truth for values
// the Flutter client would otherwise re-hardcode (R4). Keep this free of secrets
// and admin-only settings.
router.get('/', (_req, res) => {
  res.json({
    tokensPerLevel: TOKENS_PER_LEVEL,
    maxLevel: MAX_LEVEL,
    priceFreshnessHours: Math.round(PRICE_FRESHNESS_MS / HOUR_MS),
  });
});

export default router;

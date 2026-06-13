import rateLimit from 'express-rate-limit';
import { AuthRequest } from './auth';

function envLimit(name: string, fallback: number): number {
  const value = Number(process.env[name]);
  return Number.isFinite(value) && value > 0 ? value : fallback;
}

export function ipRateLimit(params: {
  envName: string;
  fallback: number;
  message: string;
}) {
  return rateLimit({
    windowMs: 60 * 1000,
    max: envLimit(params.envName, params.fallback),
    standardHeaders: true,
    legacyHeaders: false,
    message: { error: params.message },
  });
}

export function authenticatedRateLimit(params: {
  envName: string;
  fallback: number;
  message: string;
}) {
  return rateLimit({
    windowMs: 60 * 1000,
    max: envLimit(params.envName, params.fallback),
    standardHeaders: true,
    legacyHeaders: false,
    keyGenerator: (req: AuthRequest) => `user:${req.userId ?? 'unknown'}`,
    message: { error: params.message },
  });
}

import express, { type Express } from 'express';
import cors from 'cors';
import helmet from 'helmet';
import morgan from 'morgan';
import rateLimit from 'express-rate-limit';
import { env } from './config/env';
import routes from './routes';
import { errorHandler, notFound } from './middleware/error';

export function createApp(): Express {
  const app = express();
  app.disable('x-powered-by');
  app.set('trust proxy', 1);

  app.use(helmet());
  app.use(cors({ origin: env.corsOrigin, credentials: true }));
  app.use(express.json({ limit: '2mb' }));
  app.use(express.urlencoded({ extended: true }));
  app.use(morgan(env.nodeEnv === 'production' ? 'combined' : 'dev'));

  // Basic rate limit on auth routes to slow brute force.
  app.use(
    '/api/auth',
    rateLimit({ windowMs: 15 * 60 * 1000, max: 100, standardHeaders: true, legacyHeaders: false }),
  );

  app.get('/', (_req, res) => {
    res.json({ name: 'asmc-api', version: '0.1.0' });
  });
  app.use('/api', routes);

  app.use(notFound);
  app.use(errorHandler);

  return app;
}

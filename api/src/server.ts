import { createApp } from './app';
import { env } from './config/env';
import { prisma } from './config/prisma';

async function main() {
  const app = createApp();
  const server = app.listen(env.port, () => {
    console.log(`[asmc-api] listening on http://localhost:${env.port}`);
    console.log(`[asmc-api] env=${env.nodeEnv}`);
  });

  const shutdown = async (signal: string) => {
    console.log(`[asmc-api] received ${signal}, shutting down`);
    server.close();
    await prisma.$disconnect();
    process.exit(0);
  };
  process.on('SIGINT', () => void shutdown('SIGINT'));
  process.on('SIGTERM', () => void shutdown('SIGTERM'));
}

main().catch((err) => {
  console.error('[asmc-api] fatal startup error', err);
  process.exit(1);
});

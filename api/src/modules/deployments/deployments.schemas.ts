import { z } from 'zod';

const dateString = z.union([z.string(), z.date()]).transform((v) => new Date(v));
const optionalDateString = z
  .union([z.string(), z.date(), z.null()])
  .optional()
  .transform((v) => (v ? new Date(v) : undefined));

export const createDeploymentSchema = z.object({
  employeeId: z.string().uuid(),
  clientId: z.string().uuid(),
  supervisorId: z.string().uuid().optional(),
  projectName: z.string().optional(),
  startDate: dateString,
  endDate: optionalDateString,
  shift: z.enum(['MORNING', 'EVENING', 'NIGHT', 'FULL_DAY']).optional(),
  status: z.enum(['SCHEDULED', 'ACTIVE', 'COMPLETED', 'CANCELLED']).optional(),
  notes: z.string().optional(),
});
export type CreateDeploymentInput = z.infer<typeof createDeploymentSchema>;

export const updateDeploymentSchema = createDeploymentSchema.partial();

export const deploymentQuerySchema = z.object({
  q: z.string().optional(),
  employeeId: z.string().uuid().optional(),
  clientId: z.string().uuid().optional(),
  status: z.enum(['SCHEDULED', 'ACTIVE', 'COMPLETED', 'CANCELLED']).optional(),
  page: z
    .string()
    .optional()
    .transform((v) => (v ? Math.max(1, parseInt(v, 10)) : 1)),
  pageSize: z
    .string()
    .optional()
    .transform((v) => (v ? Math.min(100, Math.max(1, parseInt(v, 10))) : 20)),
});

export const availabilityQuerySchema = z.object({
  startDate: dateString,
  endDate: optionalDateString,
});

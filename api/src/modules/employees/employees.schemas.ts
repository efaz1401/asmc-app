import { z } from 'zod';

const dateLike = z
  .union([z.string(), z.date(), z.null()])
  .optional()
  .transform((v) => (v ? new Date(v) : undefined));

export const createEmployeeSchema = z.object({
  email: z.string().email(),
  password: z.string().min(8).optional(),
  fullName: z.string().min(1),
  employeeCode: z.string().min(1).optional(),
  phone: z.string().optional(),
  address: z.string().optional(),
  nationalId: z.string().optional(),
  emergencyContact: z.string().optional(),
  department: z.string().optional(),
  trade: z.string().optional(),
  skillCategory: z.string().optional(),
  salary: z.number().nonnegative().optional(),
  joiningDate: dateLike,
  visaNumber: z.string().optional(),
  visaExpiry: dateLike,
  workPermitNumber: z.string().optional(),
  workPermitExpiry: dateLike,
  profilePhotoUrl: z.string().url().optional(),
  availability: z.enum(['AVAILABLE', 'DEPLOYED', 'ON_LEAVE', 'INACTIVE']).optional(),
});
export type CreateEmployeeInput = z.infer<typeof createEmployeeSchema>;

export const updateEmployeeSchema = createEmployeeSchema.partial().extend({
  isActive: z.boolean().optional(),
});

export const employeeQuerySchema = z.object({
  q: z.string().optional(),
  department: z.string().optional(),
  availability: z.enum(['AVAILABLE', 'DEPLOYED', 'ON_LEAVE', 'INACTIVE']).optional(),
  isActive: z
    .enum(['true', 'false'])
    .optional()
    .transform((v) => (v == null ? undefined : v === 'true')),
  page: z
    .string()
    .optional()
    .transform((v) => (v ? Math.max(1, parseInt(v, 10)) : 1)),
  pageSize: z
    .string()
    .optional()
    .transform((v) => (v ? Math.min(100, Math.max(1, parseInt(v, 10))) : 20)),
});

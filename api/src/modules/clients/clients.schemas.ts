import { z } from 'zod';

export const createClientSchema = z.object({
  companyName: z.string().min(1),
  contactPerson: z.string().optional(),
  phone: z.string().optional(),
  email: z.string().email().optional(),
  address: z.string().optional(),
  industry: z.string().optional(),
  billingAddress: z.string().optional(),
  taxId: z.string().optional(),
  notes: z.string().optional(),
  // Optional: also create a portal user for the client
  createPortalAccount: z.boolean().optional(),
  portalPassword: z.string().min(8).optional(),
});
export type CreateClientInput = z.infer<typeof createClientSchema>;

export const updateClientSchema = createClientSchema.partial().extend({
  isActive: z.boolean().optional(),
});

export const clientQuerySchema = z.object({
  q: z.string().optional(),
  industry: z.string().optional(),
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

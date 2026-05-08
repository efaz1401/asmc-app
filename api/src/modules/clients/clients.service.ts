import { Prisma } from '@prisma/client';
import { prisma } from '../../config/prisma';
import { hashPassword } from '../../utils/password';
import { HttpError } from '../../middleware/error';
import type { CreateClientInput } from './clients.schemas';

export interface ClientListQuery {
  q?: string;
  industry?: string;
  isActive?: boolean;
  page: number;
  pageSize: number;
}

export async function listClients(query: ClientListQuery) {
  const where: Prisma.ClientWhereInput = {};
  if (query.industry) where.industry = query.industry;
  if (typeof query.isActive === 'boolean') where.isActive = query.isActive;
  if (query.q) {
    where.OR = [
      { companyName: { contains: query.q } },
      { contactPerson: { contains: query.q } },
      { email: { contains: query.q } },
      { phone: { contains: query.q } },
    ];
  }

  const [items, total] = await Promise.all([
    prisma.client.findMany({
      where,
      orderBy: { createdAt: 'desc' },
      skip: (query.page - 1) * query.pageSize,
      take: query.pageSize,
    }),
    prisma.client.count({ where }),
  ]);

  // Active manpower count per client (in current page)
  const ids = items.map((c) => c.id);
  const counts = await prisma.deployment.groupBy({
    by: ['clientId'],
    where: { clientId: { in: ids }, status: { in: ['SCHEDULED', 'ACTIVE'] } },
    _count: { _all: true },
  });
  const countMap = new Map(counts.map((c) => [c.clientId, c._count._all]));

  return {
    items: items.map((c) => ({ ...c, activeManpower: countMap.get(c.id) ?? 0 })),
    total,
    page: query.page,
    pageSize: query.pageSize,
  };
}

export async function getClient(id: string) {
  const client = await prisma.client.findUnique({
    where: { id },
    include: {
      user: { select: { id: true, email: true, role: true, isActive: true } },
      deployments: {
        orderBy: { startDate: 'desc' },
        take: 20,
        include: { employee: { select: { id: true, fullName: true, employeeCode: true, trade: true } } },
      },
      invoices: { orderBy: { issuedAt: 'desc' }, take: 10 },
      contracts: { orderBy: { startDate: 'desc' }, take: 10 },
    },
  });
  if (!client) throw new HttpError(404, 'Client not found');

  const active = client.deployments.filter((d) => d.status === 'ACTIVE' || d.status === 'SCHEDULED').length;
  return { ...client, activeManpower: active };
}

export async function createClient(input: CreateClientInput) {
  let userId: string | undefined;

  if (input.createPortalAccount) {
    if (!input.email) throw new HttpError(400, 'Email required for portal account', 'EMAIL_REQUIRED');
    const existing = await prisma.user.findUnique({ where: { email: input.email } });
    if (existing) throw new HttpError(409, 'Email already in use', 'EMAIL_TAKEN');
    const passwordHash = await hashPassword(input.portalPassword ?? 'changeme123');
    const user = await prisma.user.create({
      data: {
        email: input.email,
        fullName: input.contactPerson ?? input.companyName,
        passwordHash,
        role: 'CLIENT',
        phone: input.phone,
      },
    });
    userId = user.id;
  }

  const client = await prisma.client.create({
    data: {
      companyName: input.companyName,
      contactPerson: input.contactPerson,
      phone: input.phone,
      email: input.email,
      address: input.address,
      industry: input.industry,
      billingAddress: input.billingAddress,
      taxId: input.taxId,
      notes: input.notes,
      userId,
    },
  });
  return client;
}

export async function updateClient(id: string, data: Prisma.ClientUpdateInput) {
  const existing = await prisma.client.findUnique({ where: { id } });
  if (!existing) throw new HttpError(404, 'Client not found');
  return prisma.client.update({ where: { id }, data });
}

export async function deleteClient(id: string) {
  const client = await prisma.client.findUnique({ where: { id } });
  if (!client) throw new HttpError(404, 'Client not found');
  await prisma.client.update({ where: { id }, data: { isActive: false } });
  return { ok: true };
}

export async function getClientHiringHistory(id: string) {
  const deployments = await prisma.deployment.findMany({
    where: { clientId: id },
    orderBy: { startDate: 'desc' },
    include: { employee: { select: { id: true, fullName: true, employeeCode: true, trade: true } } },
  });
  return { items: deployments };
}

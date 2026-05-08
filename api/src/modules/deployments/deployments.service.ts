import { Prisma } from '@prisma/client';
import { prisma } from '../../config/prisma';
import { HttpError } from '../../middleware/error';
import type { CreateDeploymentInput } from './deployments.schemas';

export interface DeploymentListQuery {
  q?: string;
  employeeId?: string;
  clientId?: string;
  status?: string;
  page: number;
  pageSize: number;
}

const ACTIVE_STATUSES = ['SCHEDULED', 'ACTIVE'] as const;

export async function listDeployments(query: DeploymentListQuery) {
  const where: Prisma.DeploymentWhereInput = {};
  if (query.employeeId) where.employeeId = query.employeeId;
  if (query.clientId) where.clientId = query.clientId;
  if (query.status) where.status = query.status;
  if (query.q) {
    where.OR = [
      { projectName: { contains: query.q } },
      { client: { is: { companyName: { contains: query.q } } } },
      { employee: { is: { fullName: { contains: query.q } } } },
    ];
  }

  const [items, total] = await Promise.all([
    prisma.deployment.findMany({
      where,
      orderBy: { startDate: 'desc' },
      skip: (query.page - 1) * query.pageSize,
      take: query.pageSize,
      include: {
        employee: { select: { id: true, fullName: true, employeeCode: true, trade: true } },
        client: { select: { id: true, companyName: true } },
      },
    }),
    prisma.deployment.count({ where }),
  ]);

  return { items, total, page: query.page, pageSize: query.pageSize };
}

export async function getDeployment(id: string) {
  const deployment = await prisma.deployment.findUnique({
    where: { id },
    include: {
      employee: true,
      client: true,
      attendance: { orderBy: { date: 'desc' }, take: 30 },
    },
  });
  if (!deployment) throw new HttpError(404, 'Deployment not found');
  return deployment;
}

/**
 * Returns true if the employee has a conflicting deployment in [start, end].
 * If `end` is null/undefined, treat as open-ended.
 */
async function hasConflict(
  employeeId: string,
  start: Date,
  end: Date | undefined,
  excludeId?: string,
): Promise<boolean> {
  const existing = await prisma.deployment.findMany({
    where: {
      employeeId,
      id: excludeId ? { not: excludeId } : undefined,
      status: { in: [...ACTIVE_STATUSES] },
    },
  });

  return existing.some((d) => {
    const dStart = d.startDate;
    const dEnd = d.endDate ?? null;
    // overlap if start <= dEnd (or dEnd null) AND (end null or end >= dStart)
    const startsBeforeOurEnd = end ? dStart <= end : true;
    const endsAfterOurStart = dEnd ? dEnd >= start : true;
    return startsBeforeOurEnd && endsAfterOurStart;
  });
}

export async function createDeployment(input: CreateDeploymentInput) {
  // Validate FK existence
  const [employee, client] = await Promise.all([
    prisma.employee.findUnique({ where: { id: input.employeeId } }),
    prisma.client.findUnique({ where: { id: input.clientId } }),
  ]);
  if (!employee) throw new HttpError(404, 'Employee not found');
  if (!client) throw new HttpError(404, 'Client not found');

  if (await hasConflict(input.employeeId, input.startDate, input.endDate)) {
    throw new HttpError(
      409,
      'Employee already has an overlapping deployment',
      'DEPLOYMENT_CONFLICT',
    );
  }

  const deployment = await prisma.deployment.create({
    data: {
      employeeId: input.employeeId,
      clientId: input.clientId,
      supervisorId: input.supervisorId,
      projectName: input.projectName,
      startDate: input.startDate,
      endDate: input.endDate,
      shift: input.shift,
      status: input.status ?? 'SCHEDULED',
      notes: input.notes,
    },
    include: {
      employee: { select: { id: true, fullName: true, employeeCode: true } },
      client: { select: { id: true, companyName: true } },
    },
  });

  // Sync employee availability
  if (deployment.status === 'ACTIVE') {
    await prisma.employee.update({
      where: { id: input.employeeId },
      data: { availability: 'DEPLOYED' },
    });
  }

  return deployment;
}

export interface UpdateDeploymentInput {
  employeeId?: string;
  clientId?: string;
  supervisorId?: string;
  projectName?: string;
  startDate?: Date;
  endDate?: Date;
  shift?: string;
  status?: string;
  notes?: string;
}

export async function updateDeployment(id: string, data: UpdateDeploymentInput) {
  const existing = await prisma.deployment.findUnique({ where: { id } });
  if (!existing) throw new HttpError(404, 'Deployment not found');

  // If dates / employee change, re-check conflict
  const newStart = data.startDate ?? existing.startDate;
  const newEnd = data.endDate ?? existing.endDate ?? undefined;
  const employeeId = data.employeeId ?? existing.employeeId;

  if (await hasConflict(employeeId, newStart, newEnd ?? undefined, id)) {
    throw new HttpError(
      409,
      'Employee already has an overlapping deployment',
      'DEPLOYMENT_CONFLICT',
    );
  }

  const updated = await prisma.deployment.update({ where: { id }, data });

  // Reflect availability based on resulting status
  if (updated.status === 'COMPLETED' || updated.status === 'CANCELLED') {
    await prisma.employee.update({
      where: { id: updated.employeeId },
      data: { availability: 'AVAILABLE' },
    });
  } else if (updated.status === 'ACTIVE') {
    await prisma.employee.update({
      where: { id: updated.employeeId },
      data: { availability: 'DEPLOYED' },
    });
  }

  return updated;
}

export async function deleteDeployment(id: string) {
  const existing = await prisma.deployment.findUnique({ where: { id } });
  if (!existing) throw new HttpError(404, 'Deployment not found');
  await prisma.deployment.delete({ where: { id } });
  return { ok: true };
}

export async function listAvailableEmployees(start: Date, end?: Date) {
  // Find employees that don't have a conflicting active/scheduled deployment
  const all = await prisma.employee.findMany({
    where: { isActive: true },
    orderBy: { fullName: 'asc' },
  });
  const available = [];
  for (const emp of all) {
    if (!(await hasConflict(emp.id, start, end))) available.push(emp);
  }
  return { items: available, total: available.length };
}

export async function deploymentStats() {
  const [total, active, scheduled, completed, available, employees, clients] = await Promise.all([
    prisma.deployment.count(),
    prisma.deployment.count({ where: { status: 'ACTIVE' } }),
    prisma.deployment.count({ where: { status: 'SCHEDULED' } }),
    prisma.deployment.count({ where: { status: 'COMPLETED' } }),
    prisma.employee.count({ where: { availability: 'AVAILABLE', isActive: true } }),
    prisma.employee.count({ where: { isActive: true } }),
    prisma.client.count({ where: { isActive: true } }),
  ]);
  const perClient = await prisma.deployment.groupBy({
    by: ['clientId'],
    where: { status: { in: [...ACTIVE_STATUSES] } },
    _count: { _all: true },
  });
  return {
    total,
    active,
    scheduled,
    completed,
    availableWorkers: available,
    totalEmployees: employees,
    totalClients: clients,
    perClient,
  };
}

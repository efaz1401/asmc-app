import { Prisma } from '@prisma/client';
import { prisma } from '../../config/prisma';
import { hashPassword } from '../../utils/password';
import { HttpError } from '../../middleware/error';
import type { CreateEmployeeInput } from './employees.schemas';

function nextEmployeeCode(): string {
  const stamp = Date.now().toString().slice(-6);
  return `EMP-${stamp}`;
}

export interface EmployeeListQuery {
  q?: string;
  department?: string;
  availability?: string;
  isActive?: boolean;
  page: number;
  pageSize: number;
}

export async function listEmployees(query: EmployeeListQuery) {
  const where: Prisma.EmployeeWhereInput = {};
  if (query.department) where.department = query.department;
  if (query.availability) where.availability = query.availability;
  if (typeof query.isActive === 'boolean') where.isActive = query.isActive;
  if (query.q) {
    where.OR = [
      { fullName: { contains: query.q } },
      { employeeCode: { contains: query.q } },
      { email: { contains: query.q } },
      { phone: { contains: query.q } },
      { trade: { contains: query.q } },
    ];
  }

  const [items, total] = await Promise.all([
    prisma.employee.findMany({
      where,
      orderBy: { createdAt: 'desc' },
      skip: (query.page - 1) * query.pageSize,
      take: query.pageSize,
    }),
    prisma.employee.count({ where }),
  ]);

  return { items, total, page: query.page, pageSize: query.pageSize };
}

export async function getEmployee(id: string) {
  const employee = await prisma.employee.findUnique({
    where: { id },
    include: {
      user: { select: { id: true, email: true, role: true, isActive: true } },
      deployments: {
        orderBy: { startDate: 'desc' },
        take: 10,
        include: { client: { select: { id: true, companyName: true } } },
      },
      contracts: { orderBy: { startDate: 'desc' }, take: 5 },
      documents: { orderBy: { uploadedAt: 'desc' }, take: 20 },
    },
  });
  if (!employee) throw new HttpError(404, 'Employee not found');
  return employee;
}

export async function createEmployee(input: CreateEmployeeInput) {
  const existingUser = await prisma.user.findUnique({ where: { email: input.email } });
  if (existingUser) throw new HttpError(409, 'Email already in use', 'EMAIL_TAKEN');

  const password = input.password ?? 'changeme123';
  const passwordHash = await hashPassword(password);

  const code = input.employeeCode ?? nextEmployeeCode();

  const created = await prisma.user.create({
    data: {
      email: input.email,
      phone: input.phone,
      fullName: input.fullName,
      passwordHash,
      role: 'EMPLOYEE',
      employee: {
        create: {
          employeeCode: code,
          fullName: input.fullName,
          phone: input.phone,
          email: input.email,
          address: input.address,
          nationalId: input.nationalId,
          emergencyContact: input.emergencyContact,
          department: input.department,
          trade: input.trade,
          skillCategory: input.skillCategory,
          salary: input.salary ?? 0,
          joiningDate: input.joiningDate,
          visaNumber: input.visaNumber,
          visaExpiry: input.visaExpiry,
          workPermitNumber: input.workPermitNumber,
          workPermitExpiry: input.workPermitExpiry,
          profilePhotoUrl: input.profilePhotoUrl,
          availability: input.availability ?? 'AVAILABLE',
        },
      },
    },
    include: { employee: true },
  });

  if (!created.employee) throw new HttpError(500, 'Failed to create employee');
  return created.employee;
}

export async function updateEmployee(id: string, data: Prisma.EmployeeUpdateInput) {
  await prisma.employee.findUniqueOrThrow({ where: { id } }).catch(() => {
    throw new HttpError(404, 'Employee not found');
  });
  const updated = await prisma.employee.update({ where: { id }, data });
  return updated;
}

export async function deleteEmployee(id: string) {
  const employee = await prisma.employee.findUnique({ where: { id } });
  if (!employee) throw new HttpError(404, 'Employee not found');
  // Soft-delete: deactivate user + employee
  await prisma.$transaction([
    prisma.employee.update({ where: { id }, data: { isActive: false, availability: 'INACTIVE' } }),
    prisma.user.update({ where: { id: employee.userId }, data: { isActive: false } }),
  ]);
  return { ok: true };
}

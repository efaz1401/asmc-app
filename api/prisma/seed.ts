/* eslint-disable no-console */
import { PrismaClient } from '@prisma/client';
import bcrypt from 'bcryptjs';

const prisma = new PrismaClient();

const PASSWORD_PLAINTEXT = 'Password123!';

async function upsertUser(opts: {
  email: string;
  fullName: string;
  role: string;
  phone?: string;
}) {
  const passwordHash = await bcrypt.hash(PASSWORD_PLAINTEXT, 10);
  return prisma.user.upsert({
    where: { email: opts.email },
    update: { fullName: opts.fullName, role: opts.role, phone: opts.phone },
    create: {
      email: opts.email,
      fullName: opts.fullName,
      role: opts.role,
      phone: opts.phone,
      passwordHash,
    },
  });
}

async function main() {
  console.log('[seed] starting...');

  // ─── Users covering every role ─────────────────────────────────────────────
  const superAdmin = await upsertUser({
    email: 'superadmin@asmc.test',
    fullName: 'Super Admin',
    role: 'SUPER_ADMIN',
    phone: '+1000000001',
  });
  const hrAdmin = await upsertUser({
    email: 'hr@asmc.test',
    fullName: 'HR Admin',
    role: 'HR_ADMIN',
    phone: '+1000000002',
  });
  const supervisor = await upsertUser({
    email: 'supervisor@asmc.test',
    fullName: 'Site Supervisor',
    role: 'SUPERVISOR',
    phone: '+1000000003',
  });

  // ─── Employees ─────────────────────────────────────────────────────────────
  const employeeData = [
    {
      email: 'alice@asmc.test',
      fullName: 'Alice Worker',
      employeeCode: 'EMP-1001',
      department: 'Construction',
      trade: 'Electrician',
      skillCategory: 'Skilled',
      salary: 4200,
      phone: '+1000001001',
    },
    {
      email: 'bob@asmc.test',
      fullName: 'Bob Builder',
      employeeCode: 'EMP-1002',
      department: 'Construction',
      trade: 'Mason',
      skillCategory: 'Skilled',
      salary: 3800,
      phone: '+1000001002',
    },
    {
      email: 'carla@asmc.test',
      fullName: 'Carla Carpenter',
      employeeCode: 'EMP-1003',
      department: 'Construction',
      trade: 'Carpenter',
      skillCategory: 'Skilled',
      salary: 3900,
      phone: '+1000001003',
    },
    {
      email: 'derek@asmc.test',
      fullName: 'Derek Driver',
      employeeCode: 'EMP-1004',
      department: 'Logistics',
      trade: 'Driver',
      skillCategory: 'Semi-skilled',
      salary: 3200,
      phone: '+1000001004',
    },
    {
      email: 'ella@asmc.test',
      fullName: 'Ella Engineer',
      employeeCode: 'EMP-1005',
      department: 'Engineering',
      trade: 'Site Engineer',
      skillCategory: 'Professional',
      salary: 6500,
      phone: '+1000001005',
    },
  ];

  const employees = [];
  for (const e of employeeData) {
    const passwordHash = await bcrypt.hash(PASSWORD_PLAINTEXT, 10);
    const user = await prisma.user.upsert({
      where: { email: e.email },
      update: { fullName: e.fullName, role: 'EMPLOYEE', phone: e.phone },
      create: {
        email: e.email,
        fullName: e.fullName,
        role: 'EMPLOYEE',
        phone: e.phone,
        passwordHash,
      },
    });
    const employee = await prisma.employee.upsert({
      where: { userId: user.id },
      update: {
        employeeCode: e.employeeCode,
        fullName: e.fullName,
        phone: e.phone,
        email: e.email,
        department: e.department,
        trade: e.trade,
        skillCategory: e.skillCategory,
        salary: e.salary,
      },
      create: {
        userId: user.id,
        employeeCode: e.employeeCode,
        fullName: e.fullName,
        phone: e.phone,
        email: e.email,
        department: e.department,
        trade: e.trade,
        skillCategory: e.skillCategory,
        salary: e.salary,
        joiningDate: new Date('2024-01-15'),
        availability: 'AVAILABLE',
      },
    });
    employees.push(employee);
  }

  // ─── Clients ───────────────────────────────────────────────────────────────
  const clientData = [
    {
      email: 'client1@acme.test',
      companyName: 'Acme Construction LLC',
      contactPerson: 'Charles Acme',
      industry: 'Construction',
      phone: '+1000002001',
      address: '123 Builder Ave, Dubai',
    },
    {
      email: 'client2@globex.test',
      companyName: 'Globex Logistics',
      contactPerson: 'Gloria Globex',
      industry: 'Logistics',
      phone: '+1000002002',
      address: '500 Cargo Way, Abu Dhabi',
    },
    {
      email: 'client3@initech.test',
      companyName: 'Initech Engineering',
      contactPerson: 'Iris Initech',
      industry: 'Engineering',
      phone: '+1000002003',
      address: '88 Tech Plaza, Sharjah',
    },
  ];

  const clients = [];
  for (const c of clientData) {
    const passwordHash = await bcrypt.hash(PASSWORD_PLAINTEXT, 10);
    const user = await prisma.user.upsert({
      where: { email: c.email },
      update: { fullName: c.contactPerson, role: 'CLIENT', phone: c.phone },
      create: {
        email: c.email,
        fullName: c.contactPerson,
        role: 'CLIENT',
        phone: c.phone,
        passwordHash,
      },
    });
    const existing = await prisma.client.findUnique({ where: { userId: user.id } });
    const client = existing
      ? await prisma.client.update({
          where: { id: existing.id },
          data: {
            companyName: c.companyName,
            contactPerson: c.contactPerson,
            industry: c.industry,
            phone: c.phone,
            address: c.address,
            email: c.email,
          },
        })
      : await prisma.client.create({
          data: {
            userId: user.id,
            companyName: c.companyName,
            contactPerson: c.contactPerson,
            industry: c.industry,
            phone: c.phone,
            address: c.address,
            email: c.email,
          },
        });
    clients.push(client);
  }

  // ─── Deployments ───────────────────────────────────────────────────────────
  const today = new Date();
  const oneMonthAgo = new Date(today.getTime() - 30 * 24 * 60 * 60 * 1000);
  const oneMonthFromNow = new Date(today.getTime() + 30 * 24 * 60 * 60 * 1000);

  const deploymentSpecs = [
    { employee: employees[0], client: clients[0], status: 'ACTIVE', start: oneMonthAgo, end: oneMonthFromNow, project: 'Tower A — Wiring' },
    { employee: employees[1], client: clients[0], status: 'ACTIVE', start: oneMonthAgo, end: oneMonthFromNow, project: 'Tower A — Masonry' },
    { employee: employees[2], client: clients[1], status: 'SCHEDULED', start: today, end: oneMonthFromNow, project: 'Warehouse Fitout' },
    { employee: employees[3], client: clients[1], status: 'ACTIVE', start: oneMonthAgo, end: undefined, project: 'Fleet Operations' },
    { employee: employees[4], client: clients[2], status: 'COMPLETED', start: oneMonthAgo, end: today, project: 'Site Assessment' },
  ];

  for (const spec of deploymentSpecs) {
    // Use a deterministic synthetic id-by-(employee, project) check.
    const existing = await prisma.deployment.findFirst({
      where: { employeeId: spec.employee.id, clientId: spec.client.id, projectName: spec.project },
    });
    if (existing) {
      await prisma.deployment.update({
        where: { id: existing.id },
        data: {
          status: spec.status,
          startDate: spec.start,
          endDate: spec.end,
          shift: 'FULL_DAY',
          supervisorId: supervisor.id,
        },
      });
    } else {
      await prisma.deployment.create({
        data: {
          employeeId: spec.employee.id,
          clientId: spec.client.id,
          status: spec.status,
          startDate: spec.start,
          endDate: spec.end,
          shift: 'FULL_DAY',
          projectName: spec.project,
          supervisorId: supervisor.id,
        },
      });
    }
  }

  // Sync availability for active employees
  await prisma.employee.updateMany({
    where: { id: { in: [employees[0].id, employees[1].id, employees[3].id] } },
    data: { availability: 'DEPLOYED' },
  });

  console.log('[seed] done.');
  console.log('[seed] login credentials (all use password "%s"):', PASSWORD_PLAINTEXT);
  console.log('[seed]   Super Admin : %s', superAdmin.email);
  console.log('[seed]   HR Admin    : %s', hrAdmin.email);
  console.log('[seed]   Supervisor  : %s', supervisor.email);
  console.log('[seed]   Employees   : %s', employees.map((e) => e.email).join(', '));
  console.log('[seed]   Clients     : %s', clients.map((c) => c.email).join(', '));
}

main()
  .catch((err) => {
    console.error('[seed] error:', err);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });

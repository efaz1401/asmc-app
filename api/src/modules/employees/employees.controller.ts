import type { Request, Response } from 'express';
import { asyncHandler } from '../../utils/asyncHandler';
import * as service from './employees.service';
import {
  createEmployeeSchema,
  updateEmployeeSchema,
  employeeQuerySchema,
} from './employees.schemas';

export const list = asyncHandler(async (req: Request, res: Response) => {
  const query = employeeQuerySchema.parse(req.query);
  const result = await service.listEmployees(query);
  res.json(result);
});

export const getById = asyncHandler(async (req: Request, res: Response) => {
  const result = await service.getEmployee(req.params.id);
  res.json(result);
});

export const create = asyncHandler(async (req: Request, res: Response) => {
  const input = createEmployeeSchema.parse(req.body);
  const result = await service.createEmployee(input);
  res.status(201).json(result);
});

export const update = asyncHandler(async (req: Request, res: Response) => {
  const input = updateEmployeeSchema.parse(req.body);
  const result = await service.updateEmployee(req.params.id, input);
  res.json(result);
});

export const remove = asyncHandler(async (req: Request, res: Response) => {
  const result = await service.deleteEmployee(req.params.id);
  res.json(result);
});

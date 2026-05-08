import type { Request, Response } from 'express';
import { asyncHandler } from '../../utils/asyncHandler';
import * as service from './deployments.service';
import {
  createDeploymentSchema,
  updateDeploymentSchema,
  deploymentQuerySchema,
  availabilityQuerySchema,
} from './deployments.schemas';

export const list = asyncHandler(async (req: Request, res: Response) => {
  const query = deploymentQuerySchema.parse(req.query);
  const result = await service.listDeployments(query);
  res.json(result);
});

export const getById = asyncHandler(async (req: Request, res: Response) => {
  const result = await service.getDeployment(req.params.id);
  res.json(result);
});

export const create = asyncHandler(async (req: Request, res: Response) => {
  const input = createDeploymentSchema.parse(req.body);
  const result = await service.createDeployment(input);
  res.status(201).json(result);
});

export const update = asyncHandler(async (req: Request, res: Response) => {
  const input = updateDeploymentSchema.parse(req.body);
  const result = await service.updateDeployment(req.params.id, input);
  res.json(result);
});

export const remove = asyncHandler(async (req: Request, res: Response) => {
  const result = await service.deleteDeployment(req.params.id);
  res.json(result);
});

export const availability = asyncHandler(async (req: Request, res: Response) => {
  const { startDate, endDate } = availabilityQuerySchema.parse(req.query);
  const result = await service.listAvailableEmployees(startDate, endDate);
  res.json(result);
});

export const stats = asyncHandler(async (_req: Request, res: Response) => {
  const result = await service.deploymentStats();
  res.json(result);
});

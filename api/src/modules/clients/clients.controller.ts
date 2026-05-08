import type { Request, Response } from 'express';
import { asyncHandler } from '../../utils/asyncHandler';
import * as service from './clients.service';
import { createClientSchema, updateClientSchema, clientQuerySchema } from './clients.schemas';

export const list = asyncHandler(async (req: Request, res: Response) => {
  const query = clientQuerySchema.parse(req.query);
  const result = await service.listClients(query);
  res.json(result);
});

export const getById = asyncHandler(async (req: Request, res: Response) => {
  const result = await service.getClient(req.params.id);
  res.json(result);
});

export const create = asyncHandler(async (req: Request, res: Response) => {
  const input = createClientSchema.parse(req.body);
  const result = await service.createClient(input);
  res.status(201).json(result);
});

export const update = asyncHandler(async (req: Request, res: Response) => {
  const input = updateClientSchema.parse(req.body);
  const result = await service.updateClient(req.params.id, input);
  res.json(result);
});

export const remove = asyncHandler(async (req: Request, res: Response) => {
  const result = await service.deleteClient(req.params.id);
  res.json(result);
});

export const hiringHistory = asyncHandler(async (req: Request, res: Response) => {
  const result = await service.getClientHiringHistory(req.params.id);
  res.json(result);
});

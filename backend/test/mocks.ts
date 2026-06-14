import { mockDeep, mockReset, DeepMockProxy } from "jest-mock-extended";
import type { PrismaClient } from "@prisma/client";

// Shared deep mock of the Prisma client. The app's `new PrismaClient()` is wired
// to return this instance via jest.mock('@prisma/client', ...) in each test file.
export const mockPrisma: DeepMockProxy<PrismaClient> = mockDeep<PrismaClient>();

// Controllable Firebase ID-token verifier used by the auth middleware.
export const mockVerifyIdToken = jest.fn();

export function resetMocks(): void {
  mockReset(mockPrisma);
  mockVerifyIdToken.mockReset();
}

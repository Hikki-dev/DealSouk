/** @type {import('ts-jest').JestConfigWithTsJest} */
module.exports = {
  preset: "ts-jest",
  testEnvironment: "node",
  setupFiles: ["<rootDir>/test/setupEnv.ts"],
  testMatch: ["<rootDir>/test/**/*.test.ts"],
  clearMocks: true,
  // Tests need jest globals; the prod tsconfig only includes node types.
  transform: {
    "^.+\\.ts$": ["ts-jest", { tsconfig: "tsconfig.test.json" }],
  },
  // The app + Prisma + Firebase are mocked, so no real DB/credentials are needed.
  // Real-DB integration tests (Postgres service) are a documented follow-up.
};

// Shared configuration for k6 tests
// Base URL can be overridden via environment variable BASE_URL (k6 uses __ENV).

export const BASE_URL = __ENV.BASE_URL || 'https://qa.msupport.mone.am/api/v1';

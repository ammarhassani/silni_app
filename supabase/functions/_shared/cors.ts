// Shared CORS configuration for all edge functions
// Restricts origins to production domain and localhost for development

const allowedOrigins = [
  'https://silni-app.com',
  'https://www.silni-app.com',
  'http://localhost:3000',  // Local development
  'http://localhost:8080',  // Flutter web
];

export function getCorsHeaders(request: Request): Record<string, string> {
  const origin = request.headers.get('Origin') || '';

  // Check if the origin is in our allowed list
  const isAllowed = allowedOrigins.includes(origin);

  return {
    'Access-Control-Allow-Origin': isAllowed ? origin : allowedOrigins[0],
    'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
    'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
  };
}

// For functions called only from mobile apps (not web), use restrictive CORS
export const mobileOnlyCorsHeaders = {
  'Access-Control-Allow-Origin': '',  // No web origin allowed
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

import { NextResponse } from 'next/server';
import type { NextRequest } from 'next/server';

export function middleware(request: NextRequest) {
  // Firebase Auth is client-side only, so we let client components handle auth
  // The DashboardLayout and admin pages will redirect unauthenticated users
  
  return NextResponse.next();
}

export const config = {
  matcher: ['/admin/:path*', '/dashboard/:path*', '/products/:path*', '/customers/:path*', '/suppliers/:path*', '/pos/:path*', '/orders/:path*'],
};

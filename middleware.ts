import { NextResponse } from 'next/server';
import type { NextRequest } from 'next/server';

export function middleware(request: NextRequest) {
  // Protect admin routes
  if (request.nextUrl.pathname.startsWith('/admin')) {
    // Admin routes protection - will be handled client-side by checking user role
    // Redirect to login if no session
    const authCookie = request.cookies.get('__session') || request.cookies.get('firebaseToken');
    
    if (!authCookie) {
      return NextResponse.redirect(new URL('/login', request.url));
    }
  }

  // Protect dashboard routes
  if (request.nextUrl.pathname.startsWith('/dashboard') || 
      request.nextUrl.pathname.startsWith('/products') ||
      request.nextUrl.pathname.startsWith('/customers') ||
      request.nextUrl.pathname.startsWith('/suppliers') ||
      request.nextUrl.pathname.startsWith('/pos') ||
      request.nextUrl.pathname.startsWith('/orders')) {
    
    // Check for auth token (Firebase auth stores token in cookies)
    const authCookie = request.cookies.get('__session') || request.cookies.get('firebaseToken');
    
    // For now, we'll let the client-side handle auth protection
    // This is because Firebase Auth is client-side only
    // The DashboardLayout component handles redirecting unauthenticated users
  }

  return NextResponse.next();
}

export const config = {
  matcher: ['/admin/:path*', '/dashboard/:path*', '/products/:path*', '/customers/:path*', '/suppliers/:path*', '/pos/:path*', '/orders/:path*'],
};

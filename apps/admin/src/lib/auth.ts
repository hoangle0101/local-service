import { getAuthToken } from './api';

export function isAuthenticated(): boolean {
  return !!getAuthToken();
}

export function checkAuth(): void {
  if (!isAuthenticated() && typeof window !== 'undefined') {
    window.location.href = '/login';
  }
}


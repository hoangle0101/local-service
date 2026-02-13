import axios from "axios";
import Cookies from "js-cookie";

const API_BASE_URL = process.env.NEXT_PUBLIC_API_URL || "http://localhost:3000";

export const api = axios.create({
  baseURL: API_BASE_URL,
  headers: {
    "Content-Type": "application/json",
  },
});

// Token key names
const TOKEN_KEY = "admin_auth_token";
const REFRESH_TOKEN_KEY = "admin_refresh_token";

// Request interceptor to add auth token
api.interceptors.request.use(
  (config) => {
    const token = getAuthToken();
    if (token) {
      config.headers.Authorization = `Bearer ${token}`;
    }
    return config;
  },
  (error) => {
    return Promise.reject(error);
  }
);

// Response interceptor for error handling
api.interceptors.response.use(
  (response) => response,
  async (error) => {
    const originalRequest = error.config;

    // If 401 and not already retrying
    if (error.response?.status === 401 && !originalRequest._retry) {
      originalRequest._retry = true;

      // Try to refresh token
      const refreshToken = getRefreshToken();
      if (refreshToken) {
        try {
          const response = await axios.post(`${API_BASE_URL}/auth/refresh`, {
            refreshToken,
          });
          const newToken = response.data.accessToken;
          setAuthToken(newToken);
          originalRequest.headers.Authorization = `Bearer ${newToken}`;
          return api(originalRequest);
        } catch (refreshError) {
          // Refresh failed, logout
          removeAuthToken();
          if (typeof window !== "undefined") {
            window.location.href = "/login";
          }
        }
      } else {
        removeAuthToken();
        if (typeof window !== "undefined") {
          window.location.href = "/login";
        }
      }
    }
    return Promise.reject(error);
  }
);

// Auth token management - use both cookie and localStorage for reliability
export const setAuthToken = (token: string, refreshToken?: string) => {
  // Set in cookie with proper settings
  Cookies.set(TOKEN_KEY, token, {
    expires: 7, // 7 days
    sameSite: "lax",
    path: "/",
  });

  // Backup in localStorage
  if (typeof window !== "undefined") {
    localStorage.setItem(TOKEN_KEY, token);
  }

  // Store refresh token if provided
  if (refreshToken) {
    Cookies.set(REFRESH_TOKEN_KEY, refreshToken, {
      expires: 30, // 30 days
      sameSite: "lax",
      path: "/",
    });
    if (typeof window !== "undefined") {
      localStorage.setItem(REFRESH_TOKEN_KEY, refreshToken);
    }
  }
};

export const getAuthToken = (): string | undefined => {
  // Try new key first
  let token = Cookies.get(TOKEN_KEY);

  // Fallback to old key for backward compatibility
  if (!token) {
    token = Cookies.get("auth_token");
    // If found in old key, migrate to new key
    if (token) {
      Cookies.set(TOKEN_KEY, token, { expires: 7, sameSite: "lax", path: "/" });
      Cookies.remove("auth_token");
    }
  }

  // If not in cookie, try localStorage
  if (!token && typeof window !== "undefined") {
    token = localStorage.getItem(TOKEN_KEY) || undefined;
    // Restore to cookie if found in localStorage
    if (token) {
      Cookies.set(TOKEN_KEY, token, { expires: 7, sameSite: "lax", path: "/" });
    }
  }

  return token;
};

export const getRefreshToken = (): string | undefined => {
  let token = Cookies.get(REFRESH_TOKEN_KEY);
  if (!token && typeof window !== "undefined") {
    token = localStorage.getItem(REFRESH_TOKEN_KEY) || undefined;
  }
  return token;
};

export const removeAuthToken = () => {
  Cookies.remove(TOKEN_KEY, { path: "/" });
  Cookies.remove(REFRESH_TOKEN_KEY, { path: "/" });
  if (typeof window !== "undefined") {
    localStorage.removeItem(TOKEN_KEY);
    localStorage.removeItem(REFRESH_TOKEN_KEY);
  }
};

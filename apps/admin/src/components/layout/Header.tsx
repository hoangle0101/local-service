'use client';

import { Bell, User, LogOut, Settings, User as UserIcon } from 'lucide-react';
import { Button } from '@/components/ui/button';
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuLabel,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from '@/components/ui/dropdown-menu';
import { useRouter } from 'next/navigation';
import { removeAuthToken, api } from '@/lib/api';
import { useQuery } from '@tanstack/react-query';
import { ApiResponse } from '@/types/system';
import Link from 'next/link';

export default function Header() {
  const router = useRouter();

  // Get current user info to display in header
  const { data: user } = useQuery({
    queryKey: ['me'],
    queryFn: async () => {
      const response = await api.get<ApiResponse<any>>('/users/me');
      return response.data.data;
    },
  });

  const handleLogout = () => {
    removeAuthToken();
    router.push('/login');
  };

  return (
    <header className="h-16 border-b border-zinc-200 bg-white/90 backdrop-blur-sm flex items-center justify-between px-6 sticky top-0 z-30">
      <div className="flex items-center">
        <div className="text-sm text-zinc-600">
          Welcome back, <span className="font-medium text-zinc-900">{user?.profile?.fullName || 'Admin'}</span>
        </div>
      </div>

      <div className="flex items-center space-x-4">
        <Button variant="ghost" size="icon" className="relative">
          <Bell className="h-5 w-5 text-zinc-500 hover:text-blue-500" />
          <span className="absolute top-2 right-2 h-2 w-2 bg-red-500 rounded-full" />
        </Button>

        <DropdownMenu>
          <DropdownMenuTrigger asChild>
            <div className="flex items-center space-x-2 cursor-pointer hover:bg-zinc-50 p-2 rounded-lg transition-colors">
              <div className="h-8 w-8 rounded-full bg-gradient-to-br from-blue-500 to-indigo-600 flex items-center justify-center overflow-hidden">
                {user?.profile?.avatarUrl ? (
                  <img src={user.profile.avatarUrl} alt="Avatar" className="h-full w-full object-cover" />
                ) : (
                  <UserIcon className="h-4 w-4 text-white" />
                )}
              </div>
              <div className="hidden md:block text-left">
                <p className="text-sm font-medium">{user?.profile?.fullName || 'Admin User'}</p>
                <p className="text-xs text-zinc-500 capitalize">
                  {user?.userRoles?.[0]?.role?.name?.replace('_', ' ') || 'Administrator'}
                </p>
              </div>
            </div>
          </DropdownMenuTrigger>
          <DropdownMenuContent align="end" className="w-56">
            <DropdownMenuLabel>My Account</DropdownMenuLabel>
            <DropdownMenuSeparator />
            <DropdownMenuItem asChild>
              <Link href="/settings" className="cursor-pointer">
                <Settings className="mr-2 h-4 w-4" />
                <span>Settings</span>
              </Link>
            </DropdownMenuItem>
            <DropdownMenuItem onClick={handleLogout} className="text-red-600 focus:text-red-600 cursor-pointer">
              <LogOut className="mr-2 h-4 w-4" />
              <span>Log out</span>
            </DropdownMenuItem>
          </DropdownMenuContent>
        </DropdownMenu>
      </div>
    </header>
  );
}

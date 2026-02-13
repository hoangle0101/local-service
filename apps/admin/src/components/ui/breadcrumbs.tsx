'use client';

import Link from 'next/link';
import { usePathname } from 'next/navigation';
import { ChevronRight, Home } from 'lucide-react';
import { cn } from '@/lib/utils';

export function Breadcrumbs() {
  const pathname = usePathname();
  const paths = pathname.split('/').filter(Boolean);

  if (paths.length === 0) return null;

  return (
    <nav className="flex items-center space-x-2 text-sm text-zinc-500 mb-6">
      <Link
        href="/"
        className="flex items-center hover:text-blue-600 transition-colors"
      >
        <Home className="h-4 w-4" />
      </Link>
      {paths.map((path, index) => {
        const href = `/${paths.slice(0, index + 1).join('/')}`;
        const isLast = index === paths.length - 1;
        const label = path.charAt(0).toUpperCase() + path.slice(1).replace(/-/g, ' ');

        return (
          <div key={path} className="flex items-center space-x-2">
            <ChevronRight className="h-4 w-4 text-zinc-300" />
            <Link
              href={href}
              className={cn(
                "hover:text-blue-600 transition-colors",
                isLast && "font-semibold text-zinc-900 pointer-events-none"
              )}
            >
              {label}
            </Link>
          </div>
        );
      })}
    </nav>
  );
}

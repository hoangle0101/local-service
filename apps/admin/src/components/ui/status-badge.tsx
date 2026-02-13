import { cn } from '@/lib/utils';
import { STATUS_COLORS } from '@/lib/constants';

interface StatusBadgeProps {
  status: string | null | undefined;
  className?: string;
}

export function StatusBadge({ status, className }: StatusBadgeProps) {
  if (!status) {
    return (
      <span className={cn('inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium border bg-zinc-100 text-zinc-600 border-zinc-200', className)}>
        N/A
      </span>
    );
  }
  
  const statusLower = status.toLowerCase();
  const colorClass = STATUS_COLORS[statusLower as keyof typeof STATUS_COLORS] || 
    'bg-zinc-100 text-zinc-600 border-zinc-200';

  return (
    <span
      className={cn(
        'inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium border',
        colorClass,
        className
      )}
    >
      {status}
    </span>
  );
}

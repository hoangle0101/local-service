"use client";

import { DisputeTimelineEntry } from "@/types/dispute";
import {
  Clock,
  CheckCircle,
  MessageCircle,
  Image,
  ArrowUp,
  XCircle,
  AlertTriangle,
} from "lucide-react";
import { formatDistanceToNow } from "date-fns";
import { vi } from "date-fns/locale";

interface DisputeTimelineProps {
  timeline: DisputeTimelineEntry[];
}

const ACTION_ICONS: Record<string, React.ReactNode> = {
  created: <AlertTriangle className="h-4 w-4 text-yellow-500" />,
  status_changed: <Clock className="h-4 w-4 text-blue-500" />,
  evidence_added: <Image className="h-4 w-4 text-purple-500" />,
  response_submitted: <MessageCircle className="h-4 w-4 text-green-500" />,
  escalated: <ArrowUp className="h-4 w-4 text-red-500" />,
  resolved: <CheckCircle className="h-4 w-4 text-green-500" />,
  appealed: <AlertTriangle className="h-4 w-4 text-orange-500" />,
  cancelled: <XCircle className="h-4 w-4 text-zinc-500" />,
};

const ACTION_LABELS: Record<string, string> = {
  created: "Tranh chấp được tạo",
  status_changed: "Trạng thái thay đổi",
  evidence_added: "Thêm bằng chứng",
  response_submitted: "Phản hồi được gửi",
  escalated: "Leo thang tranh chấp",
  resolved: "Đã giải quyết",
  appealed: "Kháng cáo",
  cancelled: "Đã hủy",
};

export function DisputeTimeline({ timeline }: DisputeTimelineProps) {
  if (!timeline || timeline.length === 0) {
    return (
      <div className="text-center py-8 text-zinc-500">Chưa có lịch sử</div>
    );
  }

  return (
    <div className="flow-root">
      <ul className="-mb-8">
        {timeline.map((entry, idx) => (
          <li key={entry.id}>
            <div className="relative pb-8">
              {idx !== timeline.length - 1 && (
                <span
                  className="absolute top-4 left-4 -ml-px h-full w-0.5 bg-zinc-200"
                  aria-hidden="true"
                />
              )}
              <div className="relative flex space-x-3">
                <div className="flex h-8 w-8 items-center justify-center rounded-full bg-zinc-100 ring-4 ring-white">
                  {ACTION_ICONS[entry.action] || (
                    <Clock className="h-4 w-4 text-zinc-400" />
                  )}
                </div>
                <div className="flex min-w-0 flex-1 justify-between space-x-4 pt-1.5">
                  <div>
                    <p className="text-sm font-medium text-zinc-900">
                      {ACTION_LABELS[entry.action] || entry.action}
                    </p>
                    <p className="text-sm text-zinc-500 mt-0.5">
                      {entry.description}
                    </p>
                    {entry.actor && (
                      <p className="text-xs text-zinc-400 mt-1">
                        bởi {entry.actor.profile?.fullName || "Unknown"}
                      </p>
                    )}
                  </div>
                  <div className="whitespace-nowrap text-right text-xs text-zinc-500">
                    {formatDistanceToNow(new Date(entry.createdAt), {
                      addSuffix: true,
                      locale: vi,
                    })}
                  </div>
                </div>
              </div>
            </div>
          </li>
        ))}
      </ul>
    </div>
  );
}

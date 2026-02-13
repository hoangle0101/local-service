"use client";

import { useState } from "react";
import { DisputeEvidence } from "@/types/dispute";
import {
  Image,
  Video,
  FileText,
  Mic,
  Camera,
  ExternalLink,
  X,
} from "lucide-react";
import { Button } from "@/components/ui/button";
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { formatDistanceToNow } from "date-fns";
import { vi } from "date-fns/locale";

interface EvidenceViewerProps {
  evidence: DisputeEvidence[];
}

const TYPE_ICONS: Record<string, React.ReactNode> = {
  image: <Image className="h-4 w-4" />,
  video: <Video className="h-4 w-4" />,
  audio: <Mic className="h-4 w-4" />,
  document: <FileText className="h-4 w-4" />,
  screenshot: <Camera className="h-4 w-4" />,
};

const TYPE_LABELS: Record<string, string> = {
  image: "Hình ảnh",
  video: "Video",
  audio: "Audio",
  document: "Tài liệu",
  screenshot: "Ảnh chụp màn hình",
};

export function EvidenceViewer({ evidence }: EvidenceViewerProps) {
  const [selectedEvidence, setSelectedEvidence] =
    useState<DisputeEvidence | null>(null);

  if (!evidence || evidence.length === 0) {
    return (
      <div className="text-center py-8 text-zinc-500">
        Chưa có bằng chứng nào
      </div>
    );
  }

  return (
    <>
      <div className="grid grid-cols-2 md:grid-cols-3 gap-4">
        {evidence.map((item) => (
          <div
            key={item.id}
            className="relative group border rounded-lg overflow-hidden cursor-pointer hover:border-blue-500 transition-colors"
            onClick={() => setSelectedEvidence(item)}
          >
            {/* Thumbnail or placeholder */}
            {item.type === "image" || item.type === "screenshot" ? (
              <div className="aspect-video bg-zinc-100 relative">
                <img
                  src={item.url}
                  alt={item.description || "Evidence"}
                  className="w-full h-full object-cover"
                  onError={(e) => {
                    (e.target as HTMLImageElement).src =
                      "/placeholder-image.png";
                  }}
                />
              </div>
            ) : (
              <div className="aspect-video bg-zinc-100 flex items-center justify-center">
                <div className="text-center">
                  <div className="w-12 h-12 mx-auto rounded-full bg-zinc-200 flex items-center justify-center mb-2">
                    {TYPE_ICONS[item.type]}
                  </div>
                  <span className="text-sm text-zinc-600">
                    {TYPE_LABELS[item.type] || item.type}
                  </span>
                </div>
              </div>
            )}

            {/* Info overlay */}
            <div className="absolute inset-0 bg-black/50 opacity-0 group-hover:opacity-100 transition-opacity flex items-center justify-center">
              <Button variant="secondary" size="sm">
                <ExternalLink className="h-4 w-4 mr-1" />
                Xem
              </Button>
            </div>

            {/* Footer */}
            <div className="p-2 bg-white border-t">
              <div className="flex items-center gap-2 text-xs text-zinc-500">
                {TYPE_ICONS[item.type]}
                <span className="truncate">
                  {item.uploader?.profile?.fullName || "Unknown"}
                </span>
              </div>
              <div className="text-xs text-zinc-400 mt-1">
                {formatDistanceToNow(new Date(item.createdAt), {
                  addSuffix: true,
                  locale: vi,
                })}
              </div>
            </div>
          </div>
        ))}
      </div>

      {/* Detail Modal */}
      <Dialog
        open={!!selectedEvidence}
        onOpenChange={() => setSelectedEvidence(null)}
      >
        <DialogContent className="max-w-3xl">
          <DialogHeader>
            <DialogTitle className="flex items-center gap-2">
              {selectedEvidence && TYPE_ICONS[selectedEvidence.type]}
              {selectedEvidence &&
                (TYPE_LABELS[selectedEvidence.type] || "Bằng chứng")}
            </DialogTitle>
          </DialogHeader>

          {selectedEvidence && (
            <div className="space-y-4">
              {/* Media display */}
              {(selectedEvidence.type === "image" ||
                selectedEvidence.type === "screenshot") && (
                <div className="flex justify-center bg-zinc-100 rounded-lg p-4">
                  <img
                    src={selectedEvidence.url}
                    alt={selectedEvidence.description || "Evidence"}
                    className="max-h-[60vh] object-contain"
                  />
                </div>
              )}

              {selectedEvidence.type === "video" && (
                <video
                  src={selectedEvidence.url}
                  controls
                  className="w-full max-h-[60vh]"
                />
              )}

              {selectedEvidence.type === "audio" && (
                <audio src={selectedEvidence.url} controls className="w-full" />
              )}

              {selectedEvidence.type === "document" && (
                <div className="text-center py-8">
                  <FileText className="h-16 w-16 mx-auto text-zinc-400 mb-4" />
                  <a
                    href={selectedEvidence.url}
                    target="_blank"
                    rel="noopener noreferrer"
                    className="text-blue-500 hover:underline"
                  >
                    Mở tài liệu
                  </a>
                </div>
              )}

              {/* Description */}
              {selectedEvidence.description && (
                <div className="bg-zinc-50 p-3 rounded-lg">
                  <div className="text-sm font-medium text-zinc-600 mb-1">
                    Mô tả
                  </div>
                  <p className="text-sm">{selectedEvidence.description}</p>
                </div>
              )}

              {/* Meta */}
              <div className="flex justify-between text-sm text-zinc-500">
                <span>
                  Tải lên bởi:{" "}
                  {selectedEvidence.uploader?.profile?.fullName || "Unknown"}
                </span>
                <span>
                  {new Date(selectedEvidence.createdAt).toLocaleString("vi-VN")}
                </span>
              </div>
            </div>
          )}
        </DialogContent>
      </Dialog>
    </>
  );
}

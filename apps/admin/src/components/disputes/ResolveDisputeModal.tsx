"use client";

import { useState } from "react";
import { Button } from "@/components/ui/button";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";
import { Input } from "@/components/ui/input";
import { Switch } from "@/components/ui/switch";
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogFooter,
} from "@/components/ui/dialog";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import {
  Dispute,
  DisputeResolutionType,
  ResolveDisputeInput,
  RESOLUTION_TYPE_LABELS,
} from "@/types/dispute";
import { AlertTriangle } from "lucide-react";

interface ResolveDisputeModalProps {
  dispute: Dispute;
  open: boolean;
  onOpenChange: (open: boolean) => void;
  onResolve: (data: ResolveDisputeInput) => Promise<void>;
  isLoading?: boolean;
}

const RESOLUTION_OPTIONS: DisputeResolutionType[] = [
  "full_refund_to_customer",
  "partial_refund_to_customer",
  "full_payment_to_provider",
  "mutual_cancellation",
  "no_action",
];

export function ResolveDisputeModal({
  dispute,
  open,
  onOpenChange,
  onResolve,
  isLoading,
}: ResolveDisputeModalProps) {
  const [resolution, setResolution] = useState<DisputeResolutionType>(
    "full_refund_to_customer"
  );
  const [refundAmount, setRefundAmount] = useState("");
  const [notes, setNotes] = useState("");
  const [applyPenalty, setApplyPenalty] = useState(false);
  const [penaltyType, setPenaltyType] = useState<
    "warning" | "temporary_ban" | "fee_deduction"
  >("warning");
  const [penaltySeverity, setPenaltySeverity] = useState<
    "low" | "medium" | "high"
  >("low");
  const [banDurationDays, setBanDurationDays] = useState("7");
  const [feeAmount, setFeeAmount] = useState("");

  const bookingAmount = dispute.booking?.actualPrice
    ? parseFloat(String(dispute.booking.actualPrice))
    : 0;

  const showRefundInput = resolution === "partial_refund_to_customer";
  const showPenaltyOptions = applyPenalty;

  const handleSubmit = async () => {
    const data: ResolveDisputeInput = {
      resolution,
      notes: notes.trim() || undefined,
    };

    if (showRefundInput) {
      data.refundAmount = parseFloat(refundAmount) || 0;
    } else if (resolution === "full_refund_to_customer") {
      data.refundAmount = bookingAmount;
    }

    if (applyPenalty) {
      data.applyPenalty = true;
      data.penaltyType = penaltyType;
      data.penaltySeverity = penaltySeverity;

      if (penaltyType === "temporary_ban") {
        data.banDurationDays = parseInt(banDurationDays) || 7;
      }
      if (penaltyType === "fee_deduction") {
        data.feeAmount = parseFloat(feeAmount) || 0;
      }
    }

    await onResolve(data);
  };

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="max-w-lg">
        <DialogHeader>
          <DialogTitle>Giải quyết tranh chấp</DialogTitle>
        </DialogHeader>

        <div className="space-y-4 py-4">
          {/* Resolution Type */}
          <div className="space-y-2">
            <Label>Quyết định</Label>
            <Select
              value={resolution}
              onValueChange={(v) => setResolution(v as DisputeResolutionType)}
            >
              <SelectTrigger>
                <SelectValue />
              </SelectTrigger>
              <SelectContent>
                {RESOLUTION_OPTIONS.map((type) => (
                  <SelectItem key={type} value={type}>
                    {RESOLUTION_TYPE_LABELS[type]}
                  </SelectItem>
                ))}
              </SelectContent>
            </Select>
          </div>

          {/* Booking Amount Info */}
          <div className="bg-zinc-50 p-3 rounded-lg text-sm">
            <span className="text-zinc-600">Giá trị booking:</span>{" "}
            <span className="font-medium">
              {new Intl.NumberFormat("vi-VN", {
                style: "currency",
                currency: "VND",
              }).format(bookingAmount)}
            </span>
          </div>

          {/* Partial Refund Amount */}
          {showRefundInput && (
            <div className="space-y-2">
              <Label>Số tiền hoàn trả (VND)</Label>
              <Input
                type="number"
                value={refundAmount}
                onChange={(e) => setRefundAmount(e.target.value)}
                placeholder="0"
                min="0"
                max={bookingAmount}
              />
            </div>
          )}

          {/* Admin Notes */}
          <div className="space-y-2">
            <Label>Ghi chú admin</Label>
            <Textarea
              value={notes}
              onChange={(e) => setNotes(e.target.value)}
              placeholder="Ghi chú về quyết định này..."
              rows={3}
            />
          </div>

          {/* Penalty Toggle */}
          <div className="flex items-center justify-between p-3 bg-red-50 rounded-lg border border-red-200">
            <div className="flex items-center gap-2">
              <AlertTriangle className="h-4 w-4 text-red-500" />
              <span className="text-sm font-medium text-red-700">
                Áp dụng hình phạt
              </span>
            </div>
            <Switch checked={applyPenalty} onCheckedChange={setApplyPenalty} />
          </div>

          {/* Penalty Options */}
          {showPenaltyOptions && (
            <div className="space-y-3 p-3 bg-red-50/50 rounded-lg border border-red-100">
              <div className="space-y-2">
                <Label>Loại hình phạt</Label>
                <Select
                  value={penaltyType}
                  onValueChange={(v: any) => setPenaltyType(v)}
                >
                  <SelectTrigger>
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="warning">Cảnh báo</SelectItem>
                    <SelectItem value="temporary_ban">
                      Tạm khóa tài khoản
                    </SelectItem>
                    <SelectItem value="fee_deduction">Trừ phí</SelectItem>
                  </SelectContent>
                </Select>
              </div>

              <div className="space-y-2">
                <Label>Mức độ</Label>
                <Select
                  value={penaltySeverity}
                  onValueChange={(v: any) => setPenaltySeverity(v)}
                >
                  <SelectTrigger>
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="low">Nhẹ</SelectItem>
                    <SelectItem value="medium">Trung bình</SelectItem>
                    <SelectItem value="high">Nặng</SelectItem>
                  </SelectContent>
                </Select>
              </div>

              {penaltyType === "temporary_ban" && (
                <div className="space-y-2">
                  <Label>Số ngày khóa</Label>
                  <Input
                    type="number"
                    value={banDurationDays}
                    onChange={(e) => setBanDurationDays(e.target.value)}
                    min="1"
                    max="365"
                  />
                </div>
              )}

              {penaltyType === "fee_deduction" && (
                <div className="space-y-2">
                  <Label>Số tiền trừ (VND)</Label>
                  <Input
                    type="number"
                    value={feeAmount}
                    onChange={(e) => setFeeAmount(e.target.value)}
                    placeholder="0"
                    min="0"
                  />
                </div>
              )}
            </div>
          )}
        </div>

        <DialogFooter>
          <Button variant="outline" onClick={() => onOpenChange(false)}>
            Hủy
          </Button>
          <Button onClick={handleSubmit} disabled={isLoading}>
            {isLoading ? "Đang xử lý..." : "Xác nhận giải quyết"}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}

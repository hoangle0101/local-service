"use client";

import { useState } from "react";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { useParams, useRouter } from "next/navigation";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { StatusBadge } from "@/components/ui/status-badge";
import { Button } from "@/components/ui/button";
import { ConfirmDialog } from "@/components/ui/confirm-dialog";
import {
  ArrowLeft,
  DollarSign,
  User,
  Calendar,
  MapPin,
  Clock,
  XCircle,
  CheckCircle,
  AlertTriangle,
} from "lucide-react";
import { api } from "@/lib/api";
import { BookingDetail } from "@/types/booking";
import { ApiResponse } from "@/types/system";
import { toast } from "sonner";

export default function BookingDetailPage() {
  const params = useParams();
  const router = useRouter();
  const queryClient = useQueryClient();
  const bookingId = params.id as string;

  const [cancelDialog, setCancelDialog] = useState(false);
  const [completeDialog, setCompleteDialog] = useState(false);

  const { data: response, isLoading } = useQuery({
    queryKey: ["admin-booking-detail", bookingId],
    queryFn: async () => {
      const res = await api.get<ApiResponse<BookingDetail>>(
        `/admin/bookings/${bookingId}`
      );
      return res.data;
    },
  });

  const booking = response?.data;

  // Admin cancel booking mutation
  const cancelMutation = useMutation({
    mutationFn: async () => {
      return api.patch(`/bookings/${bookingId}/cancel`, {
        reason: "Cancelled by admin",
      });
    },
    onSuccess: () => {
      toast.success("Đã hủy booking thành công");
      queryClient.invalidateQueries({
        queryKey: ["admin-booking-detail", bookingId],
      });
    },
    onError: (error: any) => {
      toast.error(error.response?.data?.message || "Không thể hủy booking");
    },
  });

  // Admin force complete mutation
  const completeMutation = useMutation({
    mutationFn: async () => {
      return api.patch(`/bookings/${bookingId}/status`, {
        status: "completed",
        note: "Force completed by admin",
      });
    },
    onSuccess: () => {
      toast.success("Đã hoàn thành booking thành công");
      queryClient.invalidateQueries({
        queryKey: ["admin-booking-detail", bookingId],
      });
    },
    onError: (error: any) => {
      toast.error(
        error.response?.data?.message || "Không thể hoàn thành booking"
      );
    },
  });

  // Format currency
  const formatCurrency = (amount: number | string) => {
    const numAmount = typeof amount === "string" ? parseFloat(amount) : amount;
    return new Intl.NumberFormat("vi-VN", {
      style: "currency",
      currency: "VND",
    }).format(numAmount);
  };

  // Can admin cancel?
  const canCancel =
    booking && !["completed", "cancelled"].includes(booking.status);

  // Can admin force complete?
  const canComplete =
    booking && ["in_progress", "pending_payment"].includes(booking.status);

  if (isLoading) {
    return (
      <div className="space-y-6">
        <div className="h-8 w-48 bg-zinc-200 animate-pulse rounded" />
        <div className="grid gap-6 md:grid-cols-2">
          {[1, 2, 3, 4].map((i) => (
            <div
              key={i}
              className="h-48 bg-zinc-100 animate-pulse rounded-lg"
            />
          ))}
        </div>
      </div>
    );
  }

  if (!booking) {
    return (
      <div className="flex items-center justify-center h-96">
        <div className="text-center">
          <p className="text-lg text-zinc-600">Booking not found</p>
          <Button onClick={() => router.push("/bookings")} className="mt-4">
            Back to Bookings
          </Button>
        </div>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      {/* Header with Actions */}
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-4">
          <Button
            variant="ghost"
            size="icon"
            onClick={() => router.push("/bookings")}
          >
            <ArrowLeft className="h-4 w-4" />
          </Button>
          <div>
            <h2 className="text-3xl font-bold tracking-tight">
              Chi tiết Booking
            </h2>
            <p className="text-zinc-600">
              #{booking.id?.toString().slice(0, 12)}
            </p>
          </div>
          <StatusBadge status={booking.status} />
        </div>

        {/* Admin Action Buttons */}
        <div className="flex gap-2">
          {canComplete && (
            <Button
              variant="outline"
              className="border-green-500 text-green-600 hover:bg-green-50"
              onClick={() => setCompleteDialog(true)}
            >
              <CheckCircle className="h-4 w-4 mr-2" />
              Hoàn thành
            </Button>
          )}
          {canCancel && (
            <Button
              variant="outline"
              className="border-red-500 text-red-600 hover:bg-red-50"
              onClick={() => setCancelDialog(true)}
            >
              <XCircle className="h-4 w-4 mr-2" />
              Hủy Booking
            </Button>
          )}
        </div>
      </div>

      <div className="grid gap-6 md:grid-cols-2">
        {/* Customer Information */}
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <User className="h-4 w-4" />
              Khách hàng
            </CardTitle>
          </CardHeader>
          <CardContent className="space-y-3">
            <div className="flex items-center gap-3">
              {booking.customer?.profile?.avatarUrl && (
                <img
                  src={booking.customer.profile.avatarUrl}
                  alt="Customer"
                  className="h-12 w-12 rounded-full object-cover"
                />
              )}
              <div>
                <p className="font-medium">
                  {booking.customer?.profile?.fullName || "N/A"}
                </p>
                <p className="text-sm text-zinc-600">
                  {booking.customer?.phone}
                </p>
              </div>
            </div>
          </CardContent>
        </Card>

        {/* Provider Information */}
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <User className="h-4 w-4" />
              Nhà cung cấp
            </CardTitle>
          </CardHeader>
          <CardContent className="space-y-3">
            <div className="flex items-center gap-3">
              {booking.provider?.avatarUrl && (
                <img
                  src={booking.provider.avatarUrl}
                  alt="Provider"
                  className="h-12 w-12 rounded-full object-cover"
                />
              )}
              <div>
                <p className="font-medium">
                  {booking.provider?.displayName || "Chưa được gán"}
                </p>
                <p className="text-sm text-zinc-600">
                  {booking.provider?.user?.phone}
                </p>
              </div>
            </div>
          </CardContent>
        </Card>

        {/* Service & Location */}
        <Card>
          <CardHeader>
            <CardTitle>Dịch vụ & Địa điểm</CardTitle>
          </CardHeader>
          <CardContent className="space-y-3">
            <div>
              <p className="font-medium text-lg">{booking.service?.name}</p>
              {booking.service?.category && (
                <p className="text-sm text-zinc-600">
                  {booking.service.category.name}
                </p>
              )}
            </div>
            <div className="flex items-start gap-2 pt-2 border-t">
              <MapPin className="h-4 w-4 text-zinc-500 mt-1" />
              <p className="text-sm text-zinc-600">
                {booking.addressText || "N/A"}
              </p>
            </div>
          </CardContent>
        </Card>

        {/* Schedule Information */}
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <Calendar className="h-4 w-4" />
              Thời gian
            </CardTitle>
          </CardHeader>
          <CardContent className="space-y-2">
            <div className="flex justify-between">
              <span className="text-sm text-zinc-600">Lịch hẹn</span>
              <span className="text-sm font-medium">
                {new Date(booking.scheduledAt).toLocaleString("vi-VN")}
              </span>
            </div>
            {booking.startedAt && (
              <div className="flex justify-between">
                <span className="text-sm text-zinc-600">Bắt đầu</span>
                <span className="text-sm font-medium">
                  {new Date(booking.startedAt).toLocaleString("vi-VN")}
                </span>
              </div>
            )}
            {booking.completedAt && (
              <div className="flex justify-between text-green-600">
                <span className="text-sm">Hoàn thành</span>
                <span className="text-sm font-medium">
                  {new Date(booking.completedAt).toLocaleString("vi-VN")}
                </span>
              </div>
            )}
            {booking.cancelledAt && (
              <div className="flex justify-between text-red-600">
                <span className="text-sm">Đã hủy</span>
                <span className="text-sm font-medium">
                  {new Date(booking.cancelledAt).toLocaleString("vi-VN")}
                </span>
              </div>
            )}
          </CardContent>
        </Card>

        {/* Payment Details */}
        <Card className="md:col-span-2">
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <DollarSign className="h-4 w-4" />
              Chi tiết thanh toán
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="grid md:grid-cols-4 gap-4">
              <div className="p-4 bg-zinc-50 rounded-lg">
                <p className="text-sm text-zinc-600">Giá dịch vụ</p>
                <p className="text-lg font-semibold">
                  {formatCurrency(
                    booking.actualPrice || booking.estimatedPrice || 0
                  )}
                </p>
              </div>
              <div className="p-4 bg-zinc-50 rounded-lg">
                <p className="text-sm text-zinc-600">Phí nền tảng</p>
                <p className="text-lg font-semibold">
                  {formatCurrency(booking.platformFee || 0)}
                </p>
              </div>
              <div className="p-4 bg-zinc-50 rounded-lg">
                <p className="text-sm text-zinc-600">Provider nhận</p>
                <p className="text-lg font-semibold text-green-600">
                  {formatCurrency(booking.providerEarning || 0)}
                </p>
              </div>
              <div className="p-4 bg-blue-50 rounded-lg border border-blue-200">
                <p className="text-sm text-blue-600">Tổng thanh toán</p>
                <p className="text-xl font-bold text-blue-700">
                  {formatCurrency(
                    booking.totalAmount || booking.actualPrice || 0
                  )}
                </p>
              </div>
            </div>
            <div className="flex items-center gap-4 mt-4 pt-4 border-t">
              <span className="text-sm text-zinc-600">
                Trạng thái thanh toán:
              </span>
              <StatusBadge status={booking.paymentStatus || "unpaid"} />
              {booking.paymentMethod && (
                <span className="text-sm px-2 py-1 bg-zinc-100 rounded">
                  {booking.paymentMethod === "cod"
                    ? "Tiền mặt"
                    : booking.paymentMethod.toUpperCase()}
                </span>
              )}
            </div>
          </CardContent>
        </Card>

        {/* Booking Events Timeline */}
        {booking.events && booking.events.length > 0 && (
          <Card className="md:col-span-2">
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <Clock className="h-4 w-4" />
                Lịch sử hoạt động
              </CardTitle>
            </CardHeader>
            <CardContent>
              <div className="space-y-4">
                {booking.events.map((event: any, index: number) => (
                  <div key={index} className="flex gap-4 items-start">
                    <div className="w-2 h-2 mt-2 rounded-full bg-blue-500"></div>
                    <div className="flex-1">
                      <div className="flex justify-between">
                        <p className="font-medium">
                          {event.previousStatus} → {event.newStatus}
                        </p>
                        <span className="text-sm text-zinc-500">
                          {new Date(event.createdAt).toLocaleString("vi-VN")}
                        </span>
                      </div>
                      {event.note && (
                        <p className="text-sm text-zinc-600 mt-1">
                          {event.note}
                        </p>
                      )}
                    </div>
                  </div>
                ))}
              </div>
            </CardContent>
          </Card>
        )}

        {/* Notes */}
        {booking.notes && (
          <Card className="md:col-span-2">
            <CardHeader>
              <CardTitle>Ghi chú</CardTitle>
            </CardHeader>
            <CardContent>
              <p className="text-sm text-zinc-600">{booking.notes}</p>
            </CardContent>
          </Card>
        )}
      </div>

      {/* Cancel Confirmation */}
      <ConfirmDialog
        open={cancelDialog}
        onOpenChange={setCancelDialog}
        title="Hủy Booking"
        description="Bạn có chắc chắn muốn hủy booking này? Hành động này không thể hoàn tác."
        confirmLabel="Hủy Booking"
        variant="destructive"
        onConfirm={async () => {
          await cancelMutation.mutateAsync();
        }}
      />

      {/* Complete Confirmation */}
      <ConfirmDialog
        open={completeDialog}
        onOpenChange={setCompleteDialog}
        title="Hoàn thành Booking"
        description="Bạn có chắc chắn muốn đánh dấu booking này là hoàn thành?"
        confirmLabel="Hoàn thành"
        onConfirm={async () => {
          await completeMutation.mutateAsync();
        }}
      />
    </div>
  );
}

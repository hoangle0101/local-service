"use client";

import { useState } from "react";
import { useQuery } from "@tanstack/react-query";
import { useRouter } from "next/navigation";
import { DataTable, Column } from "@/components/ui/data-table";
import { StatusBadge } from "@/components/ui/status-badge";
import { Button } from "@/components/ui/button";
import { Eye, Download } from "lucide-react";
import { api } from "@/lib/api";
import { Booking } from "@/types/booking";
import { ApiResponse, PaginatedResponse } from "@/types/system";
import { exportToCSV } from "@/lib/export";

const STATUS_LABELS: Record<string, string> = {
  pending: "Chờ xác nhận",
  accepted: "Đã xác nhận",
  in_progress: "Đang thực hiện",
  completed: "Hoàn thành",
  cancelled: "Đã hủy",
  disputed: "Tranh chấp",
};

export default function BookingsPage() {
  const router = useRouter();
  const [page, setPage] = useState(1);
  const [searchQuery, setSearchQuery] = useState("");
  const [statusFilter, setStatusFilter] = useState<string>("");

  const { data: response, isLoading } = useQuery({
    queryKey: ["admin-bookings", page, searchQuery, statusFilter],
    queryFn: async () => {
      const res = await api.get<ApiResponse<PaginatedResponse<Booking>>>(
        "/admin/bookings",
        {
          params: {
            page,
            limit: 20,
            search: searchQuery || undefined,
            status: statusFilter || undefined,
          },
        }
      );
      return res.data.data;
    },
  });

  const formatCurrency = (amount: number | string) => {
    const numAmount = typeof amount === "string" ? parseFloat(amount) : amount;
    return new Intl.NumberFormat("vi-VN", {
      style: "currency",
      currency: "VND",
    }).format(numAmount);
  };

  const columns: Column<Booking>[] = [
    {
      key: "id",
      label: "Mã đặt lịch",
      render: (booking) => (
        <span className="font-mono text-sm">
          #{booking.id?.toString().slice(0, 8) || "N/A"}
        </span>
      ),
    },
    {
      key: "customer",
      label: "Khách hàng",
      render: (booking: any) => (
        <div>
          <div className="font-medium">
            {booking.customerName ||
              booking.customer?.profile?.fullName ||
              "N/A"}
          </div>
          <div className="text-sm text-zinc-500">
            {booking.customerPhone || booking.customer?.phone}
          </div>
        </div>
      ),
    },
    {
      key: "provider",
      label: "Nhà cung cấp",
      render: (booking: any) => (
        <div>
          <div className="font-medium">
            {booking.providerName || booking.provider?.displayName || "N/A"}
          </div>
          <div className="text-sm text-zinc-500">
            {booking.providerPhone || booking.provider?.user?.phone}
          </div>
        </div>
      ),
    },
    {
      key: "service",
      label: "Dịch vụ",
      render: (booking: any) =>
        booking.serviceName || booking.service?.name || "N/A",
    },
    {
      key: "scheduledAt",
      label: "Lịch hẹn",
      sortable: true,
      render: (booking) => (
        <div className="text-sm">
          {new Date(booking.scheduledAt).toLocaleString("vi-VN")}
        </div>
      ),
    },
    {
      key: "totalAmount",
      label: "Số tiền",
      sortable: true,
      render: (booking: any) => (
        <span className="font-medium">
          {formatCurrency(
            booking.actualPrice ||
              booking.estimatedPrice ||
              booking.totalAmount ||
              0
          )}
        </span>
      ),
    },
    {
      key: "status",
      label: "Trạng thái",
      sortable: true,
      render: (booking) => <StatusBadge status={booking.status} />,
    },
    {
      key: "actions",
      label: "Thao tác",
      render: (booking) => (
        <Button
          variant="outline"
          size="sm"
          className="border-blue-200 bg-blue-50 text-blue-700 hover:bg-blue-100"
          onClick={() => router.push(`/bookings/${booking.id}`)}
        >
          <Eye className="h-4 w-4 mr-1.5" />
          Xem
        </Button>
      ),
    },
  ];

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-3xl font-bold tracking-tight">
            Quản lý Đặt lịch
          </h2>
          <p className="text-zinc-600">Theo dõi và quản lý các đặt lịch</p>
        </div>
        <Button
          variant="outline"
          onClick={() => exportToCSV(response?.data || [], "bookings_report")}
          disabled={!response?.data?.length}
        >
          <Download className="h-4 w-4 mr-2" />
          Xuất báo cáo
        </Button>
      </div>

      {/* Status Filters */}
      <div className="flex flex-wrap gap-2">
        <Button
          variant={statusFilter === "" ? "default" : "outline"}
          size="sm"
          onClick={() => setStatusFilter("")}
        >
          Tất cả
        </Button>
        {Object.entries(STATUS_LABELS).map(([status, label]) => (
          <Button
            key={status}
            variant={statusFilter === status ? "default" : "outline"}
            size="sm"
            onClick={() => setStatusFilter(status)}
          >
            {label}
          </Button>
        ))}
      </div>

      <DataTable
        data={response?.data || []}
        columns={columns}
        searchable
        searchPlaceholder="Tìm kiếm đặt lịch..."
        onSearch={setSearchQuery}
        pagination={
          response?.pagination
            ? {
                page,
                pageSize: response.pagination.limit,
                total: response.pagination.total,
                onPageChange: setPage,
              }
            : undefined
        }
        isLoading={isLoading}
        emptyMessage="Không tìm thấy đặt lịch nào"
      />
    </div>
  );
}

"use client";

import { useState } from "react";
import { useQuery } from "@tanstack/react-query";
import { DataTable, Column } from "@/components/ui/data-table";
import { StatusBadge } from "@/components/ui/status-badge";
import { Button } from "@/components/ui/button";
import { Download } from "lucide-react";
import { api } from "@/lib/api";
import { Payment } from "@/types/payment";
import { ApiResponse, PaginatedResponse } from "@/types/system";

const STATUS_LABELS: Record<string, string> = {
  pending: "Chờ xử lý",
  completed: "Hoàn thành",
  failed: "Thất bại",
  refunded: "Đã hoàn tiền",
};

export default function PaymentsPage() {
  const [page, setPage] = useState(1);
  const [searchQuery, setSearchQuery] = useState("");
  const [statusFilter, setStatusFilter] = useState<string>("");

  const { data: response, isLoading } = useQuery({
    queryKey: ["admin-payments", page, searchQuery, statusFilter],
    queryFn: async () => {
      const res = await api.get<ApiResponse<PaginatedResponse<Payment>>>(
        "/admin/payments",
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

  const columns: Column<Payment>[] = [
    {
      key: "id",
      label: "Mã giao dịch",
      render: (payment) => (
        <span className="font-mono text-sm">#{payment.id.slice(0, 8)}</span>
      ),
    },
    {
      key: "booking",
      label: "Khách hàng",
      render: (payment: any) => (
        <div>
          <div className="font-medium">
            {payment.customerPhone ||
              payment.booking?.customer?.profile?.fullName ||
              "N/A"}
          </div>
          <div className="text-sm text-zinc-500">
            {payment.customerEmail || payment.booking?.customer?.phone}
          </div>
        </div>
      ),
    },
    {
      key: "gateway",
      label: "Cổng TT",
      render: (payment) => (
        <span className="capitalize text-sm px-2 py-1 rounded bg-zinc-100 font-medium">
          {payment.gateway}
        </span>
      ),
    },
    {
      key: "amount",
      label: "Số tiền",
      sortable: true,
      render: (payment) => (
        <span className="font-medium text-green-600">
          {formatCurrency(payment.amount)}
        </span>
      ),
    },
    {
      key: "status",
      label: "Trạng thái",
      sortable: true,
      render: (payment) => <StatusBadge status={payment.status} />,
    },
    {
      key: "gatewayTransactionId",
      label: "Mã GD Cổng",
      render: (payment) =>
        payment.gatewayTransactionId ? (
          <span className="font-mono text-xs">
            {payment.gatewayTransactionId}
          </span>
        ) : (
          <span className="text-zinc-400">—</span>
        ),
    },
    {
      key: "createdAt",
      label: "Ngày tạo",
      sortable: true,
      render: (payment) => (
        <div className="text-sm">
          {new Date(payment.createdAt).toLocaleString("vi-VN")}
        </div>
      ),
    },
  ];

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-3xl font-bold tracking-tight">
            Thanh toán & Giao dịch
          </h2>
          <p className="text-zinc-600">
            Theo dõi tất cả các giao dịch tài chính
          </p>
        </div>
        <Button variant="outline">
          <Download className="h-4 w-4 mr-2" />
          Xuất báo cáo
        </Button>
      </div>

      <div className="flex gap-2">
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
        searchPlaceholder="Tìm kiếm giao dịch..."
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
        emptyMessage="Không tìm thấy giao dịch nào"
      />
    </div>
  );
}

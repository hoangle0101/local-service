"use client";

import { useState } from "react";
import { useQuery } from "@tanstack/react-query";
import { useRouter } from "next/navigation";
import { DataTable, Column } from "@/components/ui/data-table";
import { Button } from "@/components/ui/button";
import { Eye, AlertTriangle, Filter, X } from "lucide-react";
import { api } from "@/lib/api";
import {
  Dispute,
  DisputeStatus,
  DisputeCategory,
  DISPUTE_CATEGORY_LABELS,
} from "@/types/dispute";
import { ApiResponse, PaginatedResponse } from "@/types/system";
import {
  DisputeStatusBadge,
  DisputeCategoryBadge,
} from "@/components/disputes";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";

const STATUS_OPTIONS: DisputeStatus[] = [
  "open",
  "under_review",
  "awaiting_response",
  "escalated",
  "resolved",
  "closed",
  "cancelled",
];

const CATEGORY_OPTIONS: DisputeCategory[] = [
  "service_not_completed",
  "poor_quality",
  "price_disagreement",
  "no_show_provider",
  "no_show_customer",
  "damage_caused",
  "unprofessional_behavior",
  "payment_issue",
  "other",
];

export default function DisputesPage() {
  const router = useRouter();
  const [page, setPage] = useState(1);
  const [searchQuery, setSearchQuery] = useState("");
  const [statusFilter, setStatusFilter] = useState<string>("all");
  const [categoryFilter, setCategoryFilter] = useState<string>("all");

  const {
    data: response,
    isLoading,
    isError,
  } = useQuery({
    queryKey: [
      "admin-disputes",
      page,
      searchQuery,
      statusFilter,
      categoryFilter,
    ],
    queryFn: async () => {
      const res = await api.get<ApiResponse<PaginatedResponse<Dispute>>>(
        "/admin/disputes",
        {
          params: {
            page,
            limit: 20,
            search: searchQuery || undefined,
            status: statusFilter === "all" ? undefined : statusFilter,
            category: categoryFilter === "all" ? undefined : categoryFilter,
          },
        }
      );
      return res.data.data;
    },
  });

  const clearFilters = () => {
    setStatusFilter("all");
    setCategoryFilter("all");
    setSearchQuery("");
  };

  const hasActiveFilters =
    statusFilter !== "all" || categoryFilter !== "all" || searchQuery;

  const columns: Column<Dispute>[] = [
    {
      key: "id",
      label: "ID",
      render: (dispute) => (
        <span className="font-mono text-sm">
          #{String(dispute.id).slice(0, 8)}
        </span>
      ),
    },
    {
      key: "category",
      label: "Loại",
      render: (dispute) => (
        <DisputeCategoryBadge category={dispute.category || "other"} />
      ),
    },
    {
      key: "booking",
      label: "Booking",
      render: (dispute) => (
        <div>
          <div className="font-medium">
            #{String(dispute.bookingId).slice(0, 8)}
          </div>
          <div className="text-sm text-zinc-500">
            {dispute.booking?.service?.name ||
              dispute.booking?.serviceName ||
              "N/A"}
          </div>
        </div>
      ),
    },
    {
      key: "parties",
      label: "Các bên",
      render: (dispute) => (
        <div className="text-sm">
          <div>
            <span className="text-zinc-500">KH:</span>{" "}
            {dispute.booking?.customer?.phone ||
              dispute.booking?.customerPhone ||
              "N/A"}
          </div>
          <div>
            <span className="text-zinc-500">NCC:</span>{" "}
            {dispute.booking?.providerUser?.phone ||
              dispute.booking?.providerPhone ||
              "N/A"}
          </div>
        </div>
      ),
    },
    {
      key: "reason",
      label: "Lý do",
      render: (dispute) => (
        <span className="text-sm line-clamp-2 max-w-[200px]">
          {dispute.reason}
        </span>
      ),
    },
    {
      key: "status",
      label: "Trạng thái",
      sortable: true,
      render: (dispute) => <DisputeStatusBadge status={dispute.status} />,
    },
    {
      key: "createdAt",
      label: "Ngày tạo",
      sortable: true,
      render: (dispute) => (
        <div className="text-sm">
          {new Date(dispute.createdAt).toLocaleDateString("vi-VN")}
        </div>
      ),
    },
    {
      key: "actions",
      label: "Thao tác",
      render: (dispute) => (
        <Button
          variant="outline"
          size="sm"
          className="border-blue-200 bg-blue-50 text-blue-700 hover:bg-blue-100"
          onClick={() => router.push(`/disputes/${dispute.id}`)}
        >
          <Eye className="h-4 w-4 mr-1.5" />
          Xem chi tiết
        </Button>
      ),
    },
  ];

  if (isError) {
    return (
      <div className="p-8 text-center">
        <p className="text-red-500">Không thể tải danh sách tranh chấp</p>
        <Button onClick={() => window.location.reload()} className="mt-4">
          Thử lại
        </Button>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-3xl font-bold tracking-tight flex items-center gap-2">
            <AlertTriangle className="h-8 w-8 text-yellow-500" />
            Quản lý tranh chấp
          </h2>
          <p className="text-zinc-600">
            Xử lý tranh chấp và xung đột từ booking
          </p>
        </div>
      </div>

      {/* Filters */}
      <div className="flex flex-wrap gap-3 items-center p-4 bg-zinc-50 rounded-lg">
        <Filter className="h-4 w-4 text-zinc-500" />

        <Select value={statusFilter} onValueChange={setStatusFilter}>
          <SelectTrigger className="w-[180px]">
            <SelectValue placeholder="Trạng thái" />
          </SelectTrigger>
          <SelectContent>
            <SelectItem value="all">Tất cả trạng thái</SelectItem>
            {STATUS_OPTIONS.map((status) => (
              <SelectItem key={status} value={status}>
                {status.replace("_", " ")}
              </SelectItem>
            ))}
          </SelectContent>
        </Select>

        <Select value={categoryFilter} onValueChange={setCategoryFilter}>
          <SelectTrigger className="w-[220px]">
            <SelectValue placeholder="Loại tranh chấp" />
          </SelectTrigger>
          <SelectContent>
            <SelectItem value="all">Tất cả loại</SelectItem>
            {CATEGORY_OPTIONS.map((category) => (
              <SelectItem key={category} value={category}>
                {DISPUTE_CATEGORY_LABELS[category]}
              </SelectItem>
            ))}
          </SelectContent>
        </Select>

        {hasActiveFilters && (
          <Button variant="ghost" size="sm" onClick={clearFilters}>
            <X className="h-4 w-4 mr-1" />
            Xóa bộ lọc
          </Button>
        )}
      </div>

      {/* Quick Stats */}
      <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
        <div className="bg-yellow-50 p-4 rounded-lg border border-yellow-200">
          <div className="text-2xl font-bold text-yellow-700">
            {response?.data?.filter((d) => d.status === "open").length || 0}
          </div>
          <div className="text-sm text-yellow-600">Đang mở</div>
        </div>
        <div className="bg-blue-50 p-4 rounded-lg border border-blue-200">
          <div className="text-2xl font-bold text-blue-700">
            {response?.data?.filter((d) => d.status === "under_review")
              .length || 0}
          </div>
          <div className="text-sm text-blue-600">Đang xem xét</div>
        </div>
        <div className="bg-orange-50 p-4 rounded-lg border border-orange-200">
          <div className="text-2xl font-bold text-orange-700">
            {response?.data?.filter((d) => d.status === "awaiting_response")
              .length || 0}
          </div>
          <div className="text-sm text-orange-600">Chờ phản hồi</div>
        </div>
        <div className="bg-red-50 p-4 rounded-lg border border-red-200">
          <div className="text-2xl font-bold text-red-700">
            {response?.data?.filter((d) => d.status === "escalated").length ||
              0}
          </div>
          <div className="text-sm text-red-600">Đã leo thang</div>
        </div>
      </div>

      <DataTable
        data={response?.data || []}
        columns={columns}
        searchable
        searchPlaceholder="Tìm kiếm tranh chấp..."
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
        emptyMessage="Không có tranh chấp nào"
      />
    </div>
  );
}

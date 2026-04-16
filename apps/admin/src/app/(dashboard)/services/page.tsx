"use client";

import { useState } from "react";
import { useQuery } from "@tanstack/react-query";
import { useRouter } from "next/navigation";
import { DataTable, Column } from "@/components/ui/data-table";
import { StatusBadge } from "@/components/ui/status-badge";
import { Button } from "@/components/ui/button";
import { ConfirmDialog } from "@/components/ui/confirm-dialog";
import { Plus, Trash2, Eye, Power, PowerOff, FolderOpen } from "lucide-react";
import { api } from "@/lib/api";
import { Service } from "@/types/provider";
import { ApiResponse, PaginatedResponse } from "@/types/system";
import { toast } from "sonner";

export default function ServicesPage() {
  const router = useRouter();
  const [page, setPage] = useState(1);
  const [searchQuery, setSearchQuery] = useState("");
  const [statusFilter, setStatusFilter] = useState<string>("");
  const [selectedService, setSelectedService] = useState<Service | null>(null);
  const [deleteDialog, setDeleteDialog] = useState(false);

  const {
    data: response,
    isLoading,
    refetch,
  } = useQuery({
    queryKey: ["admin-services", page, searchQuery, statusFilter],
    queryFn: async () => {
      const res = await api.get<ApiResponse<any>>("/services/search", {
        params: {
          page,
          limit: 20,
          keyword: searchQuery || undefined,
        },
      });
      const rawData = res.data.data || res.data;
      return {
        data: rawData.items || rawData.data || [],
        pagination: rawData.meta
          ? {
              total: rawData.meta.total,
              limit: rawData.meta.limit,
              page: rawData.meta.page,
              totalPages: rawData.meta.totalPages,
            }
          : rawData.pagination,
      };
    },
  });

  const handleDelete = async (serviceId: number) => {
    try {
      await api.delete(`/services/${serviceId}`);
      toast.success("Đã xóa dịch vụ thành công");
      refetch();
    } catch (error: any) {
      toast.error(error.response?.data?.message || "Xóa dịch vụ thất bại");
    }
  };

  const handleToggleActive = async (service: Service) => {
    try {
      await api.put(`/services/${service.id}`, {
        ...service,
        isActive: !service.isActive,
      });
      toast.success(`Đã ${!service.isActive ? "kích hoạt" : "tắt"} dịch vụ`);
      refetch();
    } catch (error: any) {
      toast.error(error.response?.data?.message || "Cập nhật dịch vụ thất bại");
    }
  };

  const formatCurrency = (amount: number | string) => {
    const numAmount = typeof amount === "string" ? parseFloat(amount) : amount;
    return new Intl.NumberFormat("vi-VN", {
      style: "currency",
      currency: "VND",
    }).format(numAmount);
  };

  const columns: Column<Service>[] = [
    {
      key: "id",
      label: "ID",
      render: (service) => (
        <span className="font-mono text-sm">#{service.id}</span>
      ),
    },
    {
      key: "name",
      label: "Tên dịch vụ",
      sortable: true,
      render: (service) => (
        <div className="flex items-center gap-2">
          {service.imageUrl && (
            <img
              src={service.imageUrl}
              alt={service.name}
              className="h-10 w-10 rounded object-cover"
            />
          )}
          <div>
            <div className="font-medium">{service.name}</div>
            {service.description && (
              <div className="text-xs text-zinc-500 line-clamp-1">
                {service.description}
              </div>
            )}
          </div>
        </div>
      ),
    },
    {
      key: "category",
      label: "Danh mục",
      render: (service) => service.category?.name || "—",
    },
    {
      key: "basePrice",
      label: "Giá cơ bản",
      sortable: true,
      render: (service) => (
        <span className="font-medium">{formatCurrency(service.basePrice)}</span>
      ),
    },
    {
      key: "durationMinutes",
      label: "Thời lượng",
      render: (service) => <span>{service.durationMinutes} phút</span>,
    },
    {
      key: "isActive",
      label: "Trạng thái",
      sortable: true,
      render: (service) => (
        <StatusBadge status={service.isActive ? "active" : "inactive"} />
      ),
    },
    {
      key: "actions",
      label: "Thao tác",
      render: (service) => (
        <div className="flex items-center gap-2">
          <Button
            variant="outline"
            size="sm"
            className="border-blue-200 bg-blue-50 text-blue-700 hover:bg-blue-100"
            onClick={() => router.push(`/services/${service.id}`)}
          >
            <Eye className="h-4 w-4 mr-1.5" />
            Xem
          </Button>

          <Button
            variant="outline"
            size="sm"
            className={
              service.isActive
                ? "border-orange-200 bg-orange-50 text-orange-700 hover:bg-orange-100"
                : "border-green-200 bg-green-50 text-green-700 hover:bg-green-100"
            }
            onClick={() => handleToggleActive(service)}
          >
            {service.isActive ? (
              <>
                <PowerOff className="h-4 w-4 mr-1.5" />
                Tắt
              </>
            ) : (
              <>
                <Power className="h-4 w-4 mr-1.5" />
                Bật
              </>
            )}
          </Button>

          <Button
            variant="outline"
            size="sm"
            className="border-red-200 bg-red-50 text-red-700 hover:bg-red-100"
            onClick={() => {
              setSelectedService(service);
              setDeleteDialog(true);
            }}
          >
            <Trash2 className="h-4 w-4 mr-1.5" />
            Xóa
          </Button>
        </div>
      ),
    },
  ];

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-3xl font-bold tracking-tight">Quản lý Dịch vụ</h2>
          <p className="text-zinc-600">Quản lý tất cả dịch vụ trên nền tảng</p>
        </div>
        <div className="flex gap-2">
          <Button
            variant="outline"
            onClick={() => router.push("/services/categories")}
          >
            <FolderOpen className="h-4 w-4 mr-2" />
            Quản lý danh mục
          </Button>
          <Button onClick={() => router.push("/services/new")}>
            <Plus className="h-4 w-4 mr-2" />
            Thêm dịch vụ
          </Button>
        </div>
      </div>

      <div className="flex gap-2">
        <Button
          variant={statusFilter === "" ? "default" : "outline"}
          size="sm"
          onClick={() => setStatusFilter("")}
        >
          Tất cả
        </Button>
        <Button
          variant={statusFilter === "active" ? "default" : "outline"}
          size="sm"
          onClick={() => setStatusFilter("active")}
        >
          Đang hoạt động
        </Button>
        <Button
          variant={statusFilter === "inactive" ? "default" : "outline"}
          size="sm"
          onClick={() => setStatusFilter("inactive")}
        >
          Không hoạt động
        </Button>
      </div>

      <DataTable
        data={response?.data || []}
        columns={columns}
        searchable
        searchPlaceholder="Tìm kiếm dịch vụ..."
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
        emptyMessage="Không tìm thấy dịch vụ nào"
      />

      <ConfirmDialog
        open={deleteDialog}
        onOpenChange={setDeleteDialog}
        title="Xóa dịch vụ"
        description={`Bạn có chắc muốn xóa "${selectedService?.name}"? Hành động này không thể hoàn tác.`}
        confirmLabel="Xóa"
        variant="destructive"
        onConfirm={async () => {
          if (selectedService) {
            await handleDelete(selectedService.id);
          }
        }}
      />
    </div>
  );
}

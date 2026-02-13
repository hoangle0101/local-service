"use client";

import { useState } from "react";
import { useQuery } from "@tanstack/react-query";
import { useRouter } from "next/navigation";
import { DataTable, Column } from "@/components/ui/data-table";
import { StatusBadge } from "@/components/ui/status-badge";
import { Button } from "@/components/ui/button";
import { ConfirmDialog } from "@/components/ui/confirm-dialog";
import { Eye, Ban, CheckCircle, ShieldCheck } from "lucide-react";
import { api } from "@/lib/api";
import { User } from "@/types/user";
import { ApiResponse, PaginatedResponse } from "@/types/system";
import { toast } from "sonner";

export default function CustomersPage() {
  const router = useRouter();
  const [page, setPage] = useState(1);
  const [searchQuery, setSearchQuery] = useState("");
  const [selectedUser, setSelectedUser] = useState<User | null>(null);
  const [actionDialog, setActionDialog] = useState<{
    open: boolean;
    action: "ban" | "unban" | "verify" | "unverify" | null;
  }>({ open: false, action: null });

  const {
    data: response,
    isLoading,
    refetch,
  } = useQuery({
    queryKey: ["admin-users", page, searchQuery],
    queryFn: async () => {
      const res = await api.get<ApiResponse<PaginatedResponse<User>>>(
        "/admin/users",
        {
          params: {
            page,
            limit: 20,
            search: searchQuery || undefined,
            role: "customer",
          },
        }
      );
      return res.data.data;
    },
  });

  const handleStatusChange = async (
    userId: string,
    action: "ban" | "unban" | "verify" | "unverify"
  ) => {
    try {
      if (action === "ban" || action === "unban") {
        await api.patch(`/admin/users/${userId}/ban`, {
          action,
          reason:
            action === "ban" ? "Bị khóa bởi admin" : "Được mở khóa bởi admin",
        });
        toast.success(
          `Đã ${action === "ban" ? "khóa" : "mở khóa"} tài khoản thành công`
        );
      } else {
        await api.patch(`/admin/users/${userId}/verify`, {
          isVerified: action === "verify",
        });
        toast.success(
          `Đã ${
            action === "verify" ? "xác thực" : "hủy xác thực"
          } tài khoản thành công`
        );
      }
      refetch();
    } catch (error: any) {
      toast.error(error.response?.data?.message || "Thao tác thất bại");
    }
  };

  const columns: Column<User>[] = [
    {
      key: "id",
      label: "ID",
      render: (user) => (
        <span className="font-mono text-sm">#{user.id.slice(0, 8)}</span>
      ),
    },
    {
      key: "phone",
      label: "Số điện thoại",
      sortable: true,
    },
    {
      key: "email",
      label: "Email",
      render: (user) => user.email || <span className="text-zinc-400">—</span>,
    },
    {
      key: "profile",
      label: "Họ và tên",
      render: (user: any) => (
        <span>
          {user.fullName || user.profile?.fullName || (
            <span className="text-zinc-400">Chưa cập nhật</span>
          )}
        </span>
      ),
    },
    {
      key: "status",
      label: "Trạng thái",
      sortable: true,
      render: (user) => <StatusBadge status={user.status} />,
    },
    {
      key: "isVerified",
      label: "Xác thực",
      render: (user) => (
        <span
          className={`inline-flex items-center px-2 py-1 rounded text-xs ${
            user.isVerified
              ? "bg-green-100 text-green-700"
              : "bg-zinc-100 text-zinc-500"
          }`}
        >
          <ShieldCheck className="h-3 w-3 mr-1" />
          {user.isVerified ? "Đã xác thực" : "Chưa xác thực"}
        </span>
      ),
    },
    {
      key: "createdAt",
      label: "Ngày tham gia",
      sortable: true,
      render: (user) => new Date(user.createdAt).toLocaleDateString("vi-VN"),
    },
    {
      key: "actions",
      label: "Thao tác",
      render: (user) => (
        <div className="flex items-center gap-2">
          <Button
            variant="outline"
            size="sm"
            className="border-blue-200 bg-blue-50 text-blue-700 hover:bg-blue-100"
            onClick={() => router.push(`/customers/${user.id}`)}
          >
            <Eye className="h-4 w-4 mr-1.5" />
            Xem
          </Button>

          {user.status === "active" ? (
            <Button
              variant="outline"
              size="sm"
              className="border-red-200 bg-red-50 text-red-700 hover:bg-red-100"
              onClick={() => {
                setSelectedUser(user);
                setActionDialog({ open: true, action: "ban" });
              }}
            >
              <Ban className="h-4 w-4 mr-1.5" />
              Khóa
            </Button>
          ) : user.status === "banned" ? (
            <Button
              variant="outline"
              size="sm"
              className="border-green-200 bg-green-50 text-green-700 hover:bg-green-100"
              onClick={() => {
                setSelectedUser(user);
                setActionDialog({ open: true, action: "unban" });
              }}
            >
              <CheckCircle className="h-4 w-4 mr-1.5" />
              Mở khóa
            </Button>
          ) : null}

          {!user.isVerified && (
            <Button
              variant="outline"
              size="sm"
              className="border-green-200 bg-green-50 text-green-700 hover:bg-green-100"
              onClick={() => {
                setSelectedUser(user);
                setActionDialog({ open: true, action: "verify" });
              }}
            >
              <ShieldCheck className="h-4 w-4 mr-1.5" />
              Xác thực
            </Button>
          )}
        </div>
      ),
    },
  ];

  return (
    <div className="space-y-6">
      <div>
        <h2 className="text-3xl font-bold tracking-tight">
          Quản lý Khách hàng
        </h2>
        <p className="text-zinc-600">Quản lý tất cả khách hàng trên nền tảng</p>
      </div>

      <DataTable
        data={response?.data || []}
        columns={columns}
        searchable
        searchPlaceholder="Tìm theo SĐT, email hoặc tên..."
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
        emptyMessage="Không tìm thấy khách hàng nào"
      />

      <ConfirmDialog
        open={actionDialog.open}
        onOpenChange={(open) => setActionDialog({ open, action: null })}
        title={
          actionDialog.action === "ban"
            ? "Khóa tài khoản"
            : actionDialog.action === "unban"
            ? "Mở khóa tài khoản"
            : actionDialog.action === "verify"
            ? "Xác thực tài khoản"
            : "Hủy xác thực tài khoản"
        }
        description={
          actionDialog.action === "ban"
            ? `Bạn có chắc muốn khóa tài khoản ${selectedUser?.phone}? Họ sẽ không thể truy cập nền tảng.`
            : actionDialog.action === "unban"
            ? `Mở khóa tài khoản cho ${selectedUser?.phone}?`
            : actionDialog.action === "verify"
            ? `Xác thực thủ công tài khoản ${selectedUser?.phone}?`
            : `Hủy xác thực tài khoản ${selectedUser?.phone}?`
        }
        confirmLabel={
          actionDialog.action === "ban"
            ? "Khóa"
            : actionDialog.action === "unban"
            ? "Mở khóa"
            : actionDialog.action === "verify"
            ? "Xác thực"
            : "Hủy xác thực"
        }
        variant={
          actionDialog.action === "ban" || actionDialog.action === "unverify"
            ? "destructive"
            : "default"
        }
        onConfirm={async () => {
          if (selectedUser && actionDialog.action) {
            await handleStatusChange(selectedUser.id, actionDialog.action);
          }
        }}
      />
    </div>
  );
}

"use client";

import { useState } from "react";
import { useQuery } from "@tanstack/react-query";
import { useRouter } from "next/navigation";
import { DataTable, Column } from "@/components/ui/data-table";
import { StatusBadge } from "@/components/ui/status-badge";
import { Button } from "@/components/ui/button";
import { ConfirmDialog } from "@/components/ui/confirm-dialog";
import { Eye, CheckCircle, XCircle, Ban, ShieldCheck } from "lucide-react";
import { api } from "@/lib/api";
import { Provider } from "@/types/provider";
import { ApiResponse, PaginatedResponse } from "@/types/system";
import { toast } from "sonner";

export default function ProvidersPage() {
  const router = useRouter();
  const [page, setPage] = useState(1);
  const [searchQuery, setSearchQuery] = useState("");
  const [statusFilter, setStatusFilter] = useState<string>("");
  const [selectedProvider, setSelectedProvider] = useState<Provider | null>(
    null
  );
  const [actionDialog, setActionDialog] = useState<{
    open: boolean;
    action:
      | "verify"
      | "reject"
      | "ban"
      | "unban"
      | "verify_account"
      | "unverify_account"
      | null;
  }>({ open: false, action: null });

  const statusOptions = ["pending", "verified", "rejected"];

  const {
    data: response,
    isLoading,
    refetch,
  } = useQuery({
    queryKey: ["admin-providers", page, searchQuery, statusFilter],
    queryFn: async () => {
      const res = await api.get<ApiResponse<PaginatedResponse<Provider>>>(
        "/admin/providers",
        {
          params: {
            page,
            limit: 20,
            search: searchQuery || undefined,
            verificationStatus: statusFilter || undefined,
          },
        }
      );
      return res.data.data;
    },
  });

  const handleProviderAction = async (providerId: string, action: string) => {
    try {
      if (action === "verify" || action === "reject") {
        await api.patch(`/admin/providers/${providerId}/verify`, {
          action: action === "verify" ? "verified" : "rejected",
          adminNotes: `Provider ${
            action === "verify" ? "verified" : "rejected"
          } by admin`,
        });
        toast.success(
          `Provider ${
            action === "verify" ? "verified" : "rejected"
          } successfully`
        );
      } else if (action === "ban" || action === "unban") {
        await api.patch(`/admin/users/${providerId}/ban`, {
          action: action === "ban" ? "ban" : "unban",
          reason:
            action === "ban"
              ? "Provider suspended by admin"
              : "Provider reactivated by admin",
        });
        toast.success(
          `Provider ${action === "ban" ? "banned" : "unbanned"} successfully`
        );
      } else if (action === "verify_account" || action === "unverify_account") {
        await api.patch(`/admin/users/${providerId}/verify`, {
          isVerified: action === "verify_account",
        });
        toast.success(
          `User account ${
            action === "verify_account" ? "verified" : "unverified"
          } successfully`
        );
      }
      refetch();
    } catch (error: any) {
      toast.error(
        error.response?.data?.message || `Failed to ${action} provider`
      );
    }
  };

  const columns: Column<Provider>[] = [
    {
      key: "userId",
      label: "ID",
      render: (provider) => (
        <span className="font-mono text-sm">
          #{provider.userId?.toString().slice(0, 8) || "N/A"}
        </span>
      ),
    },
    {
      key: "displayName",
      label: "Business Name",
      sortable: true,
      render: (provider) => (
        <div className="flex items-center gap-2">
          {provider.avatarUrl ? (
            <img
              src={provider.avatarUrl}
              alt={provider.displayName}
              className="h-8 w-8 rounded-full object-cover border border-zinc-200"
            />
          ) : (
            <div className="h-8 w-8 rounded-full bg-zinc-100 flex items-center justify-center text-xs text-zinc-400">
              {provider.displayName.charAt(0)}
            </div>
          )}
          <span className="font-medium">{provider.displayName}</span>
        </div>
      ),
    },
    {
      key: "phone",
      label: "Phone",
      render: (provider) => (
        <div className="flex items-center gap-1.5">
          <span className="text-sm">{provider.user?.phone || "—"}</span>
          {provider.user?.isVerified ? (
            <span title="Phone Verified">
              <ShieldCheck className="h-3.5 w-3.5 text-green-500" />
            </span>
          ) : (
            <span title="Phone Not Verified">
              <ShieldCheck className="h-3.5 w-3.5 text-zinc-300" />
            </span>
          )}
        </div>
      ),
    },
    {
      key: "owner",
      label: "Owner",
      render: (provider) => (
        <span className="text-sm">
          {provider.user?.profile?.fullName || (
            <span className="text-zinc-400">—</span>
          )}
        </span>
      ),
    },
    {
      key: "rating",
      label: "Rating",
      sortable: true,
      render: (provider) => {
        const avgRating =
          typeof provider.rating === "object" && provider.rating?.average
            ? provider.rating.average
            : typeof provider.rating === "number"
            ? provider.rating
            : 0;
        const reviewCount =
          typeof provider.rating === "object" && provider.rating?.count
            ? provider.rating.count
            : provider.totalReviews || 0;

        return (
          <div className="flex items-center gap-1 text-sm">
            <span className="text-yellow-500">★</span>
            <span className="font-medium">{Number(avgRating).toFixed(1)}</span>
            <span className="text-zinc-400">({reviewCount})</span>
          </div>
        );
      },
    },
    {
      key: "verificationStatus",
      label: "Work Status",
      sortable: true,
      render: (provider) => (
        <StatusBadge status={provider.verificationStatus} />
      ),
    },
    {
      key: "userStatus",
      label: "Account",
      render: (provider) => (
        <StatusBadge status={provider.user?.status || "active"} />
      ),
    },
    {
      key: "createdAt",
      label: "Joined",
      sortable: true,
      render: (provider) => (
        <span className="text-sm">
          {new Date(provider.createdAt).toLocaleDateString("vi-VN")}
        </span>
      ),
    },
    {
      key: "actions",
      label: "Thao tác",
      render: (provider) => (
        <div className="flex items-center gap-2">
          {/* View Details - Always visible */}
          <Button
            variant="outline"
            size="sm"
            className="border-blue-200 bg-blue-50 text-blue-700 hover:bg-blue-100"
            onClick={() => router.push(`/providers/${provider.userId}`)}
          >
            <Eye className="h-4 w-4 mr-1.5" />
            Xem
          </Button>

          {/* Provider Business Verification - show for pending or unverified */}
          {(provider.verificationStatus === "pending" ||
            provider.verificationStatus === "unverified") && (
            <>
              <Button
                variant="outline"
                size="sm"
                className="border-green-200 bg-green-50 text-green-700 hover:bg-green-100"
                onClick={() => {
                  setSelectedProvider(provider);
                  setActionDialog({ open: true, action: "verify" });
                }}
              >
                <CheckCircle className="h-4 w-4 mr-1.5" />
                Duyệt
              </Button>
              <Button
                variant="outline"
                size="sm"
                className="border-red-200 bg-red-50 text-red-700 hover:bg-red-100"
                onClick={() => {
                  setSelectedProvider(provider);
                  setActionDialog({ open: true, action: "reject" });
                }}
              >
                <XCircle className="h-4 w-4 mr-1.5" />
                Từ chối
              </Button>
            </>
          )}

          {/* Revoke for verified providers */}
          {provider.verificationStatus === "verified" && (
            <Button
              variant="outline"
              size="sm"
              className="border-orange-200 bg-orange-50 text-orange-700 hover:bg-orange-100"
              onClick={() => {
                setSelectedProvider(provider);
                setActionDialog({ open: true, action: "reject" });
              }}
            >
              <XCircle className="h-4 w-4 mr-1.5" />
              Thu hồi
            </Button>
          )}

          {/* Ban/Unban Account */}
          {provider.user?.status === "active" ? (
            <Button
              variant="outline"
              size="sm"
              className="border-red-200 bg-red-50 text-red-700 hover:bg-red-100"
              onClick={() => {
                setSelectedProvider(provider);
                setActionDialog({ open: true, action: "ban" });
              }}
            >
              <Ban className="h-4 w-4 mr-1.5" />
              Khóa TK
            </Button>
          ) : provider.user?.status === "banned" ? (
            <Button
              variant="outline"
              size="sm"
              className="border-green-200 bg-green-50 text-green-700 hover:bg-green-100"
              onClick={() => {
                setSelectedProvider(provider);
                setActionDialog({ open: true, action: "unban" });
              }}
            >
              <CheckCircle className="h-4 w-4 mr-1.5" />
              Mở khóa
            </Button>
          ) : null}

          {/* Phone Verification Badge */}
          {provider.user && (
            <span
              className={`inline-flex items-center px-2 py-1 rounded text-xs ${
                provider.user.isVerified
                  ? "bg-green-100 text-green-700"
                  : "bg-zinc-100 text-zinc-500"
              }`}
              title={
                provider.user.isVerified
                  ? "Đã xác thực SĐT"
                  : "Chưa xác thực SĐT"
              }
            >
              <ShieldCheck className="h-3 w-3 mr-1" />
              {provider.user.isVerified ? "Đã xác thực" : "Chưa xác thực"}
            </span>
          )}
        </div>
      ),
    },
  ];

  return (
    <div className="space-y-6">
      <div>
        <h2 className="text-3xl font-bold tracking-tight">
          Quản lý Nhà cung cấp
        </h2>
        <p className="text-zinc-600">Quản lý và duyệt nhà cung cấp dịch vụ</p>
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
          variant={statusFilter === "pending" ? "default" : "outline"}
          size="sm"
          onClick={() => setStatusFilter("pending")}
        >
          Chờ duyệt
        </Button>
        <Button
          variant={statusFilter === "verified" ? "default" : "outline"}
          size="sm"
          onClick={() => setStatusFilter("verified")}
        >
          Đã duyệt
        </Button>
        <Button
          variant={statusFilter === "rejected" ? "default" : "outline"}
          size="sm"
          onClick={() => setStatusFilter("rejected")}
        >
          Đã từ chối
        </Button>
      </div>

      <DataTable
        data={response?.data || []}
        columns={columns}
        searchable
        searchPlaceholder="Search by business name, phone, or owner..."
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
        emptyMessage="No providers found"
      />

      <ConfirmDialog
        open={actionDialog.open}
        onOpenChange={(open) => setActionDialog({ open, action: null })}
        title={
          actionDialog.action === "verify"
            ? "Phê duyệt nhà cung cấp"
            : actionDialog.action === "reject"
            ? "Từ chối/Thu hồi nhà cung cấp"
            : actionDialog.action === "unban"
            ? "Mở khóa tài khoản"
            : actionDialog.action === "verify_account"
            ? "Xác thực tài khoản"
            : actionDialog.action === "unverify_account"
            ? "Hủy xác thực tài khoản"
            : "Khóa tài khoản"
        }
        description={
          actionDialog.action === "verify"
            ? `Phê duyệt "${selectedProvider?.displayName}" làm nhà cung cấp dịch vụ?`
            : actionDialog.action === "reject"
            ? `Từ chối hoặc thu hồi trạng thái nhà cung cấp của "${selectedProvider?.displayName}"?`
            : actionDialog.action === "unban"
            ? `Mở khóa tài khoản cho "${selectedProvider?.displayName}"?`
            : actionDialog.action === "verify_account"
            ? `Xác thực thủ công tài khoản cho "${selectedProvider?.displayName}"?`
            : actionDialog.action === "unverify_account"
            ? `Hủy xác thực tài khoản cho "${selectedProvider?.displayName}"?`
            : `Bạn có chắc muốn khóa "${selectedProvider?.displayName}"? Họ sẽ không thể sử dụng nền tảng.`
        }
        confirmLabel={
          actionDialog.action === "verify"
            ? "Phê duyệt"
            : actionDialog.action === "reject"
            ? "Từ chối"
            : actionDialog.action === "unban"
            ? "Mở khóa"
            : actionDialog.action === "verify_account"
            ? "Xác thực"
            : actionDialog.action === "unverify_account"
            ? "Hủy xác thực"
            : "Khóa"
        }
        variant={
          actionDialog.action === "reject" ||
          actionDialog.action === "ban" ||
          actionDialog.action === "unverify_account"
            ? "destructive"
            : "default"
        }
        onConfirm={async () => {
          if (selectedProvider && actionDialog.action) {
            await handleProviderAction(
              selectedProvider.userId,
              actionDialog.action
            );
          }
        }}
      />
    </div>
  );
}

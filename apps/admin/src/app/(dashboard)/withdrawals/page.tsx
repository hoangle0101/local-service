"use client";

import { useState } from "react";
import { useQuery } from "@tanstack/react-query";
import { DataTable, Column } from "@/components/ui/data-table";
import { StatusBadge } from "@/components/ui/status-badge";
import { Button } from "@/components/ui/button";
import { ConfirmDialog } from "@/components/ui/confirm-dialog";
import { CheckCircle, XCircle } from "lucide-react";
import { api } from "@/lib/api";
import { WithdrawalRequest } from "@/types/payment";
import { ApiResponse, PaginatedResponse } from "@/types/system";
import { toast } from "sonner";

export default function WithdrawalsPage() {
  const [page, setPage] = useState(1);
  const [statusFilter, setStatusFilter] = useState<string>("");
  const [selectedRequest, setSelectedRequest] =
    useState<WithdrawalRequest | null>(null);
  const [actionDialog, setActionDialog] = useState<{
    open: boolean;
    action: "approve" | "reject" | null;
  }>({ open: false, action: null });

  const {
    data: response,
    isLoading,
    refetch,
  } = useQuery({
    queryKey: ["admin-withdrawals", page, statusFilter],
    queryFn: async () => {
      const res = await api.get<
        ApiResponse<PaginatedResponse<WithdrawalRequest>>
      >("/admin/withdrawals", {
        params: {
          page,
          limit: 20,
          status: statusFilter || undefined,
        },
      });
      return res.data.data;
    },
  });

  const handleAction = async (id: string, action: "approve" | "reject") => {
    try {
      if (action === "approve") {
        await api.patch(`/admin/withdrawals/${id}/approve`, {
          approvalNotes: "Được duyệt bởi admin",
        });
        toast.success("Đã duyệt yêu cầu rút tiền thành công");
      } else {
        await api.patch(`/admin/withdrawals/${id}/reject`, {
          rejectionReason: "Bị từ chối bởi admin",
          refundToWallet: true,
        });
        toast.success("Đã từ chối và hoàn tiền vào ví");
      }
      refetch();
    } catch (error: any) {
      toast.error(error.response?.data?.message || `Thao tác thất bại`);
    }
  };

  const formatCurrency = (amount: number | string) => {
    const numAmount = typeof amount === "string" ? parseFloat(amount) : amount;
    return new Intl.NumberFormat("vi-VN", {
      style: "currency",
      currency: "VND",
    }).format(numAmount);
  };

  const columns: Column<WithdrawalRequest>[] = [
    {
      key: "id",
      label: "ID",
      render: (req) => (
        <span className="font-mono text-sm">
          #{req.id?.toString().slice(0, 8) || "N/A"}
        </span>
      ),
    },
    {
      key: "wallet",
      label: "Người dùng",
      render: (req: any) => (
        <div>
          <div className="font-medium">
            {req.user?.fullName || req.wallet?.user?.profile?.fullName || "N/A"}
          </div>
          <div className="text-sm text-zinc-500">
            {req.user?.phone || req.wallet?.user?.phone}
          </div>
        </div>
      ),
    },
    {
      key: "amount",
      label: "Số tiền",
      sortable: true,
      render: (req) => (
        <span className="font-medium text-lg text-red-600">
          {formatCurrency(req.amount)}
        </span>
      ),
    },
    {
      key: "metadata",
      label: "Thông tin ngân hàng",
      render: (req) => (
        <div className="text-sm">
          <div>{req.metadata?.bankName}</div>
          <div className="font-mono text-zinc-500">
            {req.metadata?.bankAccount}
          </div>
        </div>
      ),
    },
    {
      key: "status",
      label: "Trạng thái",
      render: (req) => <StatusBadge status={req.status} />,
    },
    {
      key: "createdAt",
      label: "Ngày tạo",
      render: (req) => new Date(req.createdAt).toLocaleString("vi-VN"),
    },
    {
      key: "actions",
      label: "Thao tác",
      render: (req) =>
        req.status === "pending" && (
          <div className="flex gap-2">
            <Button
              variant="outline"
              size="sm"
              className="border-green-200 bg-green-50 text-green-700 hover:bg-green-100"
              onClick={() => {
                setSelectedRequest(req);
                setActionDialog({ open: true, action: "approve" });
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
                setSelectedRequest(req);
                setActionDialog({ open: true, action: "reject" });
              }}
            >
              <XCircle className="h-4 w-4 mr-1.5" />
              Từ chối
            </Button>
          </div>
        ),
    },
  ];

  return (
    <div className="space-y-6">
      <div>
        <h2 className="text-3xl font-bold tracking-tight">Quản lý Rút tiền</h2>
        <p className="text-zinc-600">Duyệt và xử lý các yêu cầu rút tiền</p>
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
          variant={statusFilter === "approved" ? "default" : "outline"}
          size="sm"
          onClick={() => setStatusFilter("approved")}
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
        emptyMessage="Không có yêu cầu rút tiền nào"
      />

      <ConfirmDialog
        open={actionDialog.open}
        onOpenChange={(open) => setActionDialog({ open, action: null })}
        title={
          actionDialog.action === "approve"
            ? "Duyệt yêu cầu rút tiền"
            : "Từ chối yêu cầu rút tiền"
        }
        description={`Bạn có chắc muốn ${
          actionDialog.action === "approve" ? "duyệt" : "từ chối"
        } yêu cầu rút tiền ${
          selectedRequest ? formatCurrency(selectedRequest.amount) : ""
        }?`}
        confirmLabel={actionDialog.action === "approve" ? "Duyệt" : "Từ chối"}
        variant={actionDialog.action === "approve" ? "default" : "destructive"}
        onConfirm={async () => {
          if (selectedRequest && actionDialog.action) {
            await handleAction(selectedRequest.id, actionDialog.action);
          }
        }}
      />
    </div>
  );
}

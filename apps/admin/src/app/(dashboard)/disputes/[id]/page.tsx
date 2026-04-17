"use client";

import { useState } from "react";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { useParams, useRouter } from "next/navigation";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import {
  ArrowLeft,
  AlertTriangle,
  Clock,
  CheckCircle,
  MessageCircle,
  ArrowUp,
  Loader2,
} from "lucide-react";
import { api } from "@/lib/api";
import {
  Dispute,
  ResolveDisputeInput,
  DISPUTE_CATEGORY_LABELS,
  RESOLUTION_TYPE_LABELS,
} from "@/types/dispute";
import { ApiResponse } from "@/types/system";
import { toast } from "sonner";
import {
  DisputeStatusBadge,
  DisputeCategoryBadge,
  DisputeTimeline,
  EvidenceViewer,
  ResolveDisputeModal,
} from "@/components/disputes";

export default function DisputeDetailPage() {
  const params = useParams();
  const router = useRouter();
  const queryClient = useQueryClient();
  const disputeId = params.id as string;

  const [isResolveModalOpen, setIsResolveModalOpen] = useState(false);

  // Fetch dispute detail with timeline and evidence
  const {
    data: dispute,
    isLoading,
    isError,
  } = useQuery({
    queryKey: ["admin-dispute-detail", disputeId],
    queryFn: async () => {
      const res = await api.get(`/admin/disputes/${disputeId}`, {
        params: {
          includeTimeline: "true",
          includeEvidence: "true",
        },
      });
      // Backend returns { data: { data: dispute } } or { data: dispute }
      const outerData = res.data?.data;
      const disputeData = outerData?.data || outerData;
      console.log("Dispute API response:", disputeData);
      return disputeData as Dispute;
    },
  });

  // Resolve mutation
  const resolveMutation = useMutation({
    mutationFn: async (data: ResolveDisputeInput) => {
      const res = await api.post(`/admin/disputes/${disputeId}/resolve`, data);
      return res.data;
    },
    onSuccess: () => {
      toast.success("Đã giải quyết tranh chấp thành công");
      setIsResolveModalOpen(false);
      queryClient.invalidateQueries({
        queryKey: ["admin-dispute-detail", disputeId],
      });
    },
    onError: (error: any) => {
      toast.error(
        error.response?.data?.message || "Không thể giải quyết tranh chấp"
      );
    },
  });

  // Escalate mutation
  const escalateMutation = useMutation({
    mutationFn: async () => {
      const res = await api.post(`/admin/disputes/${disputeId}/escalate`, {
        reason: "Escalated by admin",
      });
      return res.data;
    },
    onSuccess: () => {
      toast.success("Đã leo thang tranh chấp");
      queryClient.invalidateQueries({
        queryKey: ["admin-dispute-detail", disputeId],
      });
    },
    onError: (error: any) => {
      toast.error(error.response?.data?.message || "Không thể leo thang");
    },
  });

  // Request response mutation
  const requestResponseMutation = useMutation({
    mutationFn: async (targetParty: "customer" | "provider") => {
      const res = await api.post(
        `/admin/disputes/${disputeId}/request-response`,
        {
          targetParty,
          deadlineHours: 48,
        }
      );
      return res.data;
    },
    onSuccess: () => {
      toast.success("Đã yêu cầu phản hồi");
      queryClient.invalidateQueries({
        queryKey: ["admin-dispute-detail", disputeId],
      });
    },
    onError: (error: any) => {
      toast.error(
        error.response?.data?.message || "Không thể yêu cầu phản hồi"
      );
    },
  });

  // Format currency
  const formatCurrency = (amount: number | string | null | undefined) => {
    if (amount === null || amount === undefined) return "₫0";
    const numAmount = typeof amount === "string" ? parseFloat(amount) : amount;
    return new Intl.NumberFormat("vi-VN", {
      style: "currency",
      currency: "VND",
    }).format(numAmount);
  };

  if (isLoading) {
    return (
      <div className="flex items-center justify-center h-96">
        <Loader2 className="h-8 w-8 animate-spin text-zinc-400" />
      </div>
    );
  }

  if (isError || !dispute) {
    return (
      <div className="flex flex-col items-center justify-center h-96">
        <AlertTriangle className="h-12 w-12 text-red-500 mb-4" />
        <p className="text-lg text-zinc-600">Không tìm thấy tranh chấp</p>
        <Button onClick={() => router.push("/disputes")} className="mt-4">
          Quay lại danh sách
        </Button>
      </div>
    );
  }

  const canResolve = [
    "open",
    "under_review",
    "awaiting_response",
    "escalated",
  ].includes(dispute.status);
  const canEscalate = ["open", "under_review"].includes(dispute.status);
  const canRequestResponse = ["open", "under_review"].includes(dispute.status);

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center gap-4">
        <Button
          variant="ghost"
          size="icon"
          onClick={() => router.push("/disputes")}
        >
          <ArrowLeft className="h-4 w-4" />
        </Button>
        <div className="flex-1">
          <h2 className="text-2xl font-bold flex items-center gap-2">
            <AlertTriangle className="h-6 w-6 text-yellow-500" />
            Tranh chấp #{String(dispute.id).slice(0, 8)}
          </h2>
          <div className="flex items-center gap-2 mt-1">
            <DisputeStatusBadge status={dispute.status} />
            <DisputeCategoryBadge category={dispute.category} />
            {dispute.appealCount > 0 && (
              <span className="text-xs bg-orange-100 text-orange-700 px-2 py-0.5 rounded">
                Kháng cáo #{dispute.appealCount}
              </span>
            )}
          </div>
        </div>

        {/* Action Buttons - Redesigned */}
        <div className="flex flex-wrap gap-3">
          {canRequestResponse && (
            <Button
              variant="outline"
              className="border-blue-200 bg-blue-50 text-blue-700 hover:bg-blue-100 hover:border-blue-300"
              onClick={() => requestResponseMutation.mutate("provider")}
              disabled={requestResponseMutation.isPending}
            >
              {requestResponseMutation.isPending ? (
                <Loader2 className="h-4 w-4 mr-2 animate-spin" />
              ) : (
                <MessageCircle className="h-4 w-4 mr-2" />
              )}
              Yêu cầu phản hồi
            </Button>
          )}
          {canEscalate && (
            <Button
              variant="outline"
              className="border-orange-200 bg-orange-50 text-orange-700 hover:bg-orange-100 hover:border-orange-300"
              onClick={() => escalateMutation.mutate()}
              disabled={escalateMutation.isPending}
            >
              {escalateMutation.isPending ? (
                <Loader2 className="h-4 w-4 mr-2 animate-spin" />
              ) : (
                <ArrowUp className="h-4 w-4 mr-2" />
              )}
              Ưu tiên xử lý
            </Button>
          )}
          {canResolve && (
            <Button
              className="bg-green-600 hover:bg-green-700 text-white shadow-md"
              onClick={() => setIsResolveModalOpen(true)}
            >
              <CheckCircle className="h-4 w-4 mr-2" />
              Giải quyết tranh chấp
            </Button>
          )}
        </div>
      </div>

      {/* Content Grid */}
      <div className="grid gap-6 lg:grid-cols-3">
        {/* Main Content - 2 columns */}
        <div className="lg:col-span-2 space-y-6">
          {/* Dispute Reason */}
          <Card>
            <CardHeader>
              <CardTitle>Lý do tranh chấp</CardTitle>
            </CardHeader>
            <CardContent>
              <p className="whitespace-pre-wrap">{dispute.reason}</p>
            </CardContent>
          </Card>

          {/* Tabs for Timeline and Evidence */}
          <Tabs defaultValue="timeline">
            <TabsList>
              <TabsTrigger value="timeline" className="flex items-center gap-1">
                <Clock className="h-4 w-4" />
                Lịch sử (
                {dispute.timeline?.length || dispute._count?.timeline || 0})
              </TabsTrigger>
              <TabsTrigger value="evidence" className="flex items-center gap-1">
                <AlertTriangle className="h-4 w-4" />
                Bằng chứng (
                {dispute.evidence?.length || dispute._count?.evidence || 0})
              </TabsTrigger>
            </TabsList>
            <TabsContent value="timeline" className="mt-4">
              <Card>
                <CardContent className="pt-6">
                  <DisputeTimeline timeline={dispute.timeline || []} />
                </CardContent>
              </Card>
            </TabsContent>
            <TabsContent value="evidence" className="mt-4">
              <Card>
                <CardContent className="pt-6">
                  <EvidenceViewer evidence={dispute.evidence || []} />
                </CardContent>
              </Card>
            </TabsContent>
          </Tabs>

          {/* Resolution (if resolved) */}
          {dispute.resolution && (
            <Card className="bg-green-50 border-green-200">
              <CardHeader>
                <CardTitle className="text-green-700">
                  Kết quả giải quyết
                </CardTitle>
              </CardHeader>
              <CardContent className="space-y-3">
                <div>
                  <span className="text-sm text-green-800 font-medium">
                    Quyết định:
                  </span>
                  <p className="text-green-900">
                    {dispute.resolutionType
                      ? RESOLUTION_TYPE_LABELS[dispute.resolutionType]
                      : dispute.resolution}
                  </p>
                </div>
                {dispute.refundAmount && (
                  <div>
                    <span className="text-sm text-green-800 font-medium">
                      Số tiền hoàn:
                    </span>
                    <p className="text-lg font-semibold text-green-900">
                      {formatCurrency(dispute.refundAmount)}
                    </p>
                  </div>
                )}
                {dispute.adminNotes && (
                  <div>
                    <span className="text-sm text-green-800 font-medium">
                      Ghi chú admin:
                    </span>
                    <p className="text-green-800">{dispute.adminNotes}</p>
                  </div>
                )}
                {dispute.resolvedAt && (
                  <p className="text-xs text-green-600">
                    Giải quyết lúc{" "}
                    {new Date(dispute.resolvedAt).toLocaleString("vi-VN")}
                  </p>
                )}
              </CardContent>
            </Card>
          )}
        </div>

        {/* Sidebar - 1 column */}
        <div className="space-y-6">
          {/* Booking Info */}
          <Card>
            <CardHeader>
              <CardTitle>Thông tin Booking</CardTitle>
            </CardHeader>
            <CardContent className="space-y-3 text-sm">
              <div>
                <span className="text-zinc-500">ID:</span>
                <p className="font-mono">
                  #{String(dispute.bookingId).slice(0, 8)}
                </p>
              </div>
              <div>
                <span className="text-zinc-500">Dịch vụ:</span>
                <p className="font-medium">
                  {dispute.booking?.service?.name || "N/A"}
                </p>
              </div>
              <div>
                <span className="text-zinc-500">Giá trị:</span>
                <p className="font-semibold">
                  {formatCurrency(dispute.booking?.actualPrice)}
                </p>
              </div>
              <div>
                <span className="text-zinc-500">Trạng thái booking:</span>
                <p>{dispute.booking?.status || "N/A"}</p>
              </div>
            </CardContent>
          </Card>

          {/* Customer Info */}
          <Card>
            <CardHeader>
              <CardTitle>Khách hàng</CardTitle>
            </CardHeader>
            <CardContent className="space-y-2 text-sm">
              <p className="font-medium">
                {dispute.booking?.customer?.profile?.fullName || "N/A"}
              </p>
              <p className="font-mono text-zinc-600">
                {dispute.booking?.customer?.phone ||
                  dispute.booking?.customerPhone ||
                  "N/A"}
              </p>
            </CardContent>
          </Card>

          {/* Provider Info */}
          <Card>
            <CardHeader>
              <CardTitle>Nhà cung cấp</CardTitle>
            </CardHeader>
            <CardContent className="space-y-2 text-sm">
              <p className="font-medium">
                {dispute.booking?.providerUser?.profile?.fullName || "N/A"}
              </p>
              <p className="font-mono text-zinc-600">
                {dispute.booking?.providerUser?.phone ||
                  dispute.booking?.providerPhone ||
                  "N/A"}
              </p>
            </CardContent>
          </Card>

          {/* Timestamps */}
          <Card>
            <CardHeader>
              <CardTitle>Thời gian</CardTitle>
            </CardHeader>
            <CardContent className="space-y-2 text-sm text-zinc-600">
              <div className="flex justify-between">
                <span>Tạo lúc:</span>
                <span>
                  {new Date(dispute.createdAt).toLocaleString("vi-VN")}
                </span>
              </div>
              {dispute.escalatedAt && (
                <div className="flex justify-between">
                  <span>Leo thang:</span>
                  <span>
                    {new Date(dispute.escalatedAt).toLocaleString("vi-VN")}
                  </span>
                </div>
              )}
              {dispute.resolvedAt && (
                <div className="flex justify-between">
                  <span>Giải quyết:</span>
                  <span>
                    {new Date(dispute.resolvedAt).toLocaleString("vi-VN")}
                  </span>
                </div>
              )}
            </CardContent>
          </Card>
        </div>
      </div>

      {/* Resolve Modal */}
      {dispute && (
        <ResolveDisputeModal
          dispute={dispute}
          open={isResolveModalOpen}
          onOpenChange={setIsResolveModalOpen}
          onResolve={resolveMutation.mutateAsync}
          isLoading={resolveMutation.isPending}
        />
      )}
    </div>
  );
}

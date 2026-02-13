"use client";

import { useQuery } from "@tanstack/react-query";
import { useParams, useRouter } from "next/navigation";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { StatusBadge } from "@/components/ui/status-badge";
import { Button } from "@/components/ui/button";
import {
  ArrowLeft,
  Star,
  TrendingUp,
  CheckCircle,
  XCircle,
  Phone,
  Mail,
} from "lucide-react";
import { api } from "@/lib/api";
import { Provider } from "@/types/provider";
import { ApiResponse } from "@/types/system";
import { toast } from "sonner";

export default function ProviderDetailPage() {
  const params = useParams();
  const router = useRouter();
  const providerId = params.id as string;

  const {
    data: response,
    isLoading,
    isError,
    error,
    refetch,
  } = useQuery({
    queryKey: ["admin-provider-detail", providerId],
    queryFn: async () => {
      const res = await api.get<ApiResponse<Provider>>(
        `/admin/providers/${providerId}`
      );
      return res.data;
    },
    retry: false,
  });

  const provider = response?.data;

  const handleAction = async (action: "verified" | "rejected") => {
    try {
      await api.patch(`/admin/providers/${providerId}/verify`, {
        action,
        adminNotes: `Provider ${action} by admin`,
      });
      toast.success(
        `Provider ${
          action === "verified" ? "approved" : "rejected"
        } successfully`
      );
      refetch();
    } catch (error: any) {
      toast.error(
        error.response?.data?.message || `Failed to ${action} provider`
      );
    }
  };

  // Format currency
  const formatCurrency = (amount: number | string | undefined | null) => {
    if (amount === undefined || amount === null) return "₫0";
    const numAmount = typeof amount === "string" ? parseFloat(amount) : amount;
    return new Intl.NumberFormat("vi-VN", {
      style: "currency",
      currency: "VND",
    }).format(numAmount);
  };

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

  if (isError) {
    return (
      <div className="flex items-center justify-center h-96">
        <div className="text-center">
          <p className="text-lg text-red-600">Error loading provider data</p>
          <p className="text-sm text-zinc-500 mt-2">
            {(error as Error)?.message || "Please try again later"}
          </p>
          <Button onClick={() => router.push("/providers")} className="mt-4">
            Back to Providers
          </Button>
        </div>
      </div>
    );
  }

  if (!provider) {
    return (
      <div className="flex items-center justify-center h-96">
        <div className="text-center">
          <p className="text-lg text-zinc-600">Provider not found</p>
          <Button onClick={() => router.push("/providers")} className="mt-4">
            Back to Providers
          </Button>
        </div>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-4">
          <Button
            variant="ghost"
            size="icon"
            onClick={() => router.push("/providers")}
          >
            <ArrowLeft className="h-4 w-4" />
          </Button>
          <div>
            <h2 className="text-3xl font-bold tracking-tight">
              {provider.displayName || "Unknown Provider"}
            </h2>
            <p className="text-zinc-600">
              Provider #{provider.id ? String(provider.id).slice(0, 8) : "N/A"}
            </p>
          </div>
        </div>
        {provider.verificationStatus === "pending" && (
          <div className="flex gap-2">
            <Button variant="default" onClick={() => handleAction("verified")}>
              <CheckCircle className="h-4 w-4 mr-2" />
              Approve
            </Button>
            <Button
              variant="destructive"
              onClick={() => handleAction("rejected")}
            >
              <XCircle className="h-4 w-4 mr-2" />
              Reject
            </Button>
          </div>
        )}
      </div>

      <div className="grid gap-6 md:grid-cols-2 lg:grid-cols-4">
        <Card className="bg-gradient-to-br from-yellow-50 to-orange-50">
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Rating</CardTitle>
            <Star className="h-4 w-4 text-yellow-500" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">
              {typeof provider.rating === "object" && provider.rating?.average
                ? Number(provider.rating.average).toFixed(1)
                : typeof provider.rating === "number"
                ? provider.rating.toFixed(1)
                : "0.0"}
            </div>
            <p className="text-xs text-zinc-600">
              {provider.totalReviews || 0} reviews
            </p>
          </CardContent>
        </Card>

        <Card className="bg-gradient-to-br from-green-50 to-emerald-50">
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Response Time</CardTitle>
            <TrendingUp className="h-4 w-4 text-green-500" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">
              {provider.responseTime ? `${provider.responseTime}m` : "N/A"}
            </div>
            <p className="text-xs text-zinc-600">Average response</p>
          </CardContent>
        </Card>

        <Card className="bg-gradient-to-br from-blue-50 to-indigo-50">
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">
              Completion Rate
            </CardTitle>
            <TrendingUp className="h-4 w-4 text-blue-500" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">
              {provider.completionRate || "0%"}
            </div>
            <p className="text-xs text-zinc-600">Jobs completed</p>
          </CardContent>
        </Card>

        <Card className="bg-gradient-to-br from-purple-50 to-pink-50">
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Services</CardTitle>
            <TrendingUp className="h-4 w-4 text-purple-500" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">
              {provider.services?.length || 0}
            </div>
            <p className="text-xs text-zinc-600">Active services</p>
          </CardContent>
        </Card>
      </div>

      <div className="grid gap-6 md:grid-cols-2">
        {/* Business Information */}
        <Card>
          <CardHeader>
            <CardTitle>Business Information</CardTitle>
          </CardHeader>
          <CardContent className="space-y-4">
            {provider.avatarUrl && (
              <div className="flex justify-center">
                <img
                  src={provider.avatarUrl}
                  alt={provider.displayName || "Provider"}
                  className="h-24 w-24 rounded-full object-cover border-2 border-blue-500"
                />
              </div>
            )}
            <div className="space-y-2">
              <div className="flex justify-between">
                <span className="text-sm text-zinc-600">Business Name</span>
                <span className="text-sm font-medium">
                  {provider.displayName || "—"}
                </span>
              </div>
              {provider.bio && (
                <div>
                  <span className="text-sm text-zinc-600">Bio</span>
                  <p className="text-sm mt-1">{provider.bio}</p>
                </div>
              )}
              <div className="flex justify-between">
                <span className="text-sm text-zinc-600">
                  Verification Status
                </span>
                <StatusBadge
                  status={provider.verificationStatus || "unverified"}
                />
              </div>
              <div className="flex justify-between">
                <span className="text-sm text-zinc-600">Availability</span>
                <StatusBadge
                  status={provider.availabilityStatus || "offline"}
                />
              </div>
              <div className="flex justify-between">
                <span className="text-sm text-zinc-600">Joined</span>
                <span className="text-sm font-medium">
                  {provider.createdAt
                    ? new Date(provider.createdAt).toLocaleDateString("vi-VN")
                    : "—"}
                </span>
              </div>
            </div>
          </CardContent>
        </Card>

        {/* Contact Information */}
        <Card>
          <CardHeader>
            <CardTitle>Contact Information</CardTitle>
          </CardHeader>
          <CardContent className="space-y-4">
            <div className="space-y-2">
              <div className="flex items-center gap-2">
                <Phone className="h-4 w-4 text-zinc-600" />
                <span className="text-sm text-zinc-600">Phone</span>
              </div>
              <p className="font-mono text-sm font-medium ml-6">
                {provider.user?.phone || "—"}
              </p>
            </div>
            <div className="space-y-2">
              <div className="flex items-center gap-2">
                <Mail className="h-4 w-4 text-zinc-600" />
                <span className="text-sm text-zinc-600">Email</span>
              </div>
              <p className="text-sm font-medium ml-6">
                {provider.user?.email || "—"}
              </p>
            </div>
            <div className="space-y-2">
              <span className="text-sm text-zinc-600">Full Name</span>
              <p className="text-sm font-medium">
                {provider.user?.profile?.fullName || "—"}
              </p>
            </div>
          </CardContent>
        </Card>

        {/* Services Offered */}
        {provider.services && provider.services.length > 0 && (
          <Card className="md:col-span-2">
            <CardHeader>
              <CardTitle>Services Offered & Price List</CardTitle>
            </CardHeader>
            <CardContent>
              <div className="space-y-4">
                {provider.services.map((service: any, index: number) => (
                  <div
                    key={service.id || index}
                    className="p-4 rounded-lg bg-zinc-50 border"
                  >
                    <div className="flex justify-between items-start mb-2">
                      <div>
                        <p className="font-semibold text-lg">
                          {service.service?.name || "Unknown Service"}
                        </p>
                        <p className="text-sm text-zinc-600">
                          Base Price:{" "}
                          {formatCurrency(service.price || service.basePrice)}
                        </p>
                      </div>
                      <StatusBadge
                        status={service.isActive ? "active" : "inactive"}
                      />
                    </div>
                    {service.description && (
                      <p className="text-sm text-zinc-500 mb-3">
                        {service.description}
                      </p>
                    )}

                    {/* Service Items / Price List */}
                    {service.items && service.items.length > 0 && (
                      <div className="mt-3 border-t pt-3">
                        <p className="text-sm font-medium text-zinc-700 mb-2">
                          📋 Bảng giá chi tiết ({service.items.length} mục)
                        </p>
                        <div className="grid gap-2">
                          {service.items.map((item: any, itemIdx: number) => (
                            <div
                              key={item.id || itemIdx}
                              className="flex items-center gap-3 p-2 bg-white rounded-md border"
                            >
                              {item.imageUrl ? (
                                <img
                                  src={item.imageUrl}
                                  alt={item.name}
                                  className="w-10 h-10 rounded object-cover"
                                />
                              ) : (
                                <div className="w-10 h-10 rounded bg-zinc-100 flex items-center justify-center">
                                  🔧
                                </div>
                              )}
                              <div className="flex-1">
                                <p className="text-sm font-medium">
                                  {item.name}
                                </p>
                                {item.description && (
                                  <p className="text-xs text-zinc-500">
                                    {item.description}
                                  </p>
                                )}
                              </div>
                              <p className="text-sm font-bold text-green-600">
                                {formatCurrency(item.price)}
                              </p>
                            </div>
                          ))}
                        </div>
                      </div>
                    )}

                    {(!service.items || service.items.length === 0) && (
                      <p className="text-xs text-zinc-400 mt-2 italic">
                        Chưa có bảng giá chi tiết
                      </p>
                    )}
                  </div>
                ))}
              </div>
            </CardContent>
          </Card>
        )}
      </div>
    </div>
  );
}

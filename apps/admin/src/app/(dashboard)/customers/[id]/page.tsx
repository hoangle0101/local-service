"use client";

import { useQuery } from "@tanstack/react-query";
import { useParams, useRouter } from "next/navigation";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { StatusBadge } from "@/components/ui/status-badge";
import { Button } from "@/components/ui/button";
import { ArrowLeft, Calendar, User as UserIcon, Shield } from "lucide-react";
import { api } from "@/lib/api";
import { UserDetail } from "@/types/user";
import { ApiResponse } from "@/types/system";

export default function CustomerDetailPage() {
  const params = useParams();
  const router = useRouter();
  const userId = params.id as string;

  const {
    data: response,
    isLoading,
    isError,
    error,
  } = useQuery({
    queryKey: ["admin-user-detail", userId],
    queryFn: async () => {
      console.log("Fetching user detail for:", userId);
      const res = await api.get<ApiResponse<UserDetail>>(
        `/admin/users/${userId}`
      );
      console.log("API Response:", res.data);
      return res.data;
    },
    retry: false,
  });

  const user = response?.data;
  console.log("Parsed user:", user);

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
          <p className="text-lg text-red-600">Error loading customer data</p>
          <p className="text-sm text-zinc-500 mt-2">
            {(error as Error)?.message || "Please try again later"}
          </p>
          <Button onClick={() => router.push("/customers")} className="mt-4">
            Back to Customers
          </Button>
        </div>
      </div>
    );
  }

  if (!user) {
    return (
      <div className="flex items-center justify-center h-96">
        <div className="text-center">
          <p className="text-lg text-zinc-600">Customer not found</p>
          <Button onClick={() => router.push("/customers")} className="mt-4">
            Back to Customers
          </Button>
        </div>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      <div className="flex items-center gap-4">
        <Button
          variant="ghost"
          size="icon"
          onClick={() => router.push("/customers")}
        >
          <ArrowLeft className="h-4 w-4" />
        </Button>
        <div>
          <h2 className="text-3xl font-bold tracking-tight">
            Customer Details
          </h2>
          <p className="text-zinc-600">
            #{user.id ? String(user.id).slice(0, 8) : "N/A"}
          </p>
        </div>
      </div>

      <div className="grid gap-6 md:grid-cols-2">
        {/* Profile Information */}
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <UserIcon className="h-4 w-4" />
              Profile Information
            </CardTitle>
          </CardHeader>
          <CardContent className="space-y-4">
            {user.profile?.avatarUrl && (
              <div className="flex justify-center">
                <img
                  src={user.profile.avatarUrl}
                  alt="Avatar"
                  className="h-24 w-24 rounded-full object-cover border-2 border-blue-500"
                />
              </div>
            )}
            <div className="space-y-2">
              <div className="flex justify-between">
                <span className="text-sm text-zinc-600">Full Name</span>
                <span className="text-sm font-medium">
                  {user.profile?.fullName || "Not set"}
                </span>
              </div>
              <div className="flex justify-between">
                <span className="text-sm text-zinc-600">Phone</span>
                <span className="text-sm font-medium font-mono">
                  {user.phone || "—"}
                </span>
              </div>
              <div className="flex justify-between">
                <span className="text-sm text-zinc-600">Email</span>
                <span className="text-sm font-medium">{user.email || "—"}</span>
              </div>
              <div className="flex justify-between">
                <span className="text-sm text-zinc-600">Gender</span>
                <span className="text-sm font-medium capitalize">
                  {user.profile?.gender || "—"}
                </span>
              </div>
              <div className="flex justify-between">
                <span className="text-sm text-zinc-600">Birth Date</span>
                <span className="text-sm font-medium">
                  {user.profile?.dateOfBirth
                    ? new Date(user.profile.dateOfBirth).toLocaleDateString(
                        "vi-VN"
                      )
                    : "—"}
                </span>
              </div>
            </div>
          </CardContent>
        </Card>

        {/* Account Status */}
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <Shield className="h-4 w-4" />
              Account Status
            </CardTitle>
          </CardHeader>
          <CardContent className="space-y-4">
            <div className="space-y-2">
              <div className="flex justify-between items-center">
                <span className="text-sm text-zinc-600">Roles</span>
                <div className="flex gap-1 flex-wrap justify-end">
                  {(user.roles || []).map((role) => (
                    <span
                      key={role}
                      className="capitalize text-xs px-2 py-1 rounded bg-zinc-100 font-medium whitespace-nowrap"
                    >
                      {role.replace("_", " ")}
                    </span>
                  ))}
                  {(!user.roles || user.roles.length === 0) && (
                    <span className="text-xs text-zinc-400">No roles</span>
                  )}
                </div>
              </div>
              <div className="flex justify-between items-center">
                <span className="text-sm text-zinc-600">Status</span>
                <StatusBadge status={user.status || "active"} />
              </div>
              <div className="flex justify-between items-center">
                <span className="text-sm text-zinc-600">Verified</span>
                <span
                  className={`text-sm font-medium ${
                    user.isVerified ? "text-green-600" : "text-red-600"
                  }`}
                >
                  {user.isVerified ? "✓ Yes" : "✗ No"}
                </span>
              </div>
              <div className="flex justify-between">
                <span className="text-sm text-zinc-600">Joined</span>
                <span className="text-sm font-medium">
                  {user.createdAt
                    ? new Date(user.createdAt).toLocaleDateString("vi-VN")
                    : "—"}
                </span>
              </div>
            </div>
          </CardContent>
        </Card>

        {/* Wallet Information */}
        {user.wallet && (
          <Card>
            <CardHeader>
              <CardTitle>Wallet</CardTitle>
            </CardHeader>
            <CardContent>
              <div className="space-y-2">
                <div className="flex justify-between items-center">
                  <span className="text-sm text-zinc-600">Balance</span>
                  <span className="text-2xl font-bold text-green-600">
                    {formatCurrency(user.wallet.balance)}
                  </span>
                </div>
                <div className="flex justify-between">
                  <span className="text-sm text-zinc-600">Locked Balance</span>
                  <span className="text-sm font-medium">
                    {formatCurrency(user.wallet.lockedBalance)}
                  </span>
                </div>
                <div className="flex justify-between">
                  <span className="text-sm text-zinc-600">Total Deposits</span>
                  <span className="text-sm font-medium text-green-600">
                    {formatCurrency(user.wallet.totalDeposits)}
                  </span>
                </div>
                <div className="flex justify-between">
                  <span className="text-sm text-zinc-600">
                    Total Withdrawals
                  </span>
                  <span className="text-sm font-medium text-red-600">
                    {formatCurrency(user.wallet.totalWithdrawals)}
                  </span>
                </div>
              </div>
            </CardContent>
          </Card>
        )}

        {/* Location */}
        {user.profile?.address && (
          <Card>
            <CardHeader>
              <CardTitle>Location</CardTitle>
            </CardHeader>
            <CardContent>
              <p className="text-sm text-zinc-600">{user.profile.address}</p>
            </CardContent>
          </Card>
        )}
      </div>

      {/* Bookings History */}
      {user.bookingsAsCustomer && user.bookingsAsCustomer.length > 0 && (
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <Calendar className="h-4 w-4" />
              Booking History as Customer ({user.bookingsAsCustomer.length})
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="space-y-3">
              {user.bookingsAsCustomer.slice(0, 10).map((booking) => (
                <div
                  key={booking.id}
                  className="flex items-center justify-between p-4 rounded-lg bg-zinc-50 hover:bg-zinc-100 transition-colors cursor-pointer"
                  onClick={() => router.push(`/bookings/${booking.id}`)}
                >
                  <div className="space-y-1">
                    <p className="text-sm font-medium">
                      Booking #
                      {booking.id ? String(booking.id).slice(0, 8) : "N/A"}
                    </p>
                    <p className="text-sm text-zinc-600">
                      {booking.service?.name || "Unknown service"}
                    </p>
                    <p className="text-xs text-zinc-500">
                      {booking.createdAt
                        ? new Date(booking.createdAt).toLocaleString("vi-VN")
                        : "—"}
                    </p>
                  </div>
                  <div className="text-right space-y-1">
                    <p className="text-sm font-medium">
                      {formatCurrency(booking.totalAmount)}
                    </p>
                    <StatusBadge status={booking.status || "pending"} />
                  </div>
                </div>
              ))}
            </div>
          </CardContent>
        </Card>
      )}
    </div>
  );
}

'use client';

import { useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { Button } from '@/components/ui/button';
import { Download, TrendingUp, Users, Briefcase } from 'lucide-react';
import { api } from '@/lib/api';
import { RevenueReport, ServicesReport, UsersReport, ApiResponse } from '@/types/system';
import { RevenueChart } from '@/components/ui/revenue-chart';
import { UserGrowthChart } from '@/components/ui/user-growth-chart';
import { exportToCSV } from '@/lib/export';

export default function ReportsPage() {
  const [dateRange] = useState({ start: '', end: '' });

  // Revenue Report
  const { data: revenueData } = useQuery({
    queryKey: ['revenue-report', dateRange],
    queryFn: async () => {
      const res = await api.get<ApiResponse<RevenueReport>>('/admin/reports/revenue', {
        params: {
          startDate: dateRange.start || undefined,
          endDate: dateRange.end || undefined,
          groupBy: 'daily',
        },
      });
      return res.data.data;
    },
  });

  // Services Report
  const { data: servicesData } = useQuery({
    queryKey: ['services-report', dateRange],
    queryFn: async () => {
      const res = await api.get<ApiResponse<ServicesReport>>('/admin/reports/services', {
        params: {
          startDate: dateRange.start || undefined,
          endDate: dateRange.end || undefined,
          sortBy: 'bookings',
          limit: 20,
        },
      });
      return res.data.data;
    },
  });

  // Users Report
  const { data: usersData } = useQuery({
    queryKey: ['users-report', dateRange],
    queryFn: async () => {
      const res = await api.get<ApiResponse<UsersReport>>('/admin/reports/users', {
        params: {
          startDate: dateRange.start || undefined,
          endDate: dateRange.end || undefined,
          groupBy: 'daily',
        },
      });
      return res.data.data;
    },
  });

  // Format currency
  const formatCurrency = (amount: number) => {
    return new Intl.NumberFormat('vi-VN', {
      style: 'currency',
      currency: 'VND',
    }).format(amount);
  };

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-3xl font-bold tracking-tight">Reports & Analytics</h2>
          <p className="text-zinc-600">View detailed platform analytics</p>
        </div>
        <Button 
          variant="outline"
          onClick={() => {
            if (revenueData) exportToCSV(revenueData.timeSeriesData, 'revenue_report');
            if (usersData) exportToCSV(usersData.timeSeriesData, 'users_report');
          }}
        >
          <Download className="h-4 w-4 mr-2" />
          Export All
        </Button>
      </div>

      <Tabs defaultValue="revenue" className="space-y-4">
        <TabsList>
          <TabsTrigger value="revenue">
            <TrendingUp className="h-4 w-4 mr-2" />
            Revenue
          </TabsTrigger>
          <TabsTrigger value="services">
            <Briefcase className="h-4 w-4 mr-2" />
            Services
          </TabsTrigger>
          <TabsTrigger value="users">
            <Users className="h-4 w-4 mr-2" />
            Customers
          </TabsTrigger>
        </TabsList>

        <TabsContent value="revenue" className="space-y-4">
          <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-4">
            <Card>
              <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                <CardTitle className="text-sm font-medium">Total Revenue</CardTitle>
                <TrendingUp className="h-4 w-4 text-muted-foreground" />
              </CardHeader>
              <CardContent>
                <div className="text-2xl font-bold">
                  {formatCurrency(revenueData?.summary.totalRevenue || 0)}
                </div>
              </CardContent>
            </Card>
            <Card>
              <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                <CardTitle className="text-sm font-medium">Commission</CardTitle>
                <TrendingUp className="h-4 w-4 text-muted-foreground" />
              </CardHeader>
              <CardContent>
                <div className="text-2xl font-bold">
                  {formatCurrency(revenueData?.summary.totalCommission || 0)}
                </div>
              </CardContent>
            </Card>
            <Card>
              <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                <CardTitle className="text-sm font-medium">Provider Earnings</CardTitle>
                <TrendingUp className="h-4 w-4 text-muted-foreground" />
              </CardHeader>
              <CardContent>
                <div className="text-2xl font-bold">
                  {formatCurrency(revenueData?.summary.totalProviderEarnings || 0)}
                </div>
              </CardContent>
            </Card>
            <Card>
              <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                <CardTitle className="text-sm font-medium">Total Bookings</CardTitle>
                <Briefcase className="h-4 w-4 text-muted-foreground" />
              </CardHeader>
              <CardContent>
                <div className="text-2xl font-bold">
                  {revenueData?.summary.bookingCount || 0}
                </div>
              </CardContent>
            </Card>
          </div>

          <Card>
            <CardHeader>
              <CardTitle>Revenue Trend</CardTitle>
            </CardHeader>
            <CardContent>
              {revenueData?.timeSeriesData && revenueData.timeSeriesData.length > 0 ? (
                <RevenueChart data={revenueData.timeSeriesData} />
              ) : (
                <div className="text-center text-zinc-500 py-8">No data available</div>
              )}
            </CardContent>
          </Card>
        </TabsContent>

        <TabsContent value="services" className="space-y-4">
          <Card>
            <CardHeader>
              <CardTitle>Top Services</CardTitle>
            </CardHeader>
            <CardContent>
              {servicesData?.topServices && servicesData.topServices.length > 0 ? (
                <div className="space-y-3">
                  {servicesData.topServices.map((service, index) => (
                    <div key={service.id} className="flex items-center justify-between p-3 bg-zinc-50 rounded">
                      <div className="flex items-center gap-3">
                        <span className="font-bold text-lg text-zinc-400">#{index + 1}</span>
                        <div>
                          <div className="font-medium">{service.name}</div>
                          <div className="text-sm text-zinc-500">{service.category}</div>
                        </div>
                      </div>
                      <div className="text-right">
                        <div className="font-semibold">{formatCurrency(service.totalRevenue)}</div>
                        <div className="text-xs text-zinc-500">
                          {service.totalBookings} bookings · ★ {service.avgRating.toFixed(1)}
                        </div>
                      </div>
                    </div>
                  ))}
                </div>
              ) : (
                <div className="text-center text-zinc-500 py-8">No services data available</div>
              )}
            </CardContent>
          </Card>
        </TabsContent>

        <TabsContent value="users" className="space-y-4">
          <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-4">
            <Card>
              <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                <CardTitle className="text-sm font-medium">Total Customers</CardTitle>
                <Users className="h-4 w-4 text-muted-foreground" />
              </CardHeader>
              <CardContent>
                <div className="text-2xl font-bold">{usersData?.summary.totalUsers || 0}</div>
              </CardContent>
            </Card>
            <Card>
              <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                <CardTitle className="text-sm font-medium">New Customers</CardTitle>
                <Users className="h-4 w-4 text-muted-foreground" />
              </CardHeader>
              <CardContent>
                <div className="text-2xl font-bold">{usersData?.summary.newUsers || 0}</div>
              </CardContent>
            </Card>
            <Card>
              <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                <CardTitle className="text-sm font-medium">Active Customers</CardTitle>
                <Users className="h-4 w-4 text-muted-foreground" />
              </CardHeader>
              <CardContent>
                <div className="text-2xl font-bold">{usersData?.summary.activeUsers || 0}</div>
              </CardContent>
            </Card>
            <Card>
              <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                <CardTitle className="text-sm font-medium">Verified Customers</CardTitle>
                <Users className="h-4 w-4 text-muted-foreground" />
              </CardHeader>
              <CardContent>
                <div className="text-2xl font-bold">{usersData?.summary.verifiedUsers || 0}</div>
              </CardContent>
            </Card>
          </div>

          <Card>
            <CardHeader>
              <CardTitle>Customer Growth</CardTitle>
            </CardHeader>
            <CardContent>
              {usersData?.timeSeriesData && usersData.timeSeriesData.length > 0 ? (
                <UserGrowthChart data={usersData.timeSeriesData} />
              ) : (
                <div className="text-center text-zinc-500 py-8">No customer data available</div>
              )}
            </CardContent>
          </Card>
        </TabsContent>
      </Tabs>
    </div>
  );
}

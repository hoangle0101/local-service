'use client';

import { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { DataTable, Column } from '@/components/ui/data-table';
import { StatusBadge } from '@/components/ui/status-badge';
import { Button } from '@/components/ui/button';
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogTrigger, DialogFooter } from '@/components/ui/dialog';
import { Input } from '@/components/ui/input';
import { Textarea } from '@/components/ui/textarea';
import { Label } from '@/components/ui/label';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { Plus, Megaphone } from 'lucide-react';
import { api } from '@/lib/api';
import { Announcement, CreateAnnouncementInput } from '@/types/system';
import { ApiResponse, PaginatedResponse } from '@/types/system';
import { toast } from 'sonner';

export default function AnnouncementsPage() {
  const [page, setPage] = useState(1);
  const [open, setOpen] = useState(false);
  const [formData, setFormData] = useState<CreateAnnouncementInput>({
    title: '',
    body: '',
    type: 'general',
    targetRole: 'all',
    sendNotification: true,
  });

  const queryClient = useQueryClient();

  const { data: response, isLoading } = useQuery({
    queryKey: ['admin-announcements', page],
    queryFn: async () => {
      const res = await api.get<ApiResponse<PaginatedResponse<Announcement>>>('/admin/announcements', {
        params: {
          page,
          limit: 20,
        },
      });
      return res.data.data;
    },
  });

  const createMutation = useMutation({
    mutationFn: async (data: CreateAnnouncementInput) => {
      const res = await api.post('/admin/announcements', data);
      return res.data;
    },
    onSuccess: () => {
      toast.success('Announcement created successfully');
      queryClient.invalidateQueries({ queryKey: ['admin-announcements'] });
      setOpen(false);
      setFormData({
        title: '',
        body: '',
        type: 'general',
        targetRole: 'all',
        sendNotification: true,
      });
    },
    onError: (error: any) => {
      toast.error(error.response?.data?.message || 'Failed to create announcement');
    },
  });

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    createMutation.mutate(formData);
  };

  const columns: Column<Announcement>[] = [
    {
      key: 'id',
      label: 'ID',
      render: (announcement) => (
        <span className="font-mono text-sm">#{announcement.id.slice(0, 8)}</span>
      ),
    },
    {
      key: 'title',
      label: 'Title',
      sortable: true,
      render: (announcement) => (
        <div>
          <div className="font-medium">{announcement.title}</div>
          <div className="text-xs text-zinc-500 line-clamp-1">{announcement.body}</div>
        </div>
      ),
    },
    {
      key: 'type',
      label: 'Type',
      render: (announcement) => (
        <span className="capitalize text-sm px-2 py-1 rounded bg-zinc-100">
          {announcement.type}
        </span>
      ),
    },
    {
      key: 'targetRole',
      label: 'Target',
      render: (announcement) => (
        <span className="capitalize text-sm px-2 py-1 rounded bg-blue-50 text-blue-700">
          {announcement.targetRole}
        </span>
      ),
    },
    {
      key: 'createdBy',
      label: 'Created By',
      render: (announcement) => (
        <div className="text-sm">
          <div>{announcement.createdBy?.profile?.fullName || 'N/A'}</div>
          <div className="text-xs text-zinc-500">{announcement.createdBy?.email}</div>
        </div>
      ),
    },
    {
      key: 'status',
      label: 'Status',
      render: (announcement) => <StatusBadge status={announcement.status} />,
    },
    {
      key: 'createdAt',
      label: 'Created',
      sortable: true,
      render: (announcement) => (
        <div className="text-sm">
          {new Date(announcement.createdAt).toLocaleDateString('vi-VN')}
        </div>
      ),
    },
  ];

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-3xl font-bold tracking-tight flex items-center gap-2">
            <Megaphone className="h-8 w-8 text-blue-500" />
            Announcements
          </h2>
          <p className="text-zinc-600">Manage system announcements and notifications</p>
        </div>

        <Dialog open={open} onOpenChange={setOpen}>
          <DialogTrigger asChild>
            <Button>
              <Plus className="h-4 w-4 mr-2" />
              Create Announcement
            </Button>
          </DialogTrigger>
          <DialogContent className="max-w-2xl">
            <DialogHeader>
              <DialogTitle>Create New Announcement</DialogTitle>
            </DialogHeader>
            <form onSubmit={handleSubmit} className="space-y-4">
              <div>
                <Label htmlFor="title">Title</Label>
                <Input
                  id="title"
                  value={formData.title}
                  onChange={(e) => setFormData({ ...formData, title: e.target.value })}
                  placeholder="Enter announcement title"
                  required
                />
              </div>

              <div>
                <Label htmlFor="body">Message</Label>
                <Textarea
                  id="body"
                  value={formData.body}
                  onChange={(e) => setFormData({ ...formData, body: e.target.value })}
                  placeholder="Enter announcement message"
                  rows={4}
                  required
                />
              </div>

              <div className="grid grid-cols-2 gap-4">
                <div>
                  <Label htmlFor="type">Type</Label>
                  <Select
                    value={formData.type}
                    onValueChange={(value: any) => setFormData({ ...formData, type: value })}
                  >
                    <SelectTrigger>
                      <SelectValue />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="general">General</SelectItem>
                      <SelectItem value="maintenance">Maintenance</SelectItem>
                      <SelectItem value="promotion">Promotion</SelectItem>
                      <SelectItem value="alert">Alert</SelectItem>
                    </SelectContent>
                  </Select>
                </div>

                <div>
                  <Label htmlFor="targetRole">Target Audience</Label>
                  <Select
                    value={formData.targetRole}
                    onValueChange={(value: any) => setFormData({ ...formData, targetRole: value })}
                  >
                    <SelectTrigger>
                      <SelectValue />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="all">All Users</SelectItem>
                      <SelectItem value="customers">Customers Only</SelectItem>
                      <SelectItem value="providers">Providers Only</SelectItem>
                      <SelectItem value="admins">Admins Only</SelectItem>
                    </SelectContent>
                  </Select>
                </div>
              </div>

              <div className="flex items-center space-x-2">
                <input
                  type="checkbox"
                  id="sendNotification"
                  checked={formData.sendNotification}
                  onChange={(e) => setFormData({ ...formData, sendNotification: e.target.checked })}
                  className="rounded"
                />
                <Label htmlFor="sendNotification" className="cursor-pointer">
                  Send push notification to users
                </Label>
              </div>

              <DialogFooter>
                <Button type="button" variant="outline" onClick={() => setOpen(false)}>
                  Cancel
                </Button>
                <Button type="submit" disabled={createMutation.isPending}>
                  {createMutation.isPending ? 'Creating...' : 'Create Announcement'}
                </Button>
              </DialogFooter>
            </form>
          </DialogContent>
        </Dialog>
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
        emptyMessage="No announcements found"
      />
    </div>
  );
}

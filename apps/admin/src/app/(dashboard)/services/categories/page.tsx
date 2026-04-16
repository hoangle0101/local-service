'use client';

import { useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { ConfirmDialog } from '@/components/ui/confirm-dialog';
import { Dialog, DialogContent, DialogHeader, DialogTitle } from '@/components/ui/dialog';
import { StatusBadge } from '@/components/ui/status-badge';
import { Plus, Edit, Trash2, ArrowLeft, Folder } from 'lucide-react';
import { useRouter } from 'next/navigation';
import { api } from '@/lib/api';
import { ServiceCategory } from '@/types/provider';
import { ApiResponse } from '@/types/system';
import { toast } from 'sonner';

export default function CategoriesPage() {
  const router = useRouter();
  const [selectedCategory, setSelectedCategory] = useState<ServiceCategory | null>(null);
  const [formDialog, setFormDialog] = useState(false);
  const [deleteDialog, setDeleteDialog] = useState(false);
  const [formData, setFormData] = useState({
    name: '',
    code: '',
    slug: '',
    description: '',
    parentId: null as number | null,
    isActive: true,
  });

  const { data: response, isLoading, refetch } = useQuery({
    queryKey: ['categories'],
    queryFn: async () => {
      const res = await api.get<ApiResponse<ServiceCategory[]>>('/services/categories');
      return res.data;
    },
  });

  const categories = response?.data || [];

  const handleOpenForm = (category?: ServiceCategory) => {
    if (category) {
      setSelectedCategory(category);
      setFormData({
        name: category.name,
        code: category.code,
        slug: category.slug,
        description: category.description || '',
        parentId: category.parentId,
        isActive: category.isActive,
      });
    } else {
      setSelectedCategory(null);
      setFormData({
        name: '',
        code: '',
        slug: '',
        description: '',
        parentId: null,
        isActive: true,
      });
    }
    setFormDialog(true);
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    try {
      if (selectedCategory) {
        await api.put(`/services/categories/${selectedCategory.id}`, formData);
        toast.success('Category updated successfully');
      } else {
        await api.post('/services/categories', formData);
        toast.success('Category created successfully');
      }
      setFormDialog(false);
      refetch();
    } catch (error: any) {
      toast.error(error.response?.data?.message || `Failed to ${selectedCategory ? 'update' : 'create'} category`);
    }
  };

  const handleDelete = async (categoryId: number) => {
    try {
      await api.delete(`/services/categories/${categoryId}`);
      toast.success('Category deleted successfully');
      refetch();
    } catch (error: any) {
      toast.error(error.response?.data?.message || 'Failed to delete category');
    }
  };

  const renderCategoryTree = (categories: ServiceCategory[], level = 0) => {
    return categories.map((category) => (
      <div key={category.id} style={{ marginLeft: `${level * 20}px` }} className="mb-2">
        <div className="flex items-center gap-2 p-3 rounded-lg bg-white border border-zinc-200 hover:border-blue-500 transition-colors">
          <Folder className="h-4 w-4 text-blue-500" />
          <span className="flex-1 font-medium">{category.name}</span>
          <span className="text-sm text-zinc-500">({category.slug})</span>
          <StatusBadge status={category.isActive ? 'active' : 'inactive'} />
          <div className="flex gap-1">
            <Button
              variant="ghost"
              size="sm"
              onClick={() => handleOpenForm(category)}
            >
              <Edit className="h-3 w-3" />
            </Button>
            <Button
              variant="ghost"
              size="sm"
              onClick={() => {
                setSelectedCategory(category);
                setDeleteDialog(true);
              }}
            >
              <Trash2 className="h-3 w-3 text-red-500" />
            </Button>
          </div>
        </div>
        {category.children && category.children.length > 0 && (
          <div className="mt-2">
            {renderCategoryTree(category.children, level + 1)}
          </div>
        )}
      </div>
    ));
  };

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-4">
          <Button
            variant="ghost"
            size="icon"
            onClick={() => router.push('/services')}
          >
            <ArrowLeft className="h-4 w-4" />
          </Button>
          <div>
            <h2 className="text-3xl font-bold tracking-tight">Categories Management</h2>
            <p className="text-zinc-600">Organize services by categories</p>
          </div>
        </div>
        <Button onClick={() => handleOpenForm()}>
          <Plus className="h-4 w-4 mr-2" />
          Add Category
        </Button>
      </div>

      <Card>
        <CardHeader>
          <CardTitle>Category Tree</CardTitle>
        </CardHeader>
        <CardContent>
          {isLoading ? (
            <div className="space-y-2">
              {[1, 2, 3].map((i) => (
                <div key={i} className="h-12 bg-zinc-100 animate-pulse rounded" />
              ))}
            </div>
          ) : categories && categories.length > 0 ? (
            <div>{renderCategoryTree(categories)}</div>
          ) : (
            <p className="text-center text-zinc-600 py-8">No categories found</p>
          )}
        </CardContent>
      </Card>

      {/* Form Dialog */}
      <Dialog open={formDialog} onOpenChange={setFormDialog}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>
              {selectedCategory ? 'Edit Category' : 'Create Category'}
            </DialogTitle>
          </DialogHeader>
          <form onSubmit={handleSubmit} className="space-y-4">
            <div>
              <Label htmlFor="name">Category Name *</Label>
              <Input
                id="name"
                value={formData.name}
                onChange={(e) => {
                  const name = e.target.value;
                  setFormData({
                    ...formData,
                    name,
                    slug: name.toLowerCase().replace(/\s+/g, '-'),
                    code: name.toLowerCase().replace(/\s+/g, '_').replace(/[^a-z0-9_]/g, ''),
                  });
                }}
                required
              />
            </div>
            <div className="grid grid-cols-2 gap-4">
              <div>
                <Label htmlFor="code">Code *</Label>
                <Input
                  id="code"
                  value={formData.code}
                  onChange={(e) => setFormData({ ...formData, code: e.target.value })}
                  required
                />
              </div>
              <div>
                <Label htmlFor="slug">Slug *</Label>
                <Input
                  id="slug"
                  value={formData.slug}
                  onChange={(e) => setFormData({ ...formData, slug: e.target.value })}
                  required
                />
              </div>
            </div>
            <div>
              <Label htmlFor="description">Description</Label>
              <Input
                id="description"
                value={formData.description}
                onChange={(e) => setFormData({ ...formData, description: e.target.value })}
              />
            </div>
            <div className="flex items-center gap-2">
              <input
                type="checkbox"
                id="isActive"
                checked={formData.isActive}
                onChange={(e) => setFormData({ ...formData, isActive: e.target.checked })}
              />
              <Label htmlFor="isActive">Active</Label>
            </div>
            <div className="flex justify-end gap-2">
              <Button type="button" variant="outline" onClick={() => setFormDialog(false)}>
                Cancel
              </Button>
              <Button type="submit">
                {selectedCategory ? 'Update' : 'Create'}
              </Button>
            </div>
          </form>
        </DialogContent>
      </Dialog>

      {/* Delete Confirmation */}
      <ConfirmDialog
        open={deleteDialog}
        onOpenChange={setDeleteDialog}
        title="Delete Category"
        description={`Are you sure you want to delete "${selectedCategory?.name}"? This will also affect all subcategories and services.`}
        confirmLabel="Delete"
        variant="destructive"
        onConfirm={async () => {
          if (selectedCategory) {
            await handleDelete(selectedCategory.id);
          }
        }}
      />
    </div>
  );
}

"use client";

import { useState, useEffect } from "react";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { useRouter, useParams } from "next/navigation";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { StatusBadge } from "@/components/ui/status-badge";
import { ImageUpload } from "@/components/ui/image-upload";
import { ConfirmDialog } from "@/components/ui/confirm-dialog";
import { ArrowLeft, Edit, Trash2, Save, X } from "lucide-react";
import { api } from "@/lib/api";
import { Service, ServiceCategory } from "@/types/provider";
import { ApiResponse } from "@/types/system";
import { toast } from "sonner";

export default function ServiceDetailPage() {
  const router = useRouter();
  const params = useParams();
  const queryClient = useQueryClient();
  const serviceId = params.id as string;

  const [isEditing, setIsEditing] = useState(false);
  const [deleteDialog, setDeleteDialog] = useState(false);
  const [formData, setFormData] = useState({
    name: "",
    description: "",
    categoryId: "",
    basePrice: "",
    durationMinutes: "",
    imageUrl: "",
    isActive: true,
  });

  // Fetch service details
  const { data: serviceResponse, isLoading } = useQuery({
    queryKey: ["service", serviceId],
    queryFn: async () => {
      const res = await api.get<ApiResponse<Service>>(`/services/${serviceId}`);
      return res.data;
    },
    enabled: !!serviceId,
  });

  const service = serviceResponse?.data;

  // Fetch categories for dropdown
  const { data: categories } = useQuery<ServiceCategory[]>({
    queryKey: ["categories"],
    queryFn: async () => {
      const response = await api.get("/services/categories");
      return response.data.data || response.data;
    },
  });

  // Populate form when service loads
  useEffect(() => {
    if (service) {
      setFormData({
        name: service.name || "",
        description: service.description || "",
        categoryId: service.categoryId?.toString() || "",
        basePrice: service.basePrice?.toString() || "",
        durationMinutes: service.durationMinutes?.toString() || "",
        imageUrl: service.imageUrl || "",
        isActive: service.isActive ?? true,
      });
    }
  }, [service]);

  // Update mutation
  const updateMutation = useMutation({
    mutationFn: async (data: typeof formData) => {
      return api.put(`/services/${serviceId}`, {
        ...data,
        categoryId: parseInt(data.categoryId),
        basePrice: data.basePrice,
        durationMinutes: parseInt(data.durationMinutes),
      });
    },
    onSuccess: () => {
      toast.success("Service updated successfully");
      queryClient.invalidateQueries({ queryKey: ["service", serviceId] });
      queryClient.invalidateQueries({ queryKey: ["admin-services"] });
      setIsEditing(false);
    },
    onError: (error: any) => {
      toast.error(error.response?.data?.message || "Failed to update service");
    },
  });

  // Delete mutation
  const deleteMutation = useMutation({
    mutationFn: async () => {
      return api.delete(`/services/${serviceId}`);
    },
    onSuccess: () => {
      toast.success("Service deleted successfully");
      router.push("/services");
    },
    onError: (error: any) => {
      toast.error(error.response?.data?.message || "Failed to delete service");
    },
  });

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    updateMutation.mutate(formData);
  };

  const formatCurrency = (amount: number | string) => {
    const numAmount = typeof amount === "string" ? parseFloat(amount) : amount;
    return new Intl.NumberFormat("vi-VN", {
      style: "currency",
      currency: "VND",
    }).format(numAmount);
  };

  const flattenCategories = (cats: ServiceCategory[]): ServiceCategory[] => {
    return cats.reduce((acc: ServiceCategory[], category) => {
      acc.push(category);
      if (category.children && category.children.length > 0) {
        acc.push(...flattenCategories(category.children));
      }
      return acc;
    }, []);
  };

  if (isLoading) {
    return (
      <div className="space-y-6 max-w-3xl">
        <div className="h-8 bg-zinc-200 animate-pulse rounded w-1/3"></div>
        <Card>
          <CardContent className="p-6 space-y-4">
            {[1, 2, 3, 4].map((i) => (
              <div
                key={i}
                className="h-10 bg-zinc-100 animate-pulse rounded"
              ></div>
            ))}
          </CardContent>
        </Card>
      </div>
    );
  }

  if (!service) {
    return (
      <div className="text-center py-12">
        <p className="text-zinc-600">Service not found</p>
        <Button
          variant="outline"
          onClick={() => router.push("/services")}
          className="mt-4"
        >
          Back to Services
        </Button>
      </div>
    );
  }

  return (
    <div className="space-y-6 max-w-3xl">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-4">
          <Button
            variant="ghost"
            size="icon"
            onClick={() => router.push("/services")}
          >
            <ArrowLeft className="h-4 w-4" />
          </Button>
          <div>
            <h2 className="text-3xl font-bold tracking-tight">
              {service.name}
            </h2>
            <p className="text-zinc-600">Service #{serviceId}</p>
          </div>
        </div>
        <div className="flex gap-2">
          {!isEditing ? (
            <>
              <Button variant="outline" onClick={() => setIsEditing(true)}>
                <Edit className="h-4 w-4 mr-2" />
                Edit
              </Button>
              <Button
                variant="destructive"
                onClick={() => setDeleteDialog(true)}
              >
                <Trash2 className="h-4 w-4 mr-2" />
                Delete
              </Button>
            </>
          ) : (
            <>
              <Button variant="outline" onClick={() => setIsEditing(false)}>
                <X className="h-4 w-4 mr-2" />
                Cancel
              </Button>
              <Button
                onClick={handleSubmit}
                disabled={updateMutation.isPending}
              >
                <Save className="h-4 w-4 mr-2" />
                {updateMutation.isPending ? "Saving..." : "Save Changes"}
              </Button>
            </>
          )}
        </div>
      </div>

      {/* Service Details / Edit Form */}
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center justify-between">
            <span>Service Information</span>
            <StatusBadge status={service.isActive ? "active" : "inactive"} />
          </CardTitle>
        </CardHeader>
        <CardContent>
          {isEditing ? (
            <form onSubmit={handleSubmit} className="space-y-4">
              <div>
                <Label htmlFor="name">Service Name *</Label>
                <Input
                  id="name"
                  value={formData.name}
                  onChange={(e) =>
                    setFormData({ ...formData, name: e.target.value })
                  }
                  required
                />
              </div>

              <div>
                <Label htmlFor="description">Description</Label>
                <textarea
                  id="description"
                  value={formData.description}
                  onChange={(e) =>
                    setFormData({ ...formData, description: e.target.value })
                  }
                  className="w-full min-h-[100px] px-3 py-2 text-sm rounded-md border border-zinc-200 focus:outline-none focus:ring-2 focus:ring-blue-500"
                />
              </div>

              <div>
                <Label htmlFor="categoryId">Category *</Label>
                <select
                  id="categoryId"
                  value={formData.categoryId}
                  onChange={(e) =>
                    setFormData({ ...formData, categoryId: e.target.value })
                  }
                  className="w-full h-10 px-3 py-2 text-sm rounded-md border border-zinc-200 focus:outline-none focus:ring-2 focus:ring-blue-500"
                  required
                >
                  <option value="">Select a category</option>
                  {categories &&
                    flattenCategories(categories).map((category) => (
                      <option key={category.id} value={category.id}>
                        {category.name}
                      </option>
                    ))}
                </select>
              </div>

              <div className="grid grid-cols-2 gap-4">
                <div>
                  <Label htmlFor="basePrice">Base Price (VND) *</Label>
                  <Input
                    id="basePrice"
                    type="number"
                    step="1000"
                    value={formData.basePrice}
                    onChange={(e) =>
                      setFormData({ ...formData, basePrice: e.target.value })
                    }
                    required
                  />
                </div>
                <div>
                  <Label htmlFor="durationMinutes">Duration (minutes) *</Label>
                  <Input
                    id="durationMinutes"
                    type="number"
                    value={formData.durationMinutes}
                    onChange={(e) =>
                      setFormData({
                        ...formData,
                        durationMinutes: e.target.value,
                      })
                    }
                    required
                  />
                </div>
              </div>

              <div>
                <Label>Service Image</Label>
                <ImageUpload
                  value={formData.imageUrl}
                  onChange={(url) =>
                    setFormData({ ...formData, imageUrl: url })
                  }
                />
              </div>

              <div className="flex items-center gap-2">
                <input
                  type="checkbox"
                  id="isActive"
                  checked={formData.isActive}
                  onChange={(e) =>
                    setFormData({ ...formData, isActive: e.target.checked })
                  }
                />
                <Label htmlFor="isActive">Active (visible to users)</Label>
              </div>
            </form>
          ) : (
            <div className="space-y-4">
              {service.imageUrl && (
                <div className="mb-4">
                  <img
                    src={service.imageUrl}
                    alt={service.name}
                    className="h-40 w-auto rounded-lg object-cover"
                  />
                </div>
              )}

              <div className="grid grid-cols-2 gap-4">
                <div>
                  <p className="text-sm text-zinc-500">Category</p>
                  <p className="font-medium">{service.category?.name || "—"}</p>
                </div>
                <div>
                  <p className="text-sm text-zinc-500">Status</p>
                  <StatusBadge
                    status={service.isActive ? "active" : "inactive"}
                  />
                </div>
                <div>
                  <p className="text-sm text-zinc-500">Base Price</p>
                  <p className="font-medium text-lg">
                    {formatCurrency(service.basePrice)}
                  </p>
                </div>
                <div>
                  <p className="text-sm text-zinc-500">Duration</p>
                  <p className="font-medium">
                    {service.durationMinutes} minutes
                  </p>
                </div>
              </div>

              {service.description && (
                <div className="pt-4 border-t">
                  <p className="text-sm text-zinc-500 mb-2">Description</p>
                  <p className="text-zinc-700">{service.description}</p>
                </div>
              )}

              <div className="pt-4 border-t grid grid-cols-2 gap-4 text-sm">
                <div>
                  <p className="text-zinc-500">Created</p>
                  <p>
                    {new Date(service.createdAt).toLocaleDateString("vi-VN")}
                  </p>
                </div>
                <div>
                  <p className="text-zinc-500">Last Updated</p>
                  <p>
                    {new Date(service.updatedAt).toLocaleDateString("vi-VN")}
                  </p>
                </div>
              </div>
            </div>
          )}
        </CardContent>
      </Card>

      {/* Delete Confirmation */}
      <ConfirmDialog
        open={deleteDialog}
        onOpenChange={setDeleteDialog}
        title="Delete Service"
        description={`Are you sure you want to delete "${service.name}"? This action cannot be undone.`}
        confirmLabel="Delete"
        variant="destructive"
        onConfirm={async () => {
          await deleteMutation.mutateAsync();
        }}
      />
    </div>
  );
}

"use client";

import { useState } from "react";
import { useQuery } from "@tanstack/react-query";
import { useRouter } from "next/navigation";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { ImageUpload } from "@/components/ui/image-upload";
import { ArrowLeft } from "lucide-react";
import { api } from "@/lib/api";
import { ServiceCategory } from "@/types/provider";
import { toast } from "sonner";

export default function NewServicePage() {
  const router = useRouter();
  const [formData, setFormData] = useState({
    name: "",
    description: "",
    categoryId: "",
    basePrice: "",
    durationMinutes: "",
    imageUrl: "",
    isActive: true,
  });

  const { data: categories } = useQuery<ServiceCategory[]>({
    queryKey: ["categories"],
    queryFn: async () => {
      const response = await api.get("/services/categories");
      return response.data.data || response.data;
    },
  });

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    try {
      await api.post("/services", {
        name: formData.name,
        description: formData.description || undefined,
        categoryId: parseInt(formData.categoryId),
        basePrice: parseInt(formData.basePrice),
        durationMinutes: formData.durationMinutes
          ? parseInt(formData.durationMinutes)
          : undefined,
        imageUrl: formData.imageUrl || undefined,
        isActive: formData.isActive,
      });
      toast.success("Tạo dịch vụ thành công");
      router.push("/services");
    } catch (error: any) {
      console.error("Create service error:", error.response?.data);
      toast.error(error.response?.data?.message || "Không thể tạo dịch vụ");
    }
  };

  const flattenCategories = (
    categories: ServiceCategory[]
  ): ServiceCategory[] => {
    return categories.reduce((acc: ServiceCategory[], category) => {
      acc.push(category);
      if (category.children && category.children.length > 0) {
        acc.push(...flattenCategories(category.children));
      }
      return acc;
    }, []);
  };

  return (
    <div className="space-y-6 max-w-2xl">
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
            Create New Service
          </h2>
          <p className="text-zinc-600">Add a new service to the platform</p>
        </div>
      </div>

      <Card>
        <CardHeader>
          <CardTitle>Service Information</CardTitle>
        </CardHeader>
        <CardContent>
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
                <Label htmlFor="basePrice">Giá cơ bản (VND) *</Label>
                <Input
                  id="basePrice"
                  type="number"
                  step="1000"
                  min="0"
                  placeholder="Ví dụ: 200000"
                  value={formData.basePrice}
                  onChange={(e) =>
                    setFormData({ ...formData, basePrice: e.target.value })
                  }
                  required
                />
              </div>

              <div>
                <Label htmlFor="durationMinutes">
                  Thời gian (phút) - Không bắt buộc
                </Label>
                <Input
                  id="durationMinutes"
                  type="number"
                  placeholder="Để trống nếu linh hoạt"
                  value={formData.durationMinutes}
                  onChange={(e) =>
                    setFormData({
                      ...formData,
                      durationMinutes: e.target.value,
                    })
                  }
                />
              </div>
            </div>

            <div>
              <Label>Service Image</Label>
              <ImageUpload
                value={formData.imageUrl}
                onChange={(url) => setFormData({ ...formData, imageUrl: url })}
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

            <div className="flex justify-end gap-2 pt-4">
              <Button
                type="button"
                variant="outline"
                onClick={() => router.push("/services")}
              >
                Cancel
              </Button>
              <Button type="submit">Create Service</Button>
            </div>
          </form>
        </CardContent>
      </Card>
    </div>
  );
}

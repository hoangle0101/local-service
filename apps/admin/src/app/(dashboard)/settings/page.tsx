'use client';

import { useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Settings as SettingsIcon, Save } from 'lucide-react';
import { api } from '@/lib/api';
import { toast } from 'sonner';

const DEFAULT_SETTINGS = [
  {
    key: 'platform_fee_percentage',
    label: 'Platform Fee (%)',
    description: 'Percentage fee charged on each booking',
    type: 'number',
  },
  {
    key: 'commission_rate',
    label: 'Commission Rate (%)',
    description: 'Commission rate for service providers',
    type: 'number',
  },
  {
    key: 'min_booking_amount',
    label: 'Minimum Booking Amount ($)',
    description: 'Minimum amount required for a booking',
    type: 'number',
  },
  {
    key: 'max_cancellation_time',
    label: 'Max Cancellation Time (hours)',
    description: 'Maximum time before booking to allow cancellation',
    type: 'number',
  },
  {
    key: 'support_email',
    label: 'Support Email',
    description: 'Customer support email address',
    type: 'text',
  },
  {
    key: 'support_phone',
    label: 'Support Phone',
    description: 'Customer support phone number',
    type: 'text',
  },
];

export default function SettingsPage() {
  const [editedSettings, setEditedSettings] = useState<Record<string, string>>({});

  const { data: settings, isLoading, refetch } = useQuery<any[]>({
    queryKey: ['settings'],
    queryFn: async () => {
      const response = await api.get('/system/admin/settings');
      return response.data.data || response.data;
    },
  });

  const getSettingValue = (key: string) => {
    if (editedSettings[key] !== undefined) {
      return editedSettings[key];
    }
    const setting = settings?.find((s) => s.key === key);
    return setting?.value || '';
  };

  const handleSave = async (key: string) => {
    const value = editedSettings[key];
    if (value === undefined) return;

    try {
      await api.put('/system/admin/settings', {
        key,
        value,
        description: DEFAULT_SETTINGS.find((s) => s.key === key)?.description,
      });
      toast.success('Setting updated successfully');
      refetch();
      // Clear edited state for this key
      const newEdited = { ...editedSettings };
      delete newEdited[key];
      setEditedSettings(newEdited);
    } catch (error) {
      toast.error('Failed to update setting');
    }
  };

  return (
    <div className="space-y-6 max-w-4xl">
      <div>
        <h2 className="text-3xl font-bold tracking-tight flex items-center gap-2">
          <SettingsIcon className="h-8 w-8" />
          System Settings
        </h2>
        <p className="text-zinc-600">Configure platform settings and parameters</p>
      </div>

      {isLoading ? (
        <div className="space-y-4">
          {[1, 2, 3].map((i) => (
            <div key={i} className="h-32 bg-zinc-100 animate-pulse rounded-lg" />
          ))}
        </div>
      ) : (
        <div className="space-y-4">
          {DEFAULT_SETTINGS.map((setting) => (
            <Card key={setting.key}>
              <CardHeader>
                <CardTitle className="text-lg">{setting.label}</CardTitle>
                <p className="text-sm text-zinc-600">{setting.description}</p>
              </CardHeader>
              <CardContent>
                <div className="flex gap-4 items-end">
                  <div className="flex-1">
                    <Label htmlFor={setting.key}>Value</Label>
                    <Input
                      id={setting.key}
                      type={setting.type}
                      value={getSettingValue(setting.key)}
                      onChange={(e) =>
                        setEditedSettings({
                          ...editedSettings,
                          [setting.key]: e.target.value,
                        })
                      }
                      placeholder={`Enter ${setting.label.toLowerCase()}`}
                    />
                  </div>
                  <Button
                    onClick={() => handleSave(setting.key)}
                    disabled={editedSettings[setting.key] === undefined}
                  >
                    <Save className="h-4 w-4 mr-2" />
                    Save
                  </Button>
                </div>
              </CardContent>
            </Card>
          ))}
        </div>
      )}

      <Card className="bg-blue-50 border-blue-200">
        <CardHeader>
          <CardTitle className="text-blue-900">Important Notice</CardTitle>
        </CardHeader>
        <CardContent>
          <p className="text-sm text-blue-800">
            Changing these settings will affect the entire platform. Please ensure you
            understand the implications before making changes. All changes are logged for
            audit purposes.
          </p>
        </CardContent>
      </Card>
    </div>
  );
}

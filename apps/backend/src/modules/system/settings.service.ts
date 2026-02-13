import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';

@Injectable()
export class SettingsService {
  constructor(private prisma: PrismaService) {}

  /**
   * Get public settings (excludes internal/secret settings)
   * Public settings: Any key NOT starting with "internal_" or "secret_"
   */
  async getPublicSettings() {
    const settings = await this.prisma.setting.findMany();

    // Filter out internal and secret settings
    const publicSettings = settings.filter(
      setting => !setting.key.startsWith('internal_') && !setting.key.startsWith('secret_')
    );

    // Convert to key-value object
    const settingsObject = publicSettings.reduce((acc, setting) => {
      acc[setting.key] = setting.value;
      return acc;
    }, {} as Record<string, any>);

    return settingsObject;
  }

  /**
   * Get single setting by key (Admin only - not exposed to public)
   */
  async getSetting(key: string) {
    const setting = await this.prisma.setting.findUnique({
      where: { key }
    });

    if (!setting) {
      throw new NotFoundException(`Setting '${key}' not found`);
    }

    return setting;
  }

  /**
   * Update or create setting (Admin only)
   */
  async upsertSetting(key: string, value: any, description?: string) {
    return await this.prisma.setting.upsert({
      where: { key },
      update: { value, description },
      create: { key, value, description }
    });
  }

  /**
   * Delete setting (Admin only)
   */
  async deleteSetting(key: string) {
    await this.prisma.setting.delete({
      where: { key }
    });

    return { message: 'Setting deleted successfully' };
  }
}

import { Module } from '@nestjs/common';
import { SystemController } from './system.controller';
import { UploadService } from './upload.service';
import { SettingsService } from './settings.service';
import { PrismaModule } from '../../prisma/prisma.module';

@Module({
  imports: [PrismaModule],
  controllers: [SystemController],
  providers: [UploadService, SettingsService],
  exports: [UploadService, SettingsService],
})
export class SystemModule {}

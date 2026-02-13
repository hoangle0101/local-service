import { Module } from '@nestjs/common';
import {
  ProviderServiceItemsController,
  PublicServiceItemsController,
} from './provider-service-items.controller';
import { ProviderServiceItemsService } from './provider-service-items.service';
import { PrismaModule } from '../../prisma/prisma.module';

@Module({
  imports: [PrismaModule],
  controllers: [ProviderServiceItemsController, PublicServiceItemsController],
  providers: [ProviderServiceItemsService],
  exports: [ProviderServiceItemsService],
})
export class ProviderServiceItemsModule {}

import { Module } from '@nestjs/common';
import { ServiceQuotesController } from './service-quotes.controller';
import { ServiceQuotesService } from './service-quotes.service';
import { PrismaModule } from '../../prisma/prisma.module';
import { ConversationsModule } from '../conversations/conversations.module';

@Module({
  imports: [PrismaModule, ConversationsModule],
  controllers: [ServiceQuotesController],
  providers: [ServiceQuotesService],
  exports: [ServiceQuotesService],
})
export class ServiceQuotesModule {}

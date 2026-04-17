import { Module, Global, Logger } from '@nestjs/common';
import { PrismaService } from './prisma.service';

@Global()
@Module({
  providers: [
    {
      provide: 'PRISMA_SERVICE',
      useClass: PrismaService,
    },
    PrismaService,
  ],
  exports: [PrismaService, 'PRISMA_SERVICE'],
})
export class PrismaModule {
  private readonly logger = new Logger('PrismaModule');

  constructor(private prisma: PrismaService) {
    this.logger.log('Prisma module initialized');
  }
}


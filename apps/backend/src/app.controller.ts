import { Controller, Get } from '@nestjs/common';
import { AppService } from './app.service';
import { PrismaService } from './prisma/prisma.service';

@Controller()
export class AppController {
  constructor(
    private readonly appService: AppService,
    private readonly prisma: PrismaService,
  ) {}

  @Get()
  getHello(): string {
    return this.appService.getHello();
  }

  /**
   * Health check endpoint
   * Returns: { status: 'ok', database: boolean, timestamp: ISO string }
   */
  @Get('health')
  async health() {
    const databaseHealthy = await this.prisma.healthCheck();
    return {
      status: databaseHealthy ? 'ok' : 'degraded',
      database: databaseHealthy,
      timestamp: new Date().toISOString(),
    };
  }

  /**
   * Readiness check endpoint (for Kubernetes/Docker)
   * Returns 200 if app is ready to receive requests
   */
  @Get('ready')
  async ready() {
    const databaseHealthy = this.prisma.isHealthy();
    if (!databaseHealthy) {
      return { ready: false, message: 'Database not connected' };
    }
    return { ready: true };
  }
}

import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { RealtimeGateway } from '../gateway/realtime.gateway';

@Injectable()
export class NotificationsService {
  constructor(
    private prisma: PrismaService,
    private realtimeGateway: RealtimeGateway,
  ) {}

  async create(
    userId: bigint,
    type: string,
    title: string,
    body: string,
    payload?: any,
  ) {
    // 1. Create in DB
    const notification = await this.prisma.notification.create({
      data: {
        userId,
        type,
        title,
        body,
        payload: payload || {},
      },
    });

    // 2. Real-time emit
    this.realtimeGateway.emitNotification(userId.toString(), {
      id: notification.id.toString(),
      type: notification.type,
      title: notification.title || '',
      body: notification.body || '',
      payload: notification.payload,
      createdAt: notification.createdAt.toISOString(),
    });

    console.log(`[Notification] Created and Emitted for user ${userId}: ${title}`);

    return notification;
  }

  async findAll(userId: bigint) {
    return this.prisma.notification.findMany({
      where: { userId },
      orderBy: { createdAt: 'desc' },
      take: 50,
    });
  }

  async markAsRead(userId: bigint, notificationId: bigint) {
    return this.prisma.notification.updateMany({
      where: {
        id: notificationId,
        userId,
      },
      data: {
        isRead: true,
      },
    });
  }

  async markAllAsRead(userId: bigint) {
    return this.prisma.notification.updateMany({
      where: { userId, isRead: false },
      data: { isRead: true },
    });
  }
}

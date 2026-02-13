import {
  WebSocketGateway,
  WebSocketServer,
  SubscribeMessage,
  OnGatewayConnection,
  OnGatewayDisconnect,
  ConnectedSocket,
  MessageBody,
} from '@nestjs/websockets';
import { Server, Socket } from 'socket.io';
import { Logger, Injectable } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';

// ========================
// Socket Event Types
// ========================

export interface BookingStatusPayload {
  bookingId: string;
  status: string;
  paymentStatus?: string; // Payment status for escrow tracking
  previousStatus?: string;
  providerId?: string;
  providerName?: string;
  serviceName?: string;
  scheduledAt?: string;
  addressText?: string;
  message?: string;
  customerName?: string;
  estimatedPrice?: string;
  latitude?: number;
  longitude?: number;
  actorId?: string;
  payload?: any;
}

export interface LocationUpdatePayload {
  bookingId: string;
  providerId: string;
  latitude: number;
  longitude: number;
  heading?: number;
  speed?: number;
  timestamp: string;
}

export interface NewJobPayload {
  bookingId: string;
  serviceId: number;
  serviceName: string;
  categoryId: number;
  categoryName: string;
  customerName?: string;
  addressText: string;
  latitude: number;
  longitude: number;
  scheduledAt: string;
  estimatedPrice?: number;
  distance?: number;
}

export interface NotificationPayload {
  id: string;
  type: string;
  title: string;
  body: string;
  payload?: any;
  createdAt: string;
}

export interface TypingPayload {
  conversationId: string;
  userId: string;
  isTyping: boolean;
}

export interface MessageReadPayload {
  conversationId: string;
  messageId: string;
  readerId: string;
  readAt: string;
}

// ========================
// Socket Events Constants
// ========================
export const SocketEvents = {
  // Booking Events
  BOOKING_CREATED: 'booking_created',
  BOOKING_ACCEPTED: 'booking_accepted',
  BOOKING_STARTED: 'booking_started',
  BOOKING_AWAITING_CONFIRMATION: 'booking_awaiting_confirmation',
  BOOKING_COMPLETED: 'booking_completed',
  BOOKING_CANCELLED: 'booking_cancelled',
  BOOKING_DISPUTED: 'booking_disputed',
  BOOKING_STATUS_CHANGED: 'booking_status_changed',

  // Location Events
  PROVIDER_LOCATION_UPDATE: 'provider_location_update',
  PROVIDER_ARRIVING: 'provider_arriving',
  PROVIDER_ARRIVED: 'provider_arrived',
  SUBSCRIBE_LOCATION: 'subscribe_location',
  UNSUBSCRIBE_LOCATION: 'unsubscribe_location',
  SEND_LOCATION: 'send_location',

  // Job Market Events
  NEW_JOB_AVAILABLE: 'new_job_available',
  JOB_TAKEN: 'job_taken',
  SUBSCRIBE_JOB_MARKET: 'subscribe_job_market',
  UNSUBSCRIBE_JOB_MARKET: 'unsubscribe_job_market',

  // Provider Status
  PROVIDER_ONLINE: 'provider_online',
  PROVIDER_OFFLINE: 'provider_offline',
  TOGGLE_AVAILABILITY: 'toggle_availability',

  // Notifications
  NEW_NOTIFICATION: 'new_notification',

  // Chat Events
  JOIN_CONVERSATION: 'join_conversation',
  LEAVE_CONVERSATION: 'leave_conversation',
  SEND_MESSAGE: 'send_message',
  NEW_MESSAGE: 'new_message',
  USER_TYPING: 'user_typing',
  MESSAGE_READ: 'message_read',
  WALLET_UPDATED: 'wallet_updated',
} as const;

// ========================
// RealtimeGateway
// ========================

@Injectable()
@WebSocketGateway({
  cors: {
    origin: '*',
  },
})
export class RealtimeGateway
  implements OnGatewayConnection, OnGatewayDisconnect
{
  @WebSocketServer()
  server: Server;

  private logger = new Logger('RealtimeGateway');

  // user socket mappings
  private userSockets: Map<string, Set<string>> = new Map();
  // socket to user mapping for quick lookup
  private socketToUser: Map<string, string> = new Map();
  // provider category subscriptions: categoryId -> Set<socketId>
  private jobMarketSubscriptions: Map<string, Set<string>> = new Map();
  // location tracking: bookingId -> Set<socketId>
  private locationSubscriptions: Map<string, Set<string>> = new Map();

  constructor(private jwtService: JwtService) {}

  // ========================
  // Connection Lifecycle
  // ========================

  async handleConnection(client: Socket) {
    try {
      const token = client.handshake.auth.token || client.handshake.query.token;
      if (!token) {
        this.logger.warn(`Client ${client.id} disconnected: no token`);
        client.disconnect();
        return;
      }

      const payload = this.jwtService.verify(token as string);
      const userId = payload.sub?.toString();

      if (!userId) {
        this.logger.error('Invalid token payload: missing sub');
        client.disconnect();
        return;
      }

      // Store mappings
      client.data.userId = userId;
      this.socketToUser.set(client.id, userId);

      if (!this.userSockets.has(userId)) {
        this.userSockets.set(userId, new Set());
      }
      this.userSockets.get(userId)!.add(client.id);

      // Auto-join user's personal room for notifications
      client.join(`user_${userId}`);

      this.logger.log(
        `Client connected: ${client.id}, userId: ${userId}, total: ${this.userSockets.get(userId)?.size}`,
      );

      // Emit connection success
      client.emit('connected', {
        userId,
        socketId: client.id,
        timestamp: new Date().toISOString(),
      });
    } catch (error) {
      this.logger.error(`Connection error: ${error.message}`);
      client.disconnect();
    }
  }

  handleDisconnect(client: Socket) {
    const userId = this.socketToUser.get(client.id);

    if (userId) {
      const sockets = this.userSockets.get(userId);
      if (sockets) {
        sockets.delete(client.id);
        if (sockets.size === 0) {
          this.userSockets.delete(userId);
        }
      }
      this.socketToUser.delete(client.id);
    }

    // Clean up subscriptions
    for (const [, subscribers] of this.jobMarketSubscriptions) {
      subscribers.delete(client.id);
    }
    for (const [, subscribers] of this.locationSubscriptions) {
      subscribers.delete(client.id);
    }

    this.logger.log(`Client disconnected: ${client.id}`);
  }

  // ========================
  // Location Tracking
  // ========================

  @SubscribeMessage(SocketEvents.SUBSCRIBE_LOCATION)
  handleSubscribeLocation(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: { bookingId: string },
  ) {
    const room = `location_${data.bookingId}`;
    client.join(room);

    if (!this.locationSubscriptions.has(data.bookingId)) {
      this.locationSubscriptions.set(data.bookingId, new Set());
    }
    this.locationSubscriptions.get(data.bookingId)!.add(client.id);

    this.logger.log(`Client ${client.id} subscribed to location ${room}`);
    return { success: true, room };
  }

  @SubscribeMessage(SocketEvents.UNSUBSCRIBE_LOCATION)
  handleUnsubscribeLocation(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: { bookingId: string },
  ) {
    const room = `location_${data.bookingId}`;
    client.leave(room);

    this.locationSubscriptions.get(data.bookingId)?.delete(client.id);

    this.logger.log(`Client ${client.id} unsubscribed from location ${room}`);
    return { success: true };
  }

  @SubscribeMessage(SocketEvents.SEND_LOCATION)
  handleSendLocation(
    @ConnectedSocket() client: Socket,
    @MessageBody()
    data: {
      bookingId: string;
      latitude: number;
      longitude: number;
      heading?: number;
      speed?: number;
    },
  ) {
    const userId = client.data.userId;
    if (!userId) {
      return { error: 'Unauthorized' };
    }

    const payload: LocationUpdatePayload = {
      bookingId: data.bookingId,
      providerId: userId,
      latitude: data.latitude,
      longitude: data.longitude,
      heading: data.heading,
      speed: data.speed,
      timestamp: new Date().toISOString(),
    };

    // Emit to location room
    const room = `location_${data.bookingId}`;
    this.server.to(room).emit(SocketEvents.PROVIDER_LOCATION_UPDATE, payload);

    this.logger.debug(
      `Location update for booking ${data.bookingId}: ${data.latitude}, ${data.longitude}`,
    );

    return { success: true };
  }

  // ========================
  // Job Market
  // ========================

  @SubscribeMessage(SocketEvents.SUBSCRIBE_JOB_MARKET)
  handleSubscribeJobMarket(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: { categoryIds?: number[] },
  ) {
    const categoryIds = data.categoryIds || ['all'];

    for (const catId of categoryIds) {
      const room = `job_market_${catId}`;
      client.join(room);

      const key = catId.toString();
      if (!this.jobMarketSubscriptions.has(key)) {
        this.jobMarketSubscriptions.set(key, new Set());
      }
      this.jobMarketSubscriptions.get(key)!.add(client.id);
    }

    this.logger.log(
      `Client ${client.id} subscribed to job market: ${categoryIds.join(', ')}`,
    );
    return { success: true, categories: categoryIds };
  }

  @SubscribeMessage(SocketEvents.UNSUBSCRIBE_JOB_MARKET)
  handleUnsubscribeJobMarket(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: { categoryIds?: number[] },
  ) {
    const categoryIds = data.categoryIds || ['all'];

    for (const catId of categoryIds) {
      const room = `job_market_${catId}`;
      client.leave(room);
      this.jobMarketSubscriptions.get(catId.toString())?.delete(client.id);
    }

    this.logger.log(
      `Client ${client.id} unsubscribed from job market: ${categoryIds.join(', ')}`,
    );
    return { success: true };
  }

  // ========================
  // Chat - Typing & Read Receipts
  // ========================

  @SubscribeMessage(SocketEvents.JOIN_CONVERSATION)
  handleJoinConversation(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: { conversationId: string },
  ) {
    const room = `conversation_${data.conversationId}`;
    client.join(room);
    this.logger.log(`Client ${client.id} joined ${room}`);
    return { success: true, room };
  }

  @SubscribeMessage(SocketEvents.LEAVE_CONVERSATION)
  handleLeaveConversation(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: { conversationId: string },
  ) {
    const room = `conversation_${data.conversationId}`;
    client.leave(room);
    this.logger.log(`Client ${client.id} left ${room}`);
    return { success: true };
  }

  @SubscribeMessage(SocketEvents.USER_TYPING)
  handleUserTyping(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: { conversationId: string; isTyping: boolean },
  ) {
    const userId = client.data.userId;
    if (!userId) return { error: 'Unauthorized' };

    const room = `conversation_${data.conversationId}`;
    client.to(room).emit(SocketEvents.USER_TYPING, {
      conversationId: data.conversationId,
      userId,
      isTyping: data.isTyping,
    } as TypingPayload);

    return { success: true };
  }

  @SubscribeMessage(SocketEvents.MESSAGE_READ)
  handleMessageRead(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: { conversationId: string; messageId: string },
  ) {
    const userId = client.data.userId;
    if (!userId) return { error: 'Unauthorized' };

    const room = `conversation_${data.conversationId}`;
    client.to(room).emit(SocketEvents.MESSAGE_READ, {
      conversationId: data.conversationId,
      messageId: data.messageId,
      readerId: userId,
      readAt: new Date().toISOString(),
    } as MessageReadPayload);

    return { success: true };
  }

  // ========================
  // Provider Availability
  // ========================

  @SubscribeMessage(SocketEvents.TOGGLE_AVAILABILITY)
  handleToggleAvailability(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: { isAvailable: boolean },
  ) {
    const userId = client.data.userId;
    if (!userId) return { error: 'Unauthorized' };

    const event = data.isAvailable
      ? SocketEvents.PROVIDER_ONLINE
      : SocketEvents.PROVIDER_OFFLINE;

    // Broadcast to all clients
    this.server.emit(event, {
      providerId: userId,
      isAvailable: data.isAvailable,
      timestamp: new Date().toISOString(),
    });

    this.logger.log(
      `Provider ${userId} is now ${data.isAvailable ? 'online' : 'offline'}`,
    );
    return { success: true };
  }

  // ========================
  // Public Emit Methods (for use from Services)
  // ========================

  /**
   * Notify a specific user by userId
   */
  notifyUser(userId: string, event: string, data: any) {
    this.server.to(`user_${userId}`).emit(event, data);
    this.logger.debug(`Notified user ${userId} with event ${event}`);
  }

  /**
   * Notify multiple users
   */
  notifyUsers(userIds: string[], event: string, data: any) {
    for (const userId of userIds) {
      this.notifyUser(userId, event, data);
    }
  }

  /**
   * Emit booking status change to customer and/or provider
   */
  emitBookingStatusChange(
    customerId: string,
    providerId: string | null,
    payload: BookingStatusPayload,
  ) {
    // Ensure providerId is in payload for client-side filtering if not already there
    if (providerId && !payload.providerId) {
      payload.providerId = providerId;
    }

    // Always notify customer
    this.notifyUser(customerId, SocketEvents.BOOKING_STATUS_CHANGED, payload);

    // Notify provider if assigned
    if (providerId) {
      this.notifyUser(providerId, SocketEvents.BOOKING_STATUS_CHANGED, payload);
    }

    this.logger.log(
      `Booking ${payload.bookingId} status changed to ${payload.status}`,
    );
  }

  /**
   * Emit new job to job market
   */
  emitNewJob(categoryId: number, payload: NewJobPayload) {
    const room = `job_market_${categoryId}`;
    this.server.to(room).emit(SocketEvents.NEW_JOB_AVAILABLE, payload);

    // Also emit to 'all' room
    this.server
      .to('job_market_all')
      .emit(SocketEvents.NEW_JOB_AVAILABLE, payload);

    this.logger.log(
      `New job ${payload.bookingId} emitted to category ${categoryId}`,
    );
  }

  /**
   * Emit job taken event
   */
  emitJobTaken(
    categoryId: number,
    bookingId: string,
    takenByProviderId: string,
  ) {
    const room = `job_market_${categoryId}`;
    this.server.to(room).emit(SocketEvents.JOB_TAKEN, {
      bookingId,
      takenByProviderId,
      timestamp: new Date().toISOString(),
    });

    this.server.to('job_market_all').emit(SocketEvents.JOB_TAKEN, {
      bookingId,
      takenByProviderId,
      timestamp: new Date().toISOString(),
    });
  }

  /**
   * Emit location update (called from REST API if provider sends via HTTP)
   */
  emitLocationUpdate(bookingId: string, payload: LocationUpdatePayload) {
    const room = `location_${bookingId}`;
    this.server.to(room).emit(SocketEvents.PROVIDER_LOCATION_UPDATE, payload);
  }

  /**
   * Emit provider arriving/arrived events
   */
  emitProviderArriving(
    customerId: string,
    bookingId: string,
    distanceMeters: number,
  ) {
    this.notifyUser(customerId, SocketEvents.PROVIDER_ARRIVING, {
      bookingId,
      distanceMeters,
      timestamp: new Date().toISOString(),
    });
  }

  emitProviderArrived(customerId: string, bookingId: string) {
    this.notifyUser(customerId, SocketEvents.PROVIDER_ARRIVED, {
      bookingId,
      timestamp: new Date().toISOString(),
    });
  }

  /**
   * Emit new notification
   */
  emitNotification(userId: string, payload: NotificationPayload) {
    this.notifyUser(userId, SocketEvents.NEW_NOTIFICATION, payload);
  }

  /**
   * Emit chat message (for use from ConversationsService)
   */
  emitNewMessage(conversationId: string, message: any) {
    const room = `conversation_${conversationId}`;
    this.server.to(room).emit(SocketEvents.NEW_MESSAGE, message);
  }

  // ========================
  // Utility Methods
  // ========================

  /**
   * Emit wallet balance update
   */
  emitWalletUpdate(userId: string, balance: number) {
    this.notifyUser(userId, SocketEvents.WALLET_UPDATED, {
      userId,
      balance,
      timestamp: new Date().toISOString(),
    });
  }

  /**
   * Check if user is online
   */
  isUserOnline(userId: string): boolean {
    return (
      this.userSockets.has(userId) && this.userSockets.get(userId)!.size > 0
    );
  }

  /**
   * Get online user count
   */
  getOnlineUserCount(): number {
    return this.userSockets.size;
  }

  /**
   * Get all online user IDs
   */
  getOnlineUserIds(): string[] {
    return Array.from(this.userSockets.keys());
  }
}

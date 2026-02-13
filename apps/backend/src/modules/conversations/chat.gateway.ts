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
import { Logger } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { ConversationsService } from './conversations.service';

@WebSocketGateway({
  cors: {
    origin: '*',
  },
  namespace: '/chat',
})
export class ChatGateway implements OnGatewayConnection, OnGatewayDisconnect {
  @WebSocketServer()
  server: Server;

  private logger = new Logger('ChatGateway');
  private userSockets: Map<string, string[]> = new Map(); // userId -> socketIds[]

  constructor(
    private jwtService: JwtService,
    private conversationsService: ConversationsService,
  ) {}

  async handleConnection(client: Socket) {
    try {
      const token = client.handshake.auth.token || client.handshake.query.token;
      if (!token) {
        client.disconnect();
        return;
      }

      const payload = this.jwtService.verify(token as string);
      // AuthService signs with 'sub', 'phone'
      const userId = payload.sub;

      if (!userId) {
        this.logger.error('Invalid token payload: missing sub');
        client.disconnect();
        return;
      }

      // Store socket mapping
      client.data.userId = userId;
      const sockets = this.userSockets.get(userId) || [];
      sockets.push(client.id);
      this.userSockets.set(userId, sockets);

      this.logger.log(`Client connected: ${client.id}, userId: ${userId}`);
    } catch (error) {
      this.logger.error(`Connection error: ${error.message}`);
      client.disconnect();
    }
  }

  handleDisconnect(client: Socket) {
    const userId = client.data.userId;
    if (userId) {
      const sockets = this.userSockets.get(userId) || [];
      const updated = sockets.filter((id) => id !== client.id);
      if (updated.length > 0) {
        this.userSockets.set(userId, updated);
      } else {
        this.userSockets.delete(userId);
      }
    }
    this.logger.log(`Client disconnected: ${client.id}`);
  }

  @SubscribeMessage('join_conversation')
  handleJoinConversation(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: { conversationId: string },
  ) {
    const room = `conversation_${data.conversationId}`;
    client.join(room);
    this.logger.log(`Client ${client.id} joined room ${room}`);
    return { success: true, room };
  }

  @SubscribeMessage('leave_conversation')
  handleLeaveConversation(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: { conversationId: string },
  ) {
    const room = `conversation_${data.conversationId}`;
    client.leave(room);
    this.logger.log(`Client ${client.id} left room ${room}`);
    return { success: true };
  }

  @SubscribeMessage('send_message')
  async handleSendMessage(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: { conversationId: string; content: string },
  ) {
    const userId = client.data.userId;
    if (!userId) {
      return { error: 'Unauthorized' };
    }

    try {
      const message = await this.conversationsService.sendMessage(
        BigInt(userId),
        BigInt(data.conversationId),
        { content: data.content },
      );

      if (!message) {
        throw new Error('Message not created');
      }

      // Emit to all clients in the conversation room
      const room = `conversation_${data.conversationId}`;
      this.server.to(room).emit('new_message', {
        id: message.id.toString(),
        conversationId: data.conversationId,
        senderId: message.senderId.toString(),
        body: message.body,
        createdAt: message.createdAt,
        sender: (message as any).sender, // Include sender relation
      });

      return { success: true, messageId: message.id.toString() };
    } catch (error) {
      this.logger.error(`Send message error: ${error.message}`);
      return { error: error.message };
    }
  }

  // Method to emit message from service (when sending via REST API)
  emitNewMessage(conversationId: string, message: any) {
    const room = `conversation_${conversationId}`;
    this.server.to(room).emit('new_message', message);
  }

  // Notify specific user
  notifyUser(userId: string, event: string, data: any) {
    const sockets = this.userSockets.get(userId) || [];
    for (const socketId of sockets) {
      this.server.to(socketId).emit(event, data);
    }
  }
}

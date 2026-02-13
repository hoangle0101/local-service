import {
    ForbiddenException,
    Injectable,
    NotFoundException,
} from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { CreateConversationDto, SendMessageDto } from './dto/conversation.dto';

@Injectable()
export class ConversationsService {
    constructor(private prisma: PrismaService) { }

    /**
     * List conversations for user
     */
    async findAll(userId: bigint) {
        return this.prisma.conversation.findMany({
            where: {
                OR: [{ customerId: userId }, { providerId: userId }],
            },
            include: {
                customer: {
                    select: {
                        id: true,
                        phone: true,
                        profile: { select: { fullName: true, avatarUrl: true } },
                    },
                },
                provider: {
                    select: {
                        id: true,
                        phone: true,
                        profile: { select: { fullName: true, avatarUrl: true } },
                    },
                },
                booking: {
                    select: {
                        id: true,
                        code: true,
                        status: true,
                        service: { select: { name: true } },
                    },
                },
            },
            orderBy: { lastMessageAt: 'desc' },
        });
    }

    /**
     * Create conversation
     */
    async createConversation(userId: bigint, dto: CreateConversationDto) {
        const booking = await this.prisma.booking.findUnique({
            where: { id: BigInt(dto.bookingId) },
        });

        if (!booking) {
            throw new NotFoundException('Booking not found');
        }

        // Verify user is part of booking
        if (booking.customerId !== userId && booking.providerId !== userId) {
            throw new ForbiddenException('Access denied');
        }

        if (!booking.providerId) {
            throw new ForbiddenException('Booking has no provider yet');
        }

        // Check if conversation exists
        const existing = await this.prisma.conversation.findFirst({
            where: { bookingId: BigInt(dto.bookingId) },
        });

        if (existing) {
            return existing;
        }

        // Create conversation
        return this.prisma.conversation.create({
            data: {
                bookingId: BigInt(dto.bookingId),
                customerId: booking.customerId,
                providerId: booking.providerId,
                lastMessageAt: new Date(),
                unreadCount: 0,
            },
        });
    }

    /**
     * Get messages
     */
    async getMessages(userId: bigint, conversationId: bigint) {
        const conversation = await this.prisma.conversation.findUnique({
            where: { id: conversationId },
        });

        if (!conversation) {
            throw new NotFoundException('Conversation not found');
        }

        if (
            conversation.customerId !== userId &&
            conversation.providerId !== userId
        ) {
            throw new ForbiddenException('Not a participant');
        }

        return this.prisma.message.findMany({
            where: { conversationId },
            orderBy: { createdAt: 'asc' },
            include: {
                sender: {
                    select: {
                        id: true,
                        profile: { select: { fullName: true, avatarUrl: true } },
                    },
                },
            },
        });
    }

    /**
     * Send message
     */
    async sendMessage(
        userId: bigint,
        conversationId: bigint,
        dto: SendMessageDto,
    ) {
        const conversation = await this.prisma.conversation.findUnique({
            where: { id: conversationId },
        });

        if (!conversation) {
            throw new NotFoundException('Conversation not found');
        }

        if (
            conversation.customerId !== userId &&
            conversation.providerId !== userId
        ) {
            throw new ForbiddenException('Not a participant');
        }

        return this.prisma.$transaction(async (tx) => {
            // Create message
            const message = await tx.message.create({
                data: {
                    conversationId,
                    senderId: userId,
                    body: dto.content,
                    // type: dto.type, // Schema doesn't have type yet, assuming body is text. If schema updated, uncomment.
                    // attachmentUrl: dto.attachmentUrl, // Schema doesn't have attachmentUrl yet.
                },
            });

            // Update conversation
            await tx.conversation.update({
                where: { id: conversationId },
                data: {
                    lastMessageAt: new Date(),
                    lastMessageId: message.id,
                    unreadCount: { increment: 1 },
                },
            });

            // Notify other participant
            const recipientId =
                conversation.customerId === userId
                    ? conversation.providerId
                    : conversation.customerId;

            await tx.notification.create({
                data: {
                    userId: recipientId,
                    title: 'New Message',
                    body: dto.content.substring(0, 50),
                    type: 'message',
                    payload: {
                        conversationId: conversationId.toString(),
                        messageId: message.id.toString(),
                    },
                    isRead: false,
                },
            });

            // Fetch message with sender info
            const fullMessage = await tx.message.findUnique({
                where: { id: message.id },
                include: {
                    sender: {
                        select: {
                            id: true,
                            profile: { select: { fullName: true, avatarUrl: true } },
                        },
                    },
                },
            });

            return fullMessage;
        });
    }

    /**
     * Mark as read
     */
    async markAsRead(userId: bigint, conversationId: bigint) {
        const conversation = await this.prisma.conversation.findUnique({
            where: { id: conversationId },
        });

        if (!conversation) {
            throw new NotFoundException('Conversation not found');
        }

        if (
            conversation.customerId !== userId &&
            conversation.providerId !== userId
        ) {
            throw new ForbiddenException('Not a participant');
        }

        // Only mark as read if user is the recipient of the last message?
        // Or just reset unread count for this user?
        // Current schema has single unreadCount, which is tricky for 2 users.
        // Usually unread count is per user-conversation relation.
        // For MVP/Schema provided: simple reset.

        return this.prisma.conversation.update({
            where: { id: conversationId },
            data: { unreadCount: 0 } // This is a simplification, ideally should track per user
        });
    }
}

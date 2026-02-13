import {
    Body,
    Controller,
    Get,
    Param,
    Patch,
    Post,
    UseGuards,
} from '@nestjs/common';
import {
    ApiBearerAuth,
    ApiOperation,
    ApiResponse,
    ApiTags,
} from '@nestjs/swagger';
import { ConversationsService } from './conversations.service';
import { CreateConversationDto, SendMessageDto } from './dto/conversation.dto';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { JwtPayload } from '../../common/interfaces/jwt-payload.interface';
import { ChatGateway } from './chat.gateway';

@ApiTags('Conversations')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('conversations')
export class ConversationsController {
    constructor(
        private conversationsService: ConversationsService,
        private chatGateway: ChatGateway
    ) { }

    @Get()
    @ApiOperation({ summary: 'List conversations' })
    async findAll(@CurrentUser() user: JwtPayload) {
        return this.conversationsService.findAll(BigInt(user.userId));
    }

    @Post()
    @ApiOperation({ summary: 'Create conversation' })
    async create(
        @CurrentUser() user: JwtPayload,
        @Body() dto: CreateConversationDto,
    ) {
        return this.conversationsService.createConversation(
            BigInt(user.userId),
            dto,
        );
    }

    @Get(':id/messages')
    @ApiOperation({ summary: 'Get messages' })
    async getMessages(@CurrentUser() user: JwtPayload, @Param('id') id: string) {
        return this.conversationsService.getMessages(
            BigInt(user.userId),
            BigInt(id),
        );
    }

    @Post(':id/messages')
    @ApiOperation({ summary: 'Send message' })
    async sendMessage(
        @CurrentUser() user: JwtPayload,
        @Param('id') id: string,
        @Body() dto: SendMessageDto,
    ) {
        const message = await this.conversationsService.sendMessage(
            BigInt(user.userId),
            BigInt(id),
            dto,
        );

        if (message) {
            // Emit real-time event
            this.chatGateway.emitNewMessage(id, {
                id: message.id.toString(),
                conversationId: id,
                senderId: message.senderId.toString(),
                body: message.body,
                createdAt: message.createdAt,
                sender: (message as any).sender
            });
        }

        return message;
    }

    @Patch(':id/read')
    @ApiOperation({ summary: 'Mark as read' })
    async markAsRead(@CurrentUser() user: JwtPayload, @Param('id') id: string) {
        return this.conversationsService.markAsRead(
            BigInt(user.userId),
            BigInt(id),
        );
    }
}

import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsEnum, IsNotEmpty, IsNumber, IsOptional, IsString } from 'class-validator';

export class CreateConversationDto {
    @ApiProperty({ example: 1 })
    @IsNotEmpty()
    @IsNumber()
    bookingId: number;
}

export class SendMessageDto {
    @ApiProperty({ example: 'Hello, I have arrived.' })
    @IsNotEmpty()
    @IsString()
    content: string;

    @ApiPropertyOptional({ enum: ['text', 'image', 'file'] })
    @IsOptional()
    @IsEnum(['text', 'image', 'file'])
    type?: string = 'text';

    @ApiPropertyOptional()
    @IsOptional()
    @IsString()
    attachmentUrl?: string;
}

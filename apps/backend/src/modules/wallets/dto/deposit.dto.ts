import { ApiProperty } from '@nestjs/swagger';
import { IsNotEmpty, IsNumber, IsEnum, Min } from 'class-validator';

export class DepositDto {
    @ApiProperty({
        description: 'Amount to deposit in VND',
        example: 500000,
        minimum: 100000,
    })
    @IsNotEmpty()
    @IsNumber()
    @Min(100000, { message: 'Minimum deposit is 100,000 VND' })
    amount: number;

    @ApiProperty({
        description: 'Payment gateway to use',
        enum: ['momo', 'bank_transfer', 'card'],
        example: 'momo',
    })
    @IsNotEmpty()
    @IsEnum(['momo', 'bank_transfer', 'card'], {
        message: 'Gateway must be one of: momo, bank_transfer, card',
    })
    gateway: string;
}

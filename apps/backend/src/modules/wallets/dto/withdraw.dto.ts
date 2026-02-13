import { ApiProperty } from '@nestjs/swagger';
import { IsNotEmpty, IsNumber, IsString, Min, Max } from 'class-validator';

export class WithdrawDto {
    @ApiProperty({
        description: 'Amount to withdraw in VND',
        example: 200000,
        minimum: 100000,
        maximum: 10000000,
    })
    @IsNotEmpty()
    @IsNumber()
    @Min(100000, { message: 'Minimum withdrawal is 100,000 VND' })
    @Max(10000000, { message: 'Maximum withdrawal per transaction is 10,000,000 VND' })
    amount: number;

    @ApiProperty({
        description: 'Bank account number',
        example: '1234567890',
    })
    @IsNotEmpty()
    @IsString()
    bankAccount: string;

    @ApiProperty({
        description: 'Bank name',
        example: 'Vietcombank',
    })
    @IsNotEmpty()
    @IsString()
    bankName: string;
}

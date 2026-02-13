import {
  Controller,
  Get,
  Post,
  Body,
  Query,
  UseGuards,
  ParseIntPipe,
} from '@nestjs/common';
import {
  ApiTags,
  ApiOperation,
  ApiResponse,
  ApiBearerAuth,
  ApiQuery,
} from '@nestjs/swagger';
import { WalletsService } from './wallets.service';
import { DepositDto, WithdrawDto } from './dto';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { JwtPayload } from '../../common/interfaces/jwt-payload.interface';

@ApiTags('Wallets')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('wallets')
export class WalletsController {
  constructor(private readonly walletsService: WalletsService) {}

  @Get('balance')
  @ApiOperation({ summary: 'Get wallet balance' })
  @ApiResponse({
    status: 200,
    description: 'Wallet balance retrieved successfully',
  })
  @ApiResponse({ status: 404, description: 'Wallet not found' })
  async getBalance(@CurrentUser() user: JwtPayload) {
    return this.walletsService.getBalance(BigInt(user.userId));
  }

  @Get('transactions')
  @ApiOperation({ summary: 'Get transaction history' })
  @ApiQuery({ name: 'page', required: false, type: Number, example: 1 })
  @ApiQuery({ name: 'limit', required: false, type: Number, example: 20 })
  @ApiResponse({
    status: 200,
    description: 'Transaction history retrieved successfully',
  })
  async getTransactions(
    @CurrentUser() user: JwtPayload,
    @Query('page') page?: string,
    @Query('limit') limit?: string,
  ) {
    const pageNum = page ? parseInt(page, 10) : 1;
    const limitNum = limit ? parseInt(limit, 10) : 20;

    return this.walletsService.getTransactions(
      BigInt(user.userId),
      pageNum,
      limitNum,
    );
  }

  @Post('deposit')
  @ApiOperation({ summary: 'Initiate deposit to wallet' })
  @ApiResponse({
    status: 201,
    description: 'Deposit initiated, payment URL returned',
  })
  @ApiResponse({ status: 400, description: 'Invalid deposit amount' })
  @ApiResponse({ status: 404, description: 'Wallet not found' })
  async deposit(
    @CurrentUser() user: JwtPayload,
    @Body() depositDto: DepositDto,
  ) {
    return this.walletsService.deposit(BigInt(user.userId), depositDto);
  }

  @Post('withdraw')
  @ApiOperation({ summary: 'Withdraw from wallet' })
  @ApiResponse({
    status: 201,
    description: 'Withdrawal processed or submitted for approval',
  })
  @ApiResponse({
    status: 400,
    description: 'Insufficient balance or invalid amount',
  })
  @ApiResponse({ status: 404, description: 'Wallet not found' })
  async withdraw(
    @CurrentUser() user: JwtPayload,
    @Body() withdrawDto: WithdrawDto,
  ) {
    return this.walletsService.withdraw(BigInt(user.userId), withdrawDto);
  }

  @Get('check-deposit-status')
  @ApiOperation({
    summary: 'Check deposit payment status and update wallet if successful',
  })
  @ApiQuery({ name: 'orderId', required: true, type: String })
  @ApiResponse({ status: 200, description: 'Payment status checked' })
  async checkDepositStatus(
    @CurrentUser() user: JwtPayload,
    @Query('orderId') orderId: string,
  ) {
    return this.walletsService.checkAndProcessDeposit(
      BigInt(user.userId),
      orderId,
    );
  }
}

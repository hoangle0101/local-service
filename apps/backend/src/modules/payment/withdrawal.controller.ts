import {
  Controller,
  Post,
  Get,
  Body,
  Param,
  UseGuards,
  Query,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { WithdrawalService, CreateWithdrawalDto } from './withdrawal.service';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { CurrentUser } from '../../common/decorators/current-user.decorator';

@ApiTags('Withdrawal')
@Controller('withdrawals')
export class WithdrawalController {
  constructor(private withdrawalService: WithdrawalService) {}

  /**
   * Create withdrawal request
   */
  @Post()
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Request withdrawal' })
  async createWithdrawal(
    @CurrentUser() user: any,
    @Body() dto: CreateWithdrawalDto,
  ) {
    return this.withdrawalService.createWithdrawal(BigInt(user.userId), dto);
  }

  /**
   * Get my withdrawals
   */
  @Get('me')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Get my withdrawals' })
  async getMyWithdrawals(
    @CurrentUser() user: any,
    @Query('status') status?: string,
  ) {
    return this.withdrawalService.getProviderWithdrawals(
      BigInt(user.userId),
      status,
    );
  }

  /**
   * Get pending withdrawals (admin)
   */
  @Get('pending')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Get pending withdrawals (admin)' })
  async getPendingWithdrawals() {
    return this.withdrawalService.getPendingWithdrawals();
  }

  /**
   * Approve withdrawal (admin)
   */
  @Post(':id/approve')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Approve withdrawal (admin)' })
  async approveWithdrawal(
    @CurrentUser() user: any,
    @Param('id') id: string,
    @Body('note') note?: string,
  ) {
    return this.withdrawalService.processWithdrawal(
      BigInt(id),
      BigInt(user.userId),
      true,
      note,
    );
  }

  /**
   * Reject withdrawal (admin)
   */
  @Post(':id/reject')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Reject withdrawal (admin)' })
  async rejectWithdrawal(
    @CurrentUser() user: any,
    @Param('id') id: string,
    @Body('note') note?: string,
  ) {
    return this.withdrawalService.processWithdrawal(
      BigInt(id),
      BigInt(user.userId),
      false,
      note,
    );
  }
}

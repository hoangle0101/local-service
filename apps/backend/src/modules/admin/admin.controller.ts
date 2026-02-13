import {
  Body,
  Controller,
  Param,
  Post,
  UseGuards,
  Get,
  Query,
  Patch,
} from '@nestjs/common';
import {
  ApiBearerAuth,
  ApiOperation,
  ApiResponse,
  ApiTags,
} from '@nestjs/swagger';
import { AdminService } from './admin.service';
import {
  ResolveDisputeDto,
  AdminDashboardQueryDto,
  AdminDisputesQueryDto,
  AdminWithdrawalsQueryDto,
  ApproveWithdrawalDto,
  RejectWithdrawalDto,
  AdminUsersQueryDto,
  AdminProvidersQueryDto,
  BanUserDto,
  VerifyUserDto,
  VerifyProviderDto,
  AdminBookingsQueryDto,
  AdminPaymentsQueryDto,
  AdminRevenueReportQueryDto,
  AdminServicesReportQueryDto,
  AdminUsersReportQueryDto,
  CreateAnnouncementDto,
  AdminAnnouncementsQueryDto,
} from './dto/admin.dto';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { RolesGuard } from '../../common/guards/roles.guard';
import { Roles } from '../../common/decorators/roles.decorator';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { JwtPayload } from '../../common/interfaces/jwt-payload.interface';

@ApiTags('Admin')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard, RolesGuard)
@Controller('admin')
export class AdminController {
  constructor(private adminService: AdminService) {}

  /**
   * Get admin dashboard with overview statistics
   */
  @Get('dashboard')
  @Roles('admin', 'super_admin')
  @ApiOperation({ summary: 'Get admin dashboard overview' })
  @ApiResponse({
    status: 200,
    description: 'Dashboard data retrieved successfully',
  })
  async getDashboard(@Query() query: AdminDashboardQueryDto) {
    return this.adminService.getDashboard(query);
  }

  /**
   * Get list of disputes from admin perspective
   */
  @Get('disputes')
  @Roles('admin', 'super_admin')
  @ApiOperation({ summary: 'Get all disputes (admin view)' })
  @ApiResponse({
    status: 200,
    description: 'Disputes list retrieved successfully',
  })
  async getDisputes(@Query() query: AdminDisputesQueryDto) {
    return this.adminService.getDisputesForAdmin(query);
  }

  /**
   * Get single dispute detail for admin
   */
  @Get('disputes/:id')
  @Roles('admin', 'super_admin')
  @ApiOperation({ summary: 'Get dispute detail (admin view)' })
  @ApiResponse({ status: 200, description: 'Dispute detail retrieved' })
  @ApiResponse({ status: 404, description: 'Dispute not found' })
  async getDisputeDetail(
    @Param('id') disputeId: string,
    @Query('includeTimeline') includeTimeline?: string,
    @Query('includeEvidence') includeEvidence?: string,
  ) {
    return this.adminService.getDisputeDetailForAdmin(
      BigInt(disputeId),
      includeTimeline === 'true',
      includeEvidence === 'true',
    );
  }

  /**
   * Get list of withdrawal requests
   */
  @Get('withdrawals')
  @Roles('admin', 'super_admin')
  @ApiOperation({ summary: 'Get withdrawal requests' })
  @ApiResponse({
    status: 200,
    description: 'Withdrawals list retrieved successfully',
  })
  async getWithdrawals(@Query() query: AdminWithdrawalsQueryDto) {
    return this.adminService.getWithdrawalsForAdmin(query);
  }

  /**
   * Approve withdrawal request
   */
  @Patch('withdrawals/:id/approve')
  @Roles('admin', 'super_admin')
  @ApiOperation({ summary: 'Approve withdrawal request' })
  @ApiResponse({ status: 200, description: 'Withdrawal approved successfully' })
  @ApiResponse({ status: 400, description: 'Invalid withdrawal request' })
  @ApiResponse({ status: 404, description: 'Withdrawal not found' })
  async approveWithdrawal(
    @CurrentUser() user: JwtPayload,
    @Param('id') transactionId: string,
    @Body() dto: ApproveWithdrawalDto,
  ) {
    return this.adminService.approveWithdrawal(
      BigInt(transactionId),
      BigInt(user.userId),
      dto,
    );
  }

  /**
   * Reject withdrawal request
   */
  @Patch('withdrawals/:id/reject')
  @Roles('admin', 'super_admin')
  @ApiOperation({ summary: 'Reject withdrawal request' })
  @ApiResponse({ status: 200, description: 'Withdrawal rejected successfully' })
  @ApiResponse({ status: 400, description: 'Invalid withdrawal request' })
  @ApiResponse({ status: 404, description: 'Withdrawal not found' })
  async rejectWithdrawal(
    @CurrentUser() user: JwtPayload,
    @Param('id') transactionId: string,
    @Body() dto: RejectWithdrawalDto,
  ) {
    return this.adminService.rejectWithdrawal(
      BigInt(transactionId),
      BigInt(user.userId),
      dto,
    );
  }

  /**
   * Escalate dispute
   */
  @Post('disputes/:id/escalate')
  @Roles('admin', 'super_admin')
  @ApiOperation({ summary: 'Escalate dispute' })
  @ApiResponse({ status: 200, description: 'Dispute escalated' })
  async escalateDispute(
    @CurrentUser() user: JwtPayload,
    @Param('id') id: string,
    @Body() dto: { reason?: string },
  ) {
    return this.adminService.escalateDispute(
      BigInt(id),
      BigInt(user.userId),
      dto.reason || 'Escalated by admin',
    );
  }

  /**
   * Request response from party
   */
  @Post('disputes/:id/request-response')
  @Roles('admin', 'super_admin')
  @ApiOperation({ summary: 'Request response from a party' })
  @ApiResponse({ status: 200, description: 'Response requested' })
  async requestDisputeResponse(
    @CurrentUser() user: JwtPayload,
    @Param('id') id: string,
    @Body()
    dto: {
      targetParty: 'customer' | 'provider';
      message?: string;
      deadlineHours?: number;
    },
  ) {
    return this.adminService.requestDisputeResponse(
      BigInt(id),
      BigInt(user.userId),
      dto,
    );
  }

  /**
   * Resolve dispute
   */
  @Post('disputes/:id/resolve')
  @Roles('admin', 'super_admin')
  @ApiOperation({ summary: 'Resolve dispute' })
  @ApiResponse({ status: 200, description: 'Dispute resolved' })
  async resolveDispute(
    @CurrentUser() user: JwtPayload,
    @Param('id') id: string,
    @Body() dto: ResolveDisputeDto,
  ) {
    return this.adminService.resolveDispute(
      BigInt(id),
      BigInt(user.userId),
      dto,
    );
  }

  /**
   * Get list of all users
   */
  @Get('users')
  @Roles('admin', 'super_admin')
  @ApiOperation({ summary: 'Get all users (admin view)' })
  @ApiResponse({
    status: 200,
    description: 'Users list retrieved successfully',
  })
  async getUsers(@Query() query: AdminUsersQueryDto) {
    return this.adminService.getUsers(query);
  }

  /**
   * Get list of all providers
   */
  @Get('providers')
  @Roles('admin', 'super_admin')
  @ApiOperation({ summary: 'Get all providers (admin view)' })
  @ApiResponse({
    status: 200,
    description: 'Providers list retrieved successfully',
  })
  async getProviders(@Query() query: AdminProvidersQueryDto) {
    return this.adminService.getProviders(query);
  }

  /**
   * Get single user detail for admin
   */
  @Get('users/:id')
  @Roles('admin', 'super_admin')
  @ApiOperation({ summary: 'Get user detail (admin view)' })
  @ApiResponse({
    status: 200,
    description: 'User detail retrieved successfully',
  })
  @ApiResponse({ status: 404, description: 'User not found' })
  async getUserDetail(@Param('id') userId: string) {
    return this.adminService.getUserDetail(BigInt(userId));
  }

  /**
   * Get single provider detail for admin
   */
  @Get('providers/:id')
  @Roles('admin', 'super_admin')
  @ApiOperation({ summary: 'Get provider detail (admin view)' })
  @ApiResponse({
    status: 200,
    description: 'Provider detail retrieved successfully',
  })
  @ApiResponse({ status: 404, description: 'Provider not found' })
  async getProviderDetail(@Param('id') userId: string) {
    return this.adminService.getProviderDetail(BigInt(userId));
  }

  /**
   * Ban or unban a user
   */
  @Patch('users/:id/ban')
  @Roles('admin', 'super_admin')
  @ApiOperation({ summary: 'Ban or unban user' })
  @ApiResponse({
    status: 200,
    description: 'User banned/unbanned successfully',
  })
  @ApiResponse({ status: 400, description: 'Invalid action or user status' })
  @ApiResponse({ status: 404, description: 'User not found' })
  async banUser(
    @CurrentUser() user: JwtPayload,
    @Param('id') userId: string,
    @Body() dto: BanUserDto,
  ) {
    return this.adminService.banUser(BigInt(userId), BigInt(user.userId), dto);
  }

  /**
   * Manually verify or unverify a user
   */
  @Patch('users/:id/verify')
  @Roles('admin', 'super_admin')
  @ApiOperation({ summary: 'Manually verify or unverify user' })
  @ApiResponse({ status: 200, description: 'User verification status updated' })
  @ApiResponse({ status: 404, description: 'User not found' })
  async verifyUser(
    @CurrentUser() user: JwtPayload,
    @Param('id') userId: string,
    @Body() dto: VerifyUserDto,
  ) {
    return this.adminService.verifyUser(
      BigInt(userId),
      BigInt(user.userId),
      dto,
    );
  }

  /**
   * Verify or reject provider
   */
  @Patch('providers/:id/verify')
  @Roles('admin', 'super_admin')
  @ApiOperation({ summary: 'Verify or reject provider' })
  @ApiResponse({
    status: 200,
    description: 'Provider status updated successfully',
  })
  @ApiResponse({ status: 400, description: 'Invalid action or missing fields' })
  @ApiResponse({ status: 404, description: 'Provider not found' })
  async verifyProvider(
    @CurrentUser() user: JwtPayload,
    @Param('id') userId: string,
    @Body() dto: VerifyProviderDto,
  ) {
    return this.adminService.verifyProvider(
      BigInt(userId),
      BigInt(user.userId),
      dto,
    );
  }

  /**
   * Get list of all bookings
   */
  @Get('bookings')
  @Roles('admin', 'super_admin')
  @ApiOperation({ summary: 'Get all bookings (admin view)' })
  @ApiResponse({
    status: 200,
    description: 'Bookings list retrieved successfully',
  })
  async getBookings(@Query() query: AdminBookingsQueryDto) {
    return this.adminService.getBookings(query);
  }

  /**
   * Get single booking detail
   */
  @Get('bookings/:id')
  @Roles('admin', 'super_admin')
  @ApiOperation({ summary: 'Get booking detail (admin view)' })
  @ApiResponse({
    status: 200,
    description: 'Booking detail retrieved successfully',
  })
  @ApiResponse({ status: 404, description: 'Booking not found' })
  async getBookingDetail(@Param('id') bookingId: string) {
    return this.adminService.getBookingDetail(BigInt(bookingId));
  }

  /**
   * Get list of all payments
   */
  @Get('payments')
  @Roles('admin', 'super_admin')
  @ApiOperation({ summary: 'Get all payments (admin view)' })
  @ApiResponse({
    status: 200,
    description: 'Payments list retrieved successfully',
  })
  async getPayments(@Query() query: AdminPaymentsQueryDto) {
    return this.adminService.getPayments(query);
  }

  /**
   * Get user wallet details
   */
  @Get('wallets/:userId')
  @Roles('admin', 'super_admin')
  @ApiOperation({ summary: 'Get user wallet details' })
  @ApiResponse({
    status: 200,
    description: 'Wallet details retrieved successfully',
  })
  @ApiResponse({ status: 404, description: 'Wallet not found' })
  async getWallet(
    @Param('userId') userId: string,
    @Query('page') page?: string,
    @Query('limit') limit?: string,
  ) {
    const pageNum = page ? parseInt(page, 10) : 1;
    const limitNum = limit ? parseInt(limit, 10) : 20;
    return this.adminService.getWallet(BigInt(userId), pageNum, limitNum);
  }

  /**
   * Get revenue analytics report
   */
  @Get('reports/revenue')
  @Roles('admin', 'super_admin')
  @ApiOperation({ summary: 'Get revenue analytics report' })
  @ApiResponse({
    status: 200,
    description: 'Revenue report retrieved successfully',
  })
  async getRevenueReport(@Query() query: AdminRevenueReportQueryDto) {
    return this.adminService.getRevenueReport(query);
  }

  /**
   * Get services analytics report
   */
  @Get('reports/services')
  @Roles('admin', 'super_admin')
  @ApiOperation({ summary: 'Get services analytics report' })
  @ApiResponse({
    status: 200,
    description: 'Services report retrieved successfully',
  })
  async getServicesReport(@Query() query: AdminServicesReportQueryDto) {
    return this.adminService.getServicesReport(query);
  }

  /**
   * Get users analytics report
   */
  @Get('reports/users')
  @Roles('admin', 'super_admin')
  @ApiOperation({ summary: 'Get users analytics report' })
  @ApiResponse({
    status: 200,
    description: 'Users report retrieved successfully',
  })
  async getUsersReport(@Query() query: AdminUsersReportQueryDto) {
    return this.adminService.getUsersReport(query);
  }

  /**
   * Create system announcement
   */
  @Post('announcements')
  @Roles('admin', 'super_admin')
  @ApiOperation({ summary: 'Create system announcement' })
  @ApiResponse({
    status: 201,
    description: 'Announcement created successfully',
  })
  async createAnnouncement(
    @CurrentUser() user: JwtPayload,
    @Body() dto: CreateAnnouncementDto,
  ) {
    return this.adminService.createAnnouncement(BigInt(user.userId), dto);
  }

  /**
   * Get system announcements
   */
  @Get('announcements')
  @Roles('admin', 'super_admin')
  @ApiOperation({ summary: 'Get system announcements' })
  @ApiResponse({
    status: 200,
    description: 'Announcements list retrieved successfully',
  })
  async getAnnouncements(@Query() query: AdminAnnouncementsQueryDto) {
    return this.adminService.getAnnouncements(query);
  }
}

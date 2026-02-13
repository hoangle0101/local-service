import {
  Controller,
  Get,
  Post,
  Patch,
  Param,
  Body,
  UseGuards,
} from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { ServiceQuotesService } from './service-quotes.service';
import {
  CreateServiceQuoteDto,
  AcceptQuoteDto,
  RejectQuoteDto,
} from './dto/service-quote.dto';

@ApiTags('Service Quotes')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller()
export class ServiceQuotesController {
  constructor(private readonly serviceQuotesService: ServiceQuotesService) {}

  @Post('bookings/:bookingId/quotes')
  @ApiOperation({ summary: 'Provider creates a quote for a booking' })
  async createQuote(
    @Param('bookingId') bookingId: string,
    @Body() dto: CreateServiceQuoteDto,
    @CurrentUser() user: any,
  ) {
    return this.serviceQuotesService.createQuote(
      BigInt(bookingId),
      BigInt(user.userId),
      dto,
    );
  }

  @Get('bookings/:bookingId/quotes')
  @ApiOperation({ summary: 'Get all quotes for a booking' })
  async getQuotesForBooking(
    @Param('bookingId') bookingId: string,
    @CurrentUser() user: any,
  ) {
    return this.serviceQuotesService.getQuotesForBooking(
      BigInt(bookingId),
      BigInt(user.userId),
    );
  }

  @Get('quotes/:quoteId')
  @ApiOperation({ summary: 'Get quote by ID' })
  async getQuoteById(
    @Param('quoteId') quoteId: string,
    @CurrentUser() user: any,
  ) {
    return this.serviceQuotesService.getQuoteById(
      BigInt(quoteId),
      BigInt(user.userId),
    );
  }

  @Patch('quotes/:quoteId/accept')
  @ApiOperation({ summary: 'Customer accepts a quote' })
  async acceptQuote(
    @Param('quoteId') quoteId: string,
    @Body() dto: AcceptQuoteDto,
    @CurrentUser() user: any,
  ) {
    return this.serviceQuotesService.acceptQuote(
      BigInt(quoteId),
      BigInt(user.userId),
      dto,
    );
  }

  @Patch('quotes/:quoteId/reject')
  @ApiOperation({ summary: 'Customer rejects a quote' })
  async rejectQuote(
    @Param('quoteId') quoteId: string,
    @Body() dto: RejectQuoteDto,
    @CurrentUser() user: any,
  ) {
    return this.serviceQuotesService.rejectQuote(
      BigInt(quoteId),
      BigInt(user.userId),
      dto,
    );
  }

  @Patch('quotes/:quoteId/agree-reject')
  @ApiOperation({ summary: 'Provider agrees to rejection - cancels booking' })
  async providerAgreeReject(
    @Param('quoteId') quoteId: string,
    @CurrentUser() user: any,
  ) {
    return this.serviceQuotesService.providerAgreeReject(
      BigInt(quoteId),
      BigInt(user.userId),
    );
  }
}

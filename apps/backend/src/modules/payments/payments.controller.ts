import {
    Body,
    Controller,
    Headers,
    Param,
    Post,
    UseGuards,
} from '@nestjs/common';
import {
    ApiBearerAuth,
    ApiOperation,
    ApiResponse,
    ApiTags,
} from '@nestjs/swagger';
import { PaymentsService } from './payments.service';
import { CheckoutDto, WebhookDto } from './dto/payment.dto';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { JwtPayload } from '../../common/interfaces/jwt-payload.interface';

@ApiTags('Payments')
@Controller('payments')
export class PaymentsController {
    constructor(private paymentsService: PaymentsService) { }

    @Post('checkout')
    @UseGuards(JwtAuthGuard)
    @ApiBearerAuth()
    @ApiOperation({ summary: 'Checkout booking' })
    @ApiResponse({ status: 201, description: 'Payment initiated' })
    async checkout(@CurrentUser() user: JwtPayload, @Body() dto: CheckoutDto) {
        return this.paymentsService.checkout(BigInt(user.userId), dto);
    }

    @Post('webhook/:gateway')
    @ApiOperation({ summary: 'Payment webhook' })
    @ApiResponse({ status: 200, description: 'Webhook processed' })
    async webhook(
        @Param('gateway') gateway: string,
        @Body() body: WebhookDto,
        @Headers('signature') signature: string,
    ) {
        return this.paymentsService.handleWebhook(gateway, body, signature || '');
    }
}

import { Module, MiddlewareConsumer, NestModule } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { ScheduleModule } from '@nestjs/schedule';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { PrismaModule } from './prisma/prisma.module';
import { AuthModule } from './modules/auth/auth.module';
import { UsersModule } from './modules/users/users.module';
import { SystemModule } from './modules/system/system.module';
import { ServicesModule } from './modules/services/services.module';
import { MarketplaceModule } from './modules/marketplace/marketplace.module';
import { ProviderModule } from './modules/provider/provider.module';
import { BookingsModule } from './modules/bookings/bookings.module';
import { PaymentsModule } from './modules/payments/payments.module';
import { WalletsModule } from './modules/wallets/wallets.module';
import { ConversationsModule } from './modules/conversations/conversations.module';
import { DisputesModule } from './modules/disputes/disputes.module';
import { AdminModule } from './modules/admin/admin.module';
import { ReviewsModule } from './modules/reviews/reviews.module';
import { PaymentModule } from './modules/payment/payment.module';
import { NotificationsModule } from './modules/notifications/notifications.module';
import { GatewayModule } from './modules/gateway/gateway.module';
import { ServiceQuotesModule } from './modules/service-quotes/service-quotes.module';
import { ProviderServiceItemsModule } from './modules/provider-service-items/provider-service-items.module';
import { LoggerMiddleware } from './common/middleware/logger.middleware';
import configuration from './config/configuration';

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
      load: [configuration],
    }),
    ScheduleModule.forRoot(),
    GatewayModule,
    PrismaModule,
    AuthModule,
    UsersModule,
    SystemModule,
    ServicesModule,
    MarketplaceModule,
    ProviderModule,
    BookingsModule,
    PaymentsModule,
    WalletsModule,
    ConversationsModule,
    DisputesModule,
    AdminModule,
    ReviewsModule,
    PaymentModule,
    NotificationsModule,
    ServiceQuotesModule,
    ProviderServiceItemsModule,
  ],
  controllers: [AppController],
  providers: [AppService],
})
export class AppModule implements NestModule {
  configure(consumer: MiddlewareConsumer) {
    consumer.apply(LoggerMiddleware).forRoutes('*');
  }
}

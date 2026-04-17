import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';
import { ValidationPipe, Logger } from '@nestjs/common';
import { DocumentBuilder, SwaggerModule } from '@nestjs/swagger';
import { GlobalExceptionFilter } from './common/filters/http-exception.filter';
import { TransformInterceptor } from './common/interceptors/transform.interceptor';
import { NestExpressApplication } from '@nestjs/platform-express';
import { join } from 'path';
import { existsSync, mkdirSync } from 'fs';
import helmet from 'helmet';

// Fix BigInt serialization globally
BigInt.prototype['toJSON'] = function () {
  return this.toString();
};

async function bootstrap() {
  const logger = new Logger('Bootstrap');
  
  try {
    const app = await NestFactory.create<NestExpressApplication>(AppModule);

    // Security: Add helmet middleware for security headers
    app.use(helmet());

    app.enableCors();

    // Ensure uploads directories exist (use CWD since multer uses relative paths)
    const uploadsDir = join(process.cwd(), 'uploads');
    const avatarsDir = join(uploadsDir, 'avatars');
    if (!existsSync(uploadsDir)) {
      mkdirSync(uploadsDir, { recursive: true });
    }
    if (!existsSync(avatarsDir)) {
      mkdirSync(avatarsDir, { recursive: true });
    }
    console.log('[Server] Uploads directory:', uploadsDir);

    // Serve static files from uploads directory (same path as multer)
    app.useStaticAssets(uploadsDir, {
      prefix: '/uploads/',
    });

    app.useGlobalPipes(
      new ValidationPipe({
        whitelist: true,
        transform: true,
      }),
    );

    app.useGlobalFilters(new GlobalExceptionFilter());
    app.useGlobalInterceptors(new TransformInterceptor());

    const config = new DocumentBuilder()
      .setTitle('Local Service Platform API')
      .setDescription('The Local Service Platform API description')
      .setVersion('1.0')
      .addBearerAuth()
      .build();
    const document = SwaggerModule.createDocument(app, config);
    SwaggerModule.setup('api', app, document);

    const server = await app.listen(3000);
    logger.log(`[Server] STARTED AT: ${new Date().toISOString()}`);
    logger.log('[Server] Running on http://localhost:3000');
    logger.log('Swagger API docs at http://localhost:3000/api');

    // Graceful shutdown handling
    process.on('SIGTERM', () => {
      logger.warn('SIGTERM received. Starting graceful shutdown...');
      server.close(() => {
        logger.log('Server closed gracefully');
        process.exit(0);
      });
      // Force shutdown after 30 seconds
      setTimeout(() => {
        logger.error('Forced shutdown due to timeout');
        process.exit(1);
      }, 30000);
    });

    process.on('SIGINT', () => {
      logger.warn('SIGINT received. Starting graceful shutdown...');
      server.close(() => {
        logger.log('Server closed gracefully');
        process.exit(0);
      });
      // Force shutdown after 30 seconds
      setTimeout(() => {
        logger.error('Forced shutdown due to timeout');
        process.exit(1);
      }, 30000);
    });

    // Handle unhandled exceptions
    process.on('uncaughtException', (error) => {
      logger.error('Uncaught Exception:', error);
      process.exit(1);
    });

    process.on('unhandledRejection', (reason, promise) => {
      logger.error('Unhandled Rejection at:', promise, 'reason:', reason);
      process.exit(1);
    });
  } catch (error) {
    logger.error('Failed to start server:', error);
    process.exit(1);
  }
}
bootstrap();

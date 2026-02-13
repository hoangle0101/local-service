import { Injectable, NestMiddleware, Logger } from '@nestjs/common';
import { Request, Response, NextFunction } from 'express';

@Injectable()
export class LoggerMiddleware implements NestMiddleware {
  private logger = new Logger('HTTP');

  use(request: Request, response: Response, next: NextFunction): void {
    const { method, originalUrl, body } = request;
    const userAgent = request.get('user-agent') || '';

    const query =
      Object.keys(request.query).length > 0
        ? `?${JSON.stringify(request.query)}`
        : '';
    this.logger.log(`${method} ${originalUrl}${query} - Agent: ${userAgent}`);

    if (body && Object.keys(body).length > 0) {
      this.logger.log(`[Body]: ${JSON.stringify(body)}`);
    } else if (method === 'POST') {
      this.logger.log(`[Body]: EMPTY`);
    }

    next();
  }
}

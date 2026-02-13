import { Injectable, BadRequestException, HttpException } from '@nestjs/common';
import * as crypto from 'crypto';
import * as https from 'https';

export interface MomoPaymentRequest {
  orderId: string;
  amount: number;
  orderInfo: string;
  extraData?: string;
}

export interface MomoPaymentResponse {
  resultCode: number;
  message: string;
  payUrl?: string;
  qrCodeUrl?: string;
  deeplink?: string;
  orderId: string;
  requestId: string;
}

export interface MomoCallbackData {
  partnerCode: string;
  orderId: string;
  requestId: string;
  amount: number;
  transId: string | number;
  resultCode: number;
  message: string;
  responseTime: number;
  extraData: string;
  signature: string;
}

@Injectable()
export class MomoService {
  // MoMo Developer/Sandbox credentials
  private readonly config = {
    accessKey: 'F8BBA842ECF85',
    secretKey: 'K951B6PE1waDMi640xX08PD3vg6EkVlz',
    partnerCode: 'MOMO',
    redirectUrl: 'myapp://',
    ipnUrl:
      'https://renewable-waiting-hunting-regulations.trycloudflare.com/payments/momo/callback',
    requestType: 'captureWallet',
    autoCapture: true,
    lang: 'vi',
  };

  /**
   * Make HTTPS request to MoMo API
   */
  private async httpRequest(url: string, data: any): Promise<any> {
    return new Promise((resolve, reject) => {
      const urlObj = new URL(url);
      const postData = JSON.stringify(data);

      const options = {
        hostname: urlObj.hostname,
        port: 443,
        path: urlObj.pathname,
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Content-Length': Buffer.byteLength(postData),
        },
      };

      const req = https.request(options, (res) => {
        let body = '';
        res.on('data', (chunk) => (body += chunk));
        res.on('end', () => {
          try {
            resolve(JSON.parse(body));
          } catch (e) {
            reject(new Error(`Invalid JSON response: ${body}`));
          }
        });
      });

      req.on('error', reject);
      req.write(postData);
      req.end();
    });
  }

  /**
   * Create MoMo payment request
   */
  async createPayment(
    request: MomoPaymentRequest,
  ): Promise<MomoPaymentResponse> {
    const { orderId, amount, orderInfo, extraData = '' } = request;
    const requestId = `${orderId}_${Date.now()}`;

    // Build raw signature
    const rawSignature = [
      `accessKey=${this.config.accessKey}`,
      `amount=${amount}`,
      `extraData=${extraData}`,
      `ipnUrl=${this.config.ipnUrl}`,
      `orderId=${orderId}`,
      `orderInfo=${orderInfo}`,
      `partnerCode=${this.config.partnerCode}`,
      `redirectUrl=${this.config.redirectUrl}`,
      `requestId=${requestId}`,
      `requestType=${this.config.requestType}`,
    ].join('&');

    // Create HMAC SHA256 signature
    const signature = crypto
      .createHmac('sha256', this.config.secretKey)
      .update(rawSignature)
      .digest('hex');

    const requestBody = {
      partnerCode: this.config.partnerCode,
      partnerName: 'Local Service Platform',
      storeId: 'LocalService',
      requestId,
      amount,
      orderId,
      orderInfo,
      redirectUrl: this.config.redirectUrl,
      ipnUrl: this.config.ipnUrl,
      lang: this.config.lang,
      requestType: this.config.requestType,
      autoCapture: this.config.autoCapture,
      extraData,
      signature,
    };

    console.log('[MoMo] Creating payment:', { orderId, amount, orderInfo });
    console.log('[MoMo] Request Body:', JSON.stringify(requestBody, null, 2));

    try {
      const response = await this.httpRequest(
        'https://test-payment.momo.vn/v2/gateway/api/create',
        requestBody,
      );

      console.log('[MoMo] Response:', response);

      if (response.resultCode !== 0) {
        throw new BadRequestException(
          `MoMo error: ${response.message} (code: ${response.resultCode})`,
        );
      }

      return response;
    } catch (error) {
      console.error('[MoMo] Error creating payment:', error.message);
      throw new BadRequestException(
        `Failed to create MoMo payment: ${error.message}`,
      );
    }
  }

  /**
   * Verify MoMo callback signature
   */
  verifySignature(data: MomoCallbackData): boolean {
    const rawSignature = [
      `accessKey=${this.config.accessKey}`,
      `amount=${data.amount}`,
      `extraData=${data.extraData}`,
      `message=${data.message}`,
      `orderId=${data.orderId}`,
      `partnerCode=${data.partnerCode}`,
      `requestId=${data.requestId}`,
      `responseTime=${data.responseTime}`,
      `resultCode=${data.resultCode}`,
      `transId=${data.transId}`,
    ].join('&');

    const expectedSignature = crypto
      .createHmac('sha256', this.config.secretKey)
      .update(rawSignature)
      .digest('hex');

    const isValid = expectedSignature === data.signature;
    console.log('[MoMo] IPN Raw Signature String:', rawSignature);
    console.log('[MoMo] Expected Signature:', expectedSignature);
    console.log('[MoMo] Received Signature:', data.signature);
    console.log(
      '[MoMo] Signature verification:',
      isValid ? 'VALID' : 'INVALID',
    );

    return isValid;
  }

  /**
   * Query payment status
   */
  async queryPayment(orderId: string, requestId: string): Promise<any> {
    const rawSignature = [
      `accessKey=${this.config.accessKey}`,
      `orderId=${orderId}`,
      `partnerCode=${this.config.partnerCode}`,
      `requestId=${requestId}`,
    ].join('&');

    const signature = crypto
      .createHmac('sha256', this.config.secretKey)
      .update(rawSignature)
      .digest('hex');

    const requestBody = {
      partnerCode: this.config.partnerCode,
      requestId,
      orderId,
      signature,
      lang: this.config.lang,
    };

    try {
      const response = await this.httpRequest(
        'https://test-payment.momo.vn/v2/gateway/api/query',
        requestBody,
      );
      return response;
    } catch (error) {
      console.error('[MoMo] Error querying payment:', error.message);
      throw new BadRequestException(
        `Failed to query payment: ${error.message}`,
      );
    }
  }

  /**
   * Check if payment was successful
   */
  isPaymentSuccessful(resultCode: number): boolean {
    return resultCode === 0;
  }

  /**
   * Update IPN URL (for ngrok tunnel changes)
   */
  setIpnUrl(url: string): void {
    (this.config as any).ipnUrl = url;
    console.log('[MoMo] IPN URL updated to:', url);
  }
}

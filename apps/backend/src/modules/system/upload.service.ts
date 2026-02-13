import { Injectable, BadRequestException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import * as path from 'path';
import * as fs from 'fs';

@Injectable()
export class UploadService {
  constructor(private prisma: PrismaService) {}

  async uploadFile(userId: bigint, file: Express.Multer.File) {
    // Validate file type
    const allowedTypes = [
      'image/jpeg',
      'image/jpg',
      'image/png',
      'image/webp',
      'application/pdf',
    ];

    if (!allowedTypes.includes(file.mimetype)) {
      throw new BadRequestException(
        'Invalid file type. Allowed: JPEG, PNG, WEBP, PDF',
      );
    }

    // Validate file size (5MB max)
    const maxSize = 5 * 1024 * 1024; // 5MB
    if (file.size > maxSize) {
      throw new BadRequestException('File too large. Maximum size: 5MB');
    }

    // Generate unique filename
    const ext = path.extname(file.originalname);
    const filename = `${Date.now()}-${Math.random().toString(36).substring(7)}${ext}`;
    const relativePath = path.join('uploads', userId.toString(), filename);
    // Save to uploads/ directory (same as what static server serves)
    const fullPath = path.join(process.cwd(), relativePath);

    // Create directory if not exists
    const dir = path.dirname(fullPath);
    if (!fs.existsSync(dir)) {
      fs.mkdirSync(dir, { recursive: true });
    }

    // Save file
    fs.writeFileSync(fullPath, file.buffer);

    // Determine media category
    const category = file.mimetype.startsWith('image') ? 'image' : 'document';

    // Create Media record
    const media = await this.prisma.media.create({
      data: {
        ownerType: 'user',
        ownerId: userId,
        url: `/${relativePath.replace(/\\/g, '/')}`,
        mimeType: file.mimetype,
        size: file.size,
        category,
        isPublic: false,
        uploadedBy: userId,
        meta: {
          originalName: file.originalname,
        },
      },
    });

    // Build full URL for frontend
    const baseUrl = process.env.APP_URL || 'http://localhost:3000';
    const fullUrl = `${baseUrl}${media.url}`;

    return {
      id: media.id.toString(),
      url: media.url, // Trả về đường dẫn tương đối (ví dụ: /uploads/...)
      category: media.category,
      size: media.size,
    };
  }

  async getPresignedUrl(userId: bigint, filename: string, contentType: string) {
    // For MVP: Return direct upload URL
    // TODO: Implement S3 presigned URL for production
    const ext = path.extname(filename);
    const uniqueFilename = `${Date.now()}-${Math.random().toString(36).substring(7)}${ext}`;
    const uploadPath = `/uploads/${userId}/${uniqueFilename}`;

    return {
      uploadUrl: `/api/v1/system/upload`,
      fileUrl: uploadPath,
      expiresIn: 3600, // 1 hour
      message: 'Use POST /system/upload with multipart/form-data',
    };
  }
}

# 📘 Module Development Guide

Hướng dẫn chi tiết để implement một module mới trong dự án backend.

---

## 📋 Table of Contents

1. [Cấu trúc Module](#cấu-trúc-module)
2. [Step-by-Step Implementation](#step-by-step-implementation)
3. [Patterns & Best Practices](#patterns--best-practices)
4. [Examples](#examples)
5. [Checklist](#checklist)

---

## 🏗️ Cấu trúc Module

Mỗi module tuân theo cấu trúc chuẩn NestJS:

```
src/modules/[module-name]/
├── dto/
│   └── [module].dto.ts          # Data Transfer Objects
├── [module].controller.ts       # API Endpoints
├── [module].service.ts          # Business Logic
└── [module].module.ts           # Module Definition
```

---

## 🚀 Step-by-Step Implementation

### **Step 1: Tạo DTOs**

**File:** `dto/[module].dto.ts`

```typescript
import { IsNotEmpty, IsOptional, IsString, IsNumber, IsEnum } from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

// DTO cho Create
export class Create[Module]Dto {
  @ApiProperty({ example: 'Example value', description: 'Field description' })
  @IsNotEmpty()
  @IsString()
  fieldName: string;

  @ApiPropertyOptional({ example: 100 })
  @IsOptional()
  @IsNumber()
  optionalField?: number;
}

// DTO cho Update
export class Update[Module]Dto {
  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  fieldName?: string;
}

// DTO cho Query/Filter
export class Query[Module]Dto {
  @ApiPropertyOptional({ enum: ['active', 'inactive'] })
  @IsOptional()
  @IsEnum(['active', 'inactive'])
  status?: string;
}
```

**📌 Lưu ý:**

- Sử dụng `class-validator` decorators để validate
- Sử dụng `@ApiProperty` để generate Swagger docs
- Tạo riêng DTO cho Create, Update, Query
- Dùng `?` cho optional fields

---

### **Step 2: Tạo Service**

**File:** `[module].service.ts`

```typescript
import { Injectable, NotFoundException, BadRequestException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { Create[Module]Dto, Update[Module]Dto } from './dto/[module].dto';

@Injectable()
export class [Module]Service {
  constructor(private prisma: PrismaService) {}

  // CREATE
  async create(userId: bigint, dto: Create[Module]Dto) {
    // Validate business rules
    const existing = await this.prisma.[model].findFirst({
      where: { /* conditions */ }
    });

    if (existing) {
      throw new BadRequestException('Already exists');
    }

    // Create record
    return this.prisma.[model].create({
      data: {
        userId,
        ...dto,
      },
      include: {
        // Include relations if needed
      }
    });
  }

  // READ - List
  async findAll(userId: bigint, filters?: Query[Module]Dto) {
    return this.prisma.[model].findMany({
      where: {
        userId,
        ...filters,
      },
      orderBy: { createdAt: 'desc' },
    });
  }

  // READ - Single
  async findOne(id: bigint, userId: bigint) {
    const record = await this.prisma.[model].findUnique({
      where: { id },
      include: {
        // Include relations
      }
    });

    if (!record) {
      throw new NotFoundException('[Module] not found');
    }

    // Verify ownership
    if (record.userId !== userId) {
      throw new BadRequestException('Access denied');
    }

    return record;
  }

  // UPDATE
  async update(id: bigint, userId: bigint, dto: Update[Module]Dto) {
    // Verify exists and ownership
    await this.findOne(id, userId);

    return this.prisma.[model].update({
      where: { id },
      data: dto,
    });
  }

  // DELETE
  async remove(id: bigint, userId: bigint) {
    // Verify exists and ownership
    await this.findOne(id, userId);

    await this.prisma.[model].delete({
      where: { id },
    });

    return { message: '[Module] deleted successfully' };
  }
}
```

**📌 Best Practices:**

- ✅ Luôn validate ownership (userId)
- ✅ Throw exceptions rõ ràng (`NotFoundException`, `BadRequestException`)
- ✅ Sử dụng transactions cho operations phức tạp
- ✅ Include relations khi cần thiết

---

### **Step 3: Tạo Controller**

**File:** `[module].controller.ts`

```typescript
import {
  Controller,
  Get,
  Post,
  Patch,
  Delete,
  Body,
  Param,
  Query,
  UseGuards,
  HttpCode,
  HttpStatus
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth, ApiResponse } from '@nestjs/swagger';
import { [Module]Service } from './[module].service';
import { Create[Module]Dto, Update[Module]Dto, Query[Module]Dto } from './dto/[module].dto';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { RolesGuard } from '../../common/guards/roles.guard';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { Roles } from '../../common/decorators/roles.decorator';

@ApiTags('[Module]')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('[module-route]')
export class [Module]Controller {
  constructor(private [module]Service: [Module]Service) {}

  @Post()
  @ApiOperation({ summary: 'Create new [module]' })
  @ApiResponse({ status: 201, description: '[Module] created successfully' })
  async create(
    @CurrentUser() user: any,
    @Body() dto: Create[Module]Dto
  ) {
    return this.[module]Service.create(BigInt(user.userId), dto);
  }

  @Get()
  @ApiOperation({ summary: 'List all [module]s' })
  async findAll(
    @CurrentUser() user: any,
    @Query() query: Query[Module]Dto
  ) {
    return this.[module]Service.findAll(BigInt(user.userId), query);
  }

  @Get(':id')
  @ApiOperation({ summary: 'Get [module] by ID' })
  async findOne(
    @CurrentUser() user: any,
    @Param('id') id: string
  ) {
    return this.[module]Service.findOne(BigInt(id), BigInt(user.userId));
  }

  @Patch(':id')
  @ApiOperation({ summary: 'Update [module]' })
  async update(
    @CurrentUser() user: any,
    @Param('id') id: string,
    @Body() dto: Update[Module]Dto
  ) {
    return this.[module]Service.update(BigInt(id), BigInt(user.userId), dto);
  }

  @Delete(':id')
  @HttpCode(HttpStatus.NO_CONTENT)
  @ApiOperation({ summary: 'Delete [module]' })
  async remove(
    @CurrentUser() user: any,
    @Param('id') id: string
  ) {
    return this.[module]Service.remove(BigInt(id), BigInt(user.userId));
  }

  // Admin-only endpoint example
  @Get('admin/all')
  @UseGuards(RolesGuard)
  @Roles('admin')
  @ApiOperation({ summary: 'Admin: List all [module]s' })
  async adminFindAll() {
    // Admin logic
  }
}
```

**📌 Lưu ý:**

- ✅ Luôn có `@ApiTags` và `@ApiOperation`
- ✅ Dùng `@ApiBearerAuth()` cho protected routes
- ✅ Dùng `@CurrentUser()` để lấy user info
- ✅ Convert string params sang BigInt: `BigInt(id)`
- ✅ Dùng `@Roles()` cho admin endpoints

---

### **Step 4: Tạo Module**

**File:** `[module].module.ts`

```typescript
import { Module } from '@nestjs/common';
import { [Module]Service } from './[module].service';
import { [Module]Controller } from './[module].controller';
import { PrismaModule } from '../../prisma/prisma.module';

@Module({
  imports: [PrismaModule],
  controllers: [[Module]Controller],
  providers: [[Module]Service],
  exports: [[Module]Service], // Export nếu module khác cần dùng
})
export class [Module]Module {}
```

---

### **Step 5: Register trong AppModule**

**File:** `src/app.module.ts`

```typescript
import { [Module]Module } from './modules/[module]/[module].module';

@Module({
  imports: [
    // ... other modules
    [Module]Module,
  ],
})
export class AppModule {}
```

---

## 🎯 Patterns & Best Practices

### **1. Authentication Pattern**

```typescript
// Protected route - Chỉ user đã login
@UseGuards(JwtAuthGuard)
@Get('me/bookings')
async myBookings(@CurrentUser() user: any) {
  return this.service.findByUser(BigInt(user.userId));
}
```

### **2. Authorization Pattern (RBAC)**

```typescript
// Admin-only route
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles('admin', 'moderator')
@Get('admin/stats')
async getStats() {
  return this.service.getStatistics();
}
```

### **3. Validation Pattern**

```typescript
// DTO tự động validate nhờ ValidationPipe global
export class CreateBookingDto {
  @IsNotEmpty()
  @IsNumber()
  serviceId: number;

  @IsOptional()
  @IsDateString()
  scheduledAt?: string;
}
```

### **4. Error Handling Pattern**

```typescript
// Service
async findOne(id: bigint) {
  const item = await this.prisma.item.findUnique({ where: { id } });

  if (!item) {
    throw new NotFoundException('Item not found');
  }

  return item;
}

// Tự động được GlobalExceptionFilter format thành:
// {
//   "statusCode": 404,
//   "timestamp": "2025-11-20T...",
//   "path": "/items/123",
//   "message": "Item not found"
// }
```

### **5. Transaction Pattern**

```typescript
async createWithRelations(dto: CreateDto) {
  return this.prisma.$transaction(async (tx) => {
    const parent = await tx.parent.create({ data: dto.parent });

    const child = await tx.child.create({
      data: {
        parentId: parent.id,
        ...dto.child
      }
    });

    return { parent, child };
  });
}
```

### **6. Pagination Pattern**

```typescript
// DTO
export class PaginationDto {
  @ApiPropertyOptional({ default: 1 })
  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  page?: number = 1;

  @ApiPropertyOptional({ default: 10 })
  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  limit?: number = 10;
}

// Service
async findAll(query: PaginationDto) {
  const skip = (query.page - 1) * query.limit;

  const [items, total] = await Promise.all([
    this.prisma.item.findMany({
      skip,
      take: query.limit,
    }),
    this.prisma.item.count(),
  ]);

  return {
    items,
    meta: {
      total,
      page: query.page,
      limit: query.limit,
      totalPages: Math.ceil(total / query.limit),
    }
  };
}
```

---

## 📚 Examples

### **Example 1: Simple CRUD Module (Services)**

```typescript
// dto/service.dto.ts
export class CreateServiceDto {
  @ApiProperty()
  @IsNotEmpty()
  name: string;

  @ApiProperty()
  @IsNotEmpty()
  @IsNumber()
  categoryId: number;

  @ApiProperty()
  @IsNotEmpty()
  @IsNumber()
  price: number;
}

// services.service.ts
@Injectable()
export class ServicesService {
  constructor(private prisma: PrismaService) {}

  async create(dto: CreateServiceDto) {
    return this.prisma.service.create({ data: dto });
  }

  async findAll() {
    return this.prisma.service.findMany({
      include: { category: true },
    });
  }
}

// services.controller.ts
@ApiTags('Services')
@Controller('services')
export class ServicesController {
  constructor(private servicesService: ServicesService) {}

  @Post()
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('admin')
  async create(@Body() dto: CreateServiceDto) {
    return this.servicesService.create(dto);
  }

  @Get()
  async findAll() {
    return this.servicesService.findAll();
  }
}
```

### **Example 2: Module with Relations (Bookings)**

```typescript
// bookings.service.ts
async create(customerId: bigint, dto: CreateBookingDto) {
  // Verify service exists
  const service = await this.prisma.service.findUnique({
    where: { id: dto.serviceId }
  });

  if (!service) {
    throw new NotFoundException('Service not found');
  }

  // Create booking with relations
  return this.prisma.booking.create({
    data: {
      customerId,
      providerId: dto.providerId,
      serviceId: dto.serviceId,
      status: BookingStatus.pending,
      totalAmount: service.price,
    },
    include: {
      service: true,
      provider: { include: { profile: true } },
      customer: { include: { profile: true } },
    }
  });
}
```

---

## ✅ Checklist

Trước khi tạo Pull Request, đảm bảo:

### **Code Quality**

- [ ] DTOs có đầy đủ validation decorators
- [ ] Service có error handling đúng
- [ ] Controller có đầy đủ Swagger decorators
- [ ] Module được register trong AppModule

### **Security**

- [ ] Protected routes có `@UseGuards(JwtAuthGuard)`
- [ ] Admin routes có `@Roles('admin')`
- [ ] Verify ownership trong service methods
- [ ] Không expose sensitive data (passwordHash, etc.)

### **Testing**

- [ ] Build thành công: `npm run build`
- [ ] Dev server chạy: `npm run start:dev`
- [ ] Test endpoints qua Swagger: `http://localhost:3000/api`
- [ ] Test với Postman/Thunder Client

### **Documentation**

- [ ] Swagger docs đầy đủ (`@ApiOperation`, `@ApiProperty`)
- [ ] Code có comments cho logic phức tạp
- [ ] Update README nếu cần

---

## 🆘 Common Issues & Solutions

### **Issue 1: BigInt Serialization Error**

```typescript
// ❌ Sai
return { id: userId }; // BigInt không serialize được

// ✅ Đúng
return { id: userId.toString() };
```

### **Issue 2: Prisma Type Mismatch**

```typescript
// ❌ Sai
const id = req.params.id; // string
await this.prisma.booking.findUnique({ where: { id } });

// ✅ Đúng
const id = BigInt(req.params.id);
await this.prisma.booking.findUnique({ where: { id } });
```

### **Issue 3: Missing Validation**

```typescript
// ❌ Sai - Không validate
export class CreateDto {
  name: string;
}

// ✅ Đúng
export class CreateDto {
  @IsNotEmpty()
  @IsString()
  name: string;
}
```

---

## 📞 Need Help?

- Tham khảo modules đã implement: `Auth`, `Users`
- Xem [endpoints.md](../../../.gemini/antigravity/brain/.../endpoints.md) để biết API specs
- Hỏi trong team chat
- Review code của nhau qua PR

---

**Happy Coding! 🚀**

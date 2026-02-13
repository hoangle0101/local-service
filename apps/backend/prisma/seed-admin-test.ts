/**
 * Enhanced Seed Data for Admin UI Testing
 * 
 * This script creates comprehensive test data to test all admin functionality:
 * - Users with various statuses (active, banned, verified, unverified)
 * - Providers with various verification statuses (pending, verified, rejected)
 * - Bookings with all status types
 * - Disputes with various statuses
 * - Withdrawal requests with various statuses
 * - Payments with various statuses
 * - Reviews
 * 
 * Run with: npx ts-node prisma/seed-admin-test.ts
 */

import { PrismaClient } from '@prisma/client';
import * as bcrypt from 'bcrypt';

const prisma = new PrismaClient();

async function main() {
    console.log('🌱 Starting Admin Test Seed...\n');

    // Clear existing data
    console.log('🗑️  Clearing database...');
    await prisma.walletTransaction.deleteMany();
    await prisma.payment.deleteMany();
    await prisma.review.deleteMany();
    await prisma.dispute.deleteMany();
    await prisma.bookingEvent.deleteMany();
    await prisma.booking.deleteMany();
    await prisma.providerService.deleteMany();
    await prisma.service.deleteMany();
    await prisma.serviceCategory.deleteMany();
    await prisma.providerProfile.deleteMany();
    await prisma.wallet.deleteMany();
    await prisma.userRole.deleteMany();
    await prisma.userProfile.deleteMany();
    await prisma.session.deleteMany();
    await prisma.user.deleteMany();
    console.log('✅ Database cleared!\n');

    // ============================================
    // STEP 1: Create Roles
    // ============================================
    console.log('👥 Creating roles...');

    const customerRole = await prisma.role.upsert({
        where: { name: 'customer' },
        update: {},
        create: { name: 'customer', description: 'Regular customer' },
    });

    const providerRole = await prisma.role.upsert({
        where: { name: 'provider' },
        update: {},
        create: { name: 'provider', description: 'Service provider' },
    });

    const adminRole = await prisma.role.upsert({
        where: { name: 'admin' },
        update: {},
        create: { name: 'admin', description: 'Platform administrator' },
    });

    console.log('✅ Roles created!\n');

    // ============================================
    // STEP 2: Create Admin User
    // ============================================
    console.log('👨‍💼 Creating admin user...');

    const adminPassword = await bcrypt.hash('Admin@123', 10);
    const admin = await prisma.user.create({
        data: {
            phone: '0123456789',
            email: 'admin@localservice.com',
            passwordHash: adminPassword,
            status: 'active',
            isVerified: true,
            profile: {
                create: { fullName: 'Admin User', gender: 'male' },
            },
            userRoles: {
                create: { roleId: adminRole.id },
            },
        },
    });
    console.log(`✅ Admin created: ${admin.phone}\n`);

    // ============================================
    // STEP 3: Create Service Categories & Services
    // ============================================
    console.log('📂 Creating categories & services...');

    const categories = await Promise.all([
        prisma.serviceCategory.create({
            data: { code: 'cleaning', name: 'Dọn dẹp nhà cửa', slug: 'cleaning', description: 'Dịch vụ vệ sinh, dọn dẹp' },
        }),
        prisma.serviceCategory.create({
            data: { code: 'plumbing', name: 'Sửa chữa đường ống', slug: 'plumbing', description: 'Sửa ống nước, bồn cầu' },
        }),
        prisma.serviceCategory.create({
            data: { code: 'electrical', name: 'Điện - Điện tử', slug: 'electrical', description: 'Sửa điện, lắp đặt thiết bị' },
        }),
        prisma.serviceCategory.create({
            data: { code: 'beauty', name: 'Làm đẹp', slug: 'beauty', description: 'Cắt tóc, massage, spa' },
        }),
        prisma.serviceCategory.create({
            data: { code: 'tutoring', name: 'Gia sư', slug: 'tutoring', description: 'Dạy kèm các môn học' },
        }),
    ]);

    const services = await Promise.all([
        // Cleaning
        prisma.service.create({
            data: { categoryId: categories[0].id, name: 'Dọn dẹp nhà', basePrice: 200000, durationMinutes: 120 },
        }),
        prisma.service.create({
            data: { categoryId: categories[0].id, name: 'Giặt thảm', basePrice: 300000, durationMinutes: 60 },
        }),
        prisma.service.create({
            data: { categoryId: categories[0].id, name: 'Lau kính', basePrice: 150000, durationMinutes: 90 },
        }),
        // Plumbing
        prisma.service.create({
            data: { categoryId: categories[1].id, name: 'Thông bồn cầu', basePrice: 250000, durationMinutes: 60 },
        }),
        prisma.service.create({
            data: { categoryId: categories[1].id, name: 'Sửa ống nước', basePrice: 350000, durationMinutes: 90 },
        }),
        // Electrical
        prisma.service.create({
            data: { categoryId: categories[2].id, name: 'Sửa điều hòa', basePrice: 400000, durationMinutes: 120 },
        }),
        prisma.service.create({
            data: { categoryId: categories[2].id, name: 'Lắp đèn', basePrice: 150000, durationMinutes: 45 },
        }),
        // Beauty
        prisma.service.create({
            data: { categoryId: categories[3].id, name: 'Cắt tóc nam', basePrice: 100000, durationMinutes: 30 },
        }),
        prisma.service.create({
            data: { categoryId: categories[3].id, name: 'Massage toàn thân', basePrice: 500000, durationMinutes: 90 },
        }),
        // Tutoring
        prisma.service.create({
            data: { categoryId: categories[4].id, name: 'Gia sư Toán', basePrice: 200000, durationMinutes: 90 },
        }),
        prisma.service.create({
            data: { categoryId: categories[4].id, name: 'Gia sư Tiếng Anh', basePrice: 250000, durationMinutes: 90 },
        }),
        prisma.service.create({
            data: { categoryId: categories[4].id, name: 'Gia sư Lý', basePrice: 220000, durationMinutes: 90 },
        }),
    ]);

    console.log(`✅ Created ${categories.length} categories and ${services.length} services!\n`);

    // ============================================
    // STEP 4: Create Customers (30 users)
    // ============================================
    console.log('🙎 Creating 30 customers...');

    const testPassword = await bcrypt.hash('Test@123', 10);
    const customers: any[] = [];

    for (let i = 1; i <= 30; i++) {
        // Vary statuses: 24 active, 3 banned, 3 inactive
        let status: 'active' | 'inactive' | 'banned' = 'active';
        if (i >= 25 && i <= 27) status = 'banned';
        if (i >= 28) status = 'inactive';

        // Vary verification: 20 verified, 10 unverified
        const isVerified = i <= 20;

        const customer = await prisma.user.create({
            data: {
                phone: `0900${String(i).padStart(6, '0')}`,
                email: `customer${i}@test.com`,
                passwordHash: testPassword,
                status,
                isVerified,
                profile: {
                    create: {
                        fullName: `Customer ${i}`,
                        gender: i % 2 === 0 ? 'male' : 'female',
                    },
                },
                userRoles: {
                    create: { roleId: customerRole.id },
                },
                wallet: {
                    create: { balance: 1000000 + (i * 50000), currency: 'VND' },
                },
            },
        });
        customers.push(customer);
    }

    console.log(`✅ Created 30 customers (24 active, 3 banned, 3 inactive | 20 verified, 10 unverified)\n`);

    // ============================================
    // STEP 5: Create Providers (15 providers)
    // ============================================
    console.log('👷 Creating 15 providers...');

    const providers: any[] = [];
    const verificationStatuses: ('verified' | 'pending' | 'unverified' | 'rejected')[] = [
        'verified', 'verified', 'verified', 'verified', 'verified', // 5 verified
        'verified', 'verified', // 2 more verified
        'pending', 'pending', 'pending', 'pending', 'pending', // 5 pending
        'rejected', 'rejected', 'rejected', // 3 rejected
    ];

    for (let i = 1; i <= 15; i++) {
        const verificationStatus = verificationStatuses[i - 1];

        // 2 providers banned, 1 inactive
        let status: 'active' | 'inactive' | 'banned' = 'active';
        if (i === 14) status = 'banned';
        if (i === 15) status = 'inactive';

        const provider = await prisma.user.create({
            data: {
                phone: `0910${String(i).padStart(6, '0')}`,
                email: `provider${i}@test.com`,
                passwordHash: testPassword,
                status,
                isVerified: true,
                profile: {
                    create: {
                        fullName: `Provider Owner ${i}`,
                        gender: i % 2 === 0 ? 'male' : 'female',
                    },
                },
                userRoles: {
                    create: { roleId: providerRole.id },
                },
                providerProfile: {
                    create: {
                        displayName: `Dịch vụ ${i} - ${categories[i % categories.length].name}`,
                        bio: `Chuyên cung cấp dịch vụ ${categories[i % categories.length].name}. Kinh nghiệm ${5 + i} năm.`,
                        ratingAvg: 3.5 + (i % 20) * 0.1,
                        ratingCount: 10 + (i * 3),
                        isAvailable: status === 'active' && verificationStatus === 'verified',
                        verificationStatus,
                        address: `${i * 10} Nguyễn Văn Cừ, Quận ${i % 12 + 1}, TP.HCM`,
                        latitude: 10.7769 + (i * 0.005),
                        longitude: 106.7009 + (i * 0.003),
                    },
                },
                wallet: {
                    create: { balance: 5000000 + (i * 100000), currency: 'VND' },
                },
            },
        });
        providers.push(provider);
    }

    console.log(`✅ Created 15 providers (7 verified, 5 pending, 3 rejected | 13 active, 1 banned, 1 inactive)\n`);

    // ============================================
    // STEP 6: Link Providers to Services
    // ============================================
    console.log('🔗 Linking providers to services...');

    for (const provider of providers) {
        // Each provider offers 3-4 random services
        const numServices = 3 + (providers.indexOf(provider) % 2);
        const selectedServices = services
            .sort(() => Math.random() - 0.5)
            .slice(0, numServices);

        for (const service of selectedServices) {
            await prisma.providerService.create({
                data: {
                    providerUserId: provider.id,
                    serviceId: service.id,
                    price: Number(service.basePrice) * (0.8 + Math.random() * 0.4), // 80%-120% of base price
                    currency: 'VND',
                    isActive: true,
                },
            });
        }
    }

    console.log(`✅ Provider services linked!\n`);

    // ============================================
    // STEP 7: Create Bookings (100 bookings)
    // ============================================
    console.log('📅 Creating 100 bookings...');

    const bookingStatuses: ('pending' | 'accepted' | 'in_progress' | 'completed' | 'cancelled' | 'disputed')[] = [
        'pending', 'pending', 'pending', // 15% pending
        'accepted', 'accepted', // 10% accepted
        'in_progress', // 5% in_progress
        'completed', 'completed', 'completed', 'completed', // 40% completed
        'completed', 'completed', 'completed', 'completed',
        'cancelled', 'cancelled', // 10% cancelled
        'disputed', 'disputed', // 10% disputed (for testing dispute resolution)
    ];

    const bookings: any[] = [];

    for (let i = 0; i < 100; i++) {
        const customer = customers[i % customers.length];
        const provider = providers[i % providers.length];
        const service = services[i % services.length];
        const status = bookingStatuses[i % bookingStatuses.length];

        const actualPrice = status === 'completed' || status === 'disputed' ? Number(service.basePrice) : null;
        const platformFee = actualPrice ? actualPrice * 0.1 : 0;
        const providerEarning = actualPrice ? actualPrice * 0.9 : 0;

        const scheduledDate = new Date();
        scheduledDate.setDate(scheduledDate.getDate() - (i % 30) + 5);

        const lat = 10.7769 + (Math.random() * 0.1);
        const lng = 106.7009 + (Math.random() * 0.1);

        const completedAt = status === 'completed' ? new Date(scheduledDate.getTime() + 2 * 60 * 60 * 1000) : null;
        const cancelledAt = status === 'cancelled' ? new Date() : null;

        await prisma.$executeRawUnsafe(`
      INSERT INTO bookings (
        code, customer_id, provider_id, service_id, status,
        scheduled_at, address_text, location,
        estimated_price, actual_price, platform_fee, provider_earning,
        completed_at, cancelled_at, created_at, updated_at
      ) VALUES (
        'BK${Date.now()}-${i}',
        ${customer.id},
        ${provider.id},
        ${service.id},
        '${status}',
        '${scheduledDate.toISOString()}',
        '${i + 1} Duong Test, Phuong ${(i % 15) + 1}, Quan ${(i % 12) + 1}, TP.HCM',
        ST_SetSRID(ST_MakePoint(${lng}, ${lat}), 4326),
        ${Number(service.basePrice)},
        ${actualPrice || 'NULL'},
        ${platformFee},
        ${providerEarning},
        ${completedAt ? `'${completedAt.toISOString()}'` : 'NULL'},
        ${cancelledAt ? `'${cancelledAt.toISOString()}'` : 'NULL'},
        NOW(),
        NOW()
      )
    `);

        if ((i + 1) % 25 === 0) console.log(`  Created ${i + 1}/100 bookings...`);
    }

    // Get all booking IDs
    const allBookings = await prisma.booking.findMany({
        orderBy: { createdAt: 'desc' },
        take: 100,
    });

    console.log(`✅ Created 100 bookings!\n`);

    // ============================================
    // STEP 8: Create Disputes (10 disputes)
    // ============================================
    console.log('⚠️ Creating 10 disputes...');

    const disputedBookings = allBookings.filter(b => b.status === 'disputed').slice(0, 10);
    const disputes: any[] = [];
    const disputeStatuses: ('open' | 'under_review' | 'resolved' | 'closed')[] = [
        'open', 'open', 'open', 'open', // 4 open
        'under_review', 'under_review', // 2 under_review
        'resolved', 'resolved', 'resolved', // 3 resolved
        'closed', // 1 closed
    ];

    const disputeReasons = [
        'Nhà cung cấp không đến đúng giờ',
        'Chất lượng dịch vụ không đạt yêu cầu',
        'Giá thu thực tế khác với giá đã thỏa thuận',
        'Nhà cung cấp hủy đơn phút cuối',
        'Hư hỏng tài sản trong quá trình thực hiện',
        'Thái độ phục vụ không chuyên nghiệp',
        'Dịch vụ chưa hoàn thành',
        'Không liên lạc được với nhà cung cấp',
        'Yêu cầu hoàn tiền',
        'Khác - cần xem xét',
    ];

    for (let i = 0; i < Math.min(10, disputedBookings.length); i++) {
        const booking = disputedBookings[i];
        const status = disputeStatuses[i];
        const resolvedAt = status === 'resolved' || status === 'closed' ? new Date() : null;

        const dispute = await prisma.dispute.create({
            data: {
                bookingId: booking.id,
                raisedBy: booking.customerId,
                reason: disputeReasons[i],
                status,
                resolution: resolvedAt ? 'Đã xử lý tranh chấp theo quy định' : null,
                resolvedByAdminId: resolvedAt ? admin.id : null,
                resolvedAt,
            },
        });
        disputes.push(dispute);
    }

    console.log(`✅ Created ${disputes.length} disputes (4 open, 2 under_review, 3 resolved, 1 closed)!\n`);

    // ============================================
    // STEP 9: Create Payments (20 payments)
    // ============================================
    console.log('💳 Creating 20 payments...');

    const completedBookings = allBookings.filter(b => b.status === 'completed');
    const paymentStatuses: ('initiated' | 'succeeded' | 'failed')[] = [
        'succeeded', 'succeeded', 'succeeded', 'succeeded', 'succeeded', // 50% succeeded
        'succeeded', 'succeeded', 'succeeded', 'succeeded', 'succeeded',
        'initiated', 'initiated', 'initiated', 'initiated', // 20% initiated
        'failed', 'failed', 'failed', 'failed', 'failed', 'failed', // 30% failed
    ];
    const paymentMethods: ('card' | 'momo' | 'bank_transfer' | 'wallet')[] = ['card', 'momo', 'bank_transfer', 'wallet'];

    const payments: any[] = [];

    for (let i = 0; i < 20; i++) {
        const booking = completedBookings[i % completedBookings.length];
        const status = paymentStatuses[i];
        const method = paymentMethods[i % paymentMethods.length];

        const payment = await prisma.payment.create({
            data: {
                bookingId: booking.id,
                amount: booking.actualPrice || 200000,
                currency: 'VND',
                method,
                gateway: method === 'momo' ? 'momo' : method === 'card' ? 'vnpay' : 'manual',
                gatewayTxId: `TXN${Date.now()}-${i}`,
                status,
                payload: { testPayment: true, orderId: i + 1 },
            },
        });
        payments.push(payment);
    }

    console.log(`✅ Created 20 payments (10 succeeded, 4 initiated, 6 failed)!\n`);

    // ============================================
    // STEP 10: Create Withdrawal Requests (10)
    // ============================================
    console.log('💰 Creating 10 withdrawal requests...');

    for (let i = 0; i < 10; i++) {
        const provider = providers[i % providers.length];

        // Vary statuses: 5 pending, 3 completed, 2 failed
        let status: 'pending' | 'completed' | 'failed' = 'pending';
        if (i >= 5 && i <= 7) status = 'completed';
        if (i >= 8) status = 'failed';

        const amount = (i + 1) * 500000;

        await prisma.walletTransaction.create({
            data: {
                walletUserId: provider.id,
                type: 'withdrawal',
                amount: -amount,
                balanceAfter: 5000000 - amount,
                status,
                metadata: {
                    withdrawalRequest: true,
                    bankName: ['Vietcombank', 'Techcombank', 'BIDV', 'ACB', 'MB Bank'][i % 5],
                    bankAccount: `${1000000000 + i * 11111}`,
                    accountHolder: `Provider Owner ${i + 1}`,
                },
            },
        });
    }

    console.log(`✅ Created 10 withdrawal requests (5 pending, 3 completed, 2 failed)!\n`);

    // ============================================
    // STEP 11: Create Reviews (30 reviews)
    // ============================================
    console.log('⭐ Creating 30 reviews...');

    const completedBookingsForReviews = allBookings.filter(b => b.status === 'completed').slice(0, 30);

    for (let i = 0; i < Math.min(30, completedBookingsForReviews.length); i++) {
        const booking = completedBookingsForReviews[i];
        const rating = 3 + (i % 3); // Ratings: 3, 4, 5

        await prisma.review.create({
            data: {
                bookingId: booking.id,
                reviewerId: booking.customerId,
                revieweeId: booking.providerId!,
                rating,
                title: rating >= 4 ? 'Dịch vụ tốt' : 'Tạm được',
                comment: rating >= 4
                    ? 'Nhà cung cấp làm việc chuyên nghiệp, đúng giờ. Rất hài lòng!'
                    : 'Dịch vụ ổn, cần cải thiện một chút về thời gian.',
            },
        });
    }

    console.log(`✅ Created 30 reviews!\n`);

    // ============================================
    // SUMMARY
    // ============================================
    console.log('═══════════════════════════════════════════════════════════════════');
    console.log('📊 SEED COMPLETED - DATA SUMMARY');
    console.log('═══════════════════════════════════════════════════════════════════');
    console.log('');
    console.log('👨‍💼 ADMIN ACCOUNT:');
    console.log('   Phone: 0123456789');
    console.log('   Password: Admin@123');
    console.log('');
    console.log('🙎 CUSTOMERS (30 total):');
    console.log('   - Active: 24 (phones: 0900000001 - 0900000024)');
    console.log('   - Banned: 3 (phones: 0900000025 - 0900000027)');
    console.log('   - Inactive: 3 (phones: 0900000028 - 0900000030)');
    console.log('   - Verified: 20 | Unverified: 10');
    console.log('   - Password: Test@123');
    console.log('');
    console.log('👷 PROVIDERS (15 total):');
    console.log('   - Verified: 7 (phones: 0910000001 - 0910000007)');
    console.log('   - Pending: 5 (phones: 0910000008 - 0910000012)');
    console.log('   - Rejected: 3 (phones: 0910000013 - 0910000015)');
    console.log('   - Active: 13 | Banned: 1 | Inactive: 1');
    console.log('   - Password: Test@123');
    console.log('');
    console.log('📂 SERVICES: 12 services in 5 categories');
    console.log('📅 BOOKINGS: 100 (15 pending, 10 accepted, 5 in_progress, 50 completed, 10 cancelled, 10 disputed)');
    console.log('⚠️  DISPUTES: 10 (4 open, 2 under_review, 3 resolved, 1 closed)');
    console.log('💳 PAYMENTS: 20 (10 succeeded, 4 initiated, 6 failed)');
    console.log('💰 WITHDRAWALS: 10 (5 pending, 3 completed, 2 failed)');
    console.log('⭐ REVIEWS: 30');
    console.log('');
    console.log('═══════════════════════════════════════════════════════════════════');
    console.log('');
    console.log('🚀 Ready for testing! Access admin at http://localhost:3001');
    console.log('');
}

main()
    .catch((e) => {
        console.error('❌ Seed failed:', e);
        process.exit(1);
    })
    .finally(async () => {
        await prisma.$disconnect();
    });

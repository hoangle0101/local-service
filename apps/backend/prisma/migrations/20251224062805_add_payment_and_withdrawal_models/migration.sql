-- CreateEnum
CREATE TYPE "QuoteStatus" AS ENUM ('pending', 'accepted', 'rejected', 'expired');

-- CreateEnum
CREATE TYPE "WithdrawalStatus" AS ENUM ('pending', 'processing', 'completed', 'failed', 'cancelled');

-- CreateEnum
CREATE TYPE "BookingPaymentStatus" AS ENUM ('pending', 'held', 'released', 'refunded', 'disputed');

-- AlterEnum
ALTER TYPE "BookingStatus" ADD VALUE 'pending_payment';

-- AlterEnum
ALTER TYPE "PaymentMethod" ADD VALUE 'cod';

-- AlterTable
ALTER TABLE "bookings" ADD COLUMN     "additional_costs" DECIMAL(12,2),
ADD COLUMN     "additional_notes" TEXT,
ADD COLUMN     "paid_at" TIMESTAMPTZ(6),
ADD COLUMN     "payment_method" "PaymentMethod",
ADD COLUMN     "payment_status" VARCHAR(20) NOT NULL DEFAULT 'unpaid';

-- CreateTable
CREATE TABLE "service_quotes" (
    "id" BIGSERIAL NOT NULL,
    "booking_id" BIGINT NOT NULL,
    "provider_id" BIGINT NOT NULL,
    "diagnosis" TEXT NOT NULL,
    "items" JSONB NOT NULL,
    "labor_cost" DECIMAL(18,2) NOT NULL,
    "parts_cost" DECIMAL(18,2) NOT NULL,
    "total_cost" DECIMAL(18,2) NOT NULL,
    "platform_fee" DECIMAL(18,2) NOT NULL,
    "final_price" DECIMAL(18,2) NOT NULL,
    "warranty" VARCHAR(100),
    "estimated_time" INTEGER,
    "images" VARCHAR(500)[],
    "notes" TEXT,
    "status" "QuoteStatus" NOT NULL DEFAULT 'pending',
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "expires_at" TIMESTAMPTZ(6) NOT NULL,
    "accepted_at" TIMESTAMPTZ(6),

    CONSTRAINT "service_quotes_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "booking_payments" (
    "id" BIGSERIAL NOT NULL,
    "booking_id" BIGINT NOT NULL,
    "customer_id" BIGINT NOT NULL,
    "provider_id" BIGINT NOT NULL,
    "amount" DECIMAL(18,2) NOT NULL,
    "platform_fee" DECIMAL(18,2) NOT NULL,
    "provider_amount" DECIMAL(18,2) NOT NULL,
    "payment_method" VARCHAR(20) NOT NULL,
    "momo_trans_id" VARCHAR(100),
    "status" "BookingPaymentStatus" NOT NULL DEFAULT 'pending',
    "paid_at" TIMESTAMPTZ(6),
    "held_at" TIMESTAMPTZ(6),
    "released_at" TIMESTAMPTZ(6),
    "refunded_at" TIMESTAMPTZ(6),
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL,

    CONSTRAINT "booking_payments_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "withdrawals" (
    "id" BIGSERIAL NOT NULL,
    "provider_id" BIGINT NOT NULL,
    "amount" DECIMAL(18,2) NOT NULL,
    "fee" DECIMAL(18,2) NOT NULL DEFAULT 0,
    "net_amount" DECIMAL(18,2) NOT NULL,
    "method" VARCHAR(20) NOT NULL,
    "bank_name" VARCHAR(100),
    "bank_account" VARCHAR(50),
    "bank_holder" VARCHAR(100),
    "momo_phone" VARCHAR(20),
    "status" "WithdrawalStatus" NOT NULL DEFAULT 'pending',
    "note" TEXT,
    "admin_note" TEXT,
    "processed_by" BIGINT,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "processed_at" TIMESTAMPTZ(6),

    CONSTRAINT "withdrawals_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "minimum_prices" (
    "id" BIGSERIAL NOT NULL,
    "category_code" VARCHAR(50) NOT NULL,
    "category_name" VARCHAR(100) NOT NULL,
    "min_price" DECIMAL(18,2) NOT NULL,
    "description" TEXT,
    "is_active" BOOLEAN NOT NULL DEFAULT true,
    "updated_at" TIMESTAMPTZ(6) NOT NULL,

    CONSTRAINT "minimum_prices_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "service_quotes_booking_id_idx" ON "service_quotes"("booking_id");

-- CreateIndex
CREATE INDEX "service_quotes_provider_id_idx" ON "service_quotes"("provider_id");

-- CreateIndex
CREATE INDEX "service_quotes_status_idx" ON "service_quotes"("status");

-- CreateIndex
CREATE UNIQUE INDEX "booking_payments_booking_id_key" ON "booking_payments"("booking_id");

-- CreateIndex
CREATE INDEX "booking_payments_customer_id_idx" ON "booking_payments"("customer_id");

-- CreateIndex
CREATE INDEX "booking_payments_provider_id_idx" ON "booking_payments"("provider_id");

-- CreateIndex
CREATE INDEX "booking_payments_status_idx" ON "booking_payments"("status");

-- CreateIndex
CREATE INDEX "withdrawals_provider_id_idx" ON "withdrawals"("provider_id");

-- CreateIndex
CREATE INDEX "withdrawals_status_idx" ON "withdrawals"("status");

-- CreateIndex
CREATE UNIQUE INDEX "minimum_prices_category_code_key" ON "minimum_prices"("category_code");

-- AddForeignKey
ALTER TABLE "service_quotes" ADD CONSTRAINT "service_quotes_booking_id_fkey" FOREIGN KEY ("booking_id") REFERENCES "bookings"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "service_quotes" ADD CONSTRAINT "service_quotes_provider_id_fkey" FOREIGN KEY ("provider_id") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "booking_payments" ADD CONSTRAINT "booking_payments_booking_id_fkey" FOREIGN KEY ("booking_id") REFERENCES "bookings"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "booking_payments" ADD CONSTRAINT "booking_payments_customer_id_fkey" FOREIGN KEY ("customer_id") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "booking_payments" ADD CONSTRAINT "booking_payments_provider_id_fkey" FOREIGN KEY ("provider_id") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "withdrawals" ADD CONSTRAINT "withdrawals_provider_id_fkey" FOREIGN KEY ("provider_id") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "withdrawals" ADD CONSTRAINT "withdrawals_processed_by_fkey" FOREIGN KEY ("processed_by") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;

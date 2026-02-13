-- AlterEnum
ALTER TYPE "BookingStatus" ADD VALUE 'pending_completion';

-- AlterTable
ALTER TABLE "provider_profiles" ADD COLUMN     "address" TEXT,
ADD COLUMN     "latitude" DOUBLE PRECISION,
ADD COLUMN     "longitude" DOUBLE PRECISION;

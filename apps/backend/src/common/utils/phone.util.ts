/**
 * Normalize Vietnamese phone number to standard format (09xxxxxxxx)
 * Converts +84 prefix to 0
 * 
 * Examples:
 * - +84987654321 -> 0987654321
 * - 84987654321 -> 0987654321
 * - 0987654321 -> 0987654321
 * - 098 765 4321 -> 0987654321
 */
export function normalizePhoneNumber(phone: string): string {
  if (!phone) return phone;

  // Remove all spaces, dashes, parentheses, and dots
  let normalized = phone.replace(/[\s\-().]/g, '');

  // Convert +84 to 0
  if (normalized.startsWith('+84')) {
    normalized = '0' + normalized.substring(3);
  }
  // Convert 84 to 0 (without +)
  else if (normalized.startsWith('84') && normalized.length >= 11) {
    normalized = '0' + normalized.substring(2);
  }

  return normalized;
}

/**
 * Validate Vietnamese phone number format
 * Valid formats: 09xxxxxxxx, 08xxxxxxxx, 07xxxxxxxx, 05xxxxxxxx, 03xxxxxxxx
 * Length: 10 digits
 */
export function isValidVietnamesePhone(phone: string): boolean {
  const normalized = normalizePhoneNumber(phone);
  
  // Must be exactly 10 digits
  if (!/^\d{10}$/.test(normalized)) {
    return false;
  }

  // Must start with valid Vietnamese mobile prefixes
  const validPrefixes = ['09', '08', '07', '05', '03'];
  return validPrefixes.some(prefix => normalized.startsWith(prefix));
}

/**
 * Format phone number for display
 * 0987654321 -> 098 765 4321
 */
export function formatPhoneNumber(phone: string): string {
  const normalized = normalizePhoneNumber(phone);
  
  if (normalized.length !== 10) {
    return normalized;
  }

  // Format as: 098 765 4321
  return `${normalized.substring(0, 3)} ${normalized.substring(3, 6)} ${normalized.substring(6)}`;
}

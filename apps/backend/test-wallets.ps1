# Test Script cho Wallets Module
# Chạy script này trong PowerShell

$baseUrl = "http://localhost:3000"

Write-Host "==================================" -ForegroundColor Cyan
Write-Host "WALLET MODULE TEST SCRIPT" -ForegroundColor Cyan
Write-Host "==================================" -ForegroundColor Cyan
Write-Host ""

# Step 1: Register user
Write-Host "STEP 1: Đăng ký user mới..." -ForegroundColor Yellow
$registerBody = @{
    phone = "0987654321"
    password = "Test@123"
    fullName = "Test User Wallet"
} | ConvertTo-Json

try {
    $registerResponse = Invoke-RestMethod -Uri "$baseUrl/auth/register" `
        -Method POST `
        -ContentType "application/json" `
        -Body $registerBody
    
    Write-Host "✓ Đăng ký thành công!" -ForegroundColor Green
    Write-Host "User ID: $($registerResponse.user.id)" -ForegroundColor Gray
} catch {
    Write-Host "User đã tồn tại, tiếp tục với login..." -ForegroundColor Yellow
}

# Step 2: Login to get token
Write-Host "`nSTEP 2: Đăng nhập để lấy token..." -ForegroundColor Yellow
$loginBody = @{
    phone = "0987654321"
    password = "Test@123"
} | ConvertTo-Json

$loginResponse = Invoke-RestMethod -Uri "$baseUrl/auth/login" `
    -Method POST `
    -ContentType "application/json" `
    -Body $loginBody

$token = $loginResponse.accessToken
Write-Host "✓ Login thành công!" -ForegroundColor Green
Write-Host "Token: $($token.Substring(0, 20))..." -ForegroundColor Gray

# Prepare headers
$headers = @{
    "Authorization" = "Bearer $token"
    "Content-Type" = "application/json"
}

Write-Host ""
Write-Host "==================================" -ForegroundColor Cyan
Write-Host "TEST WALLETS ENDPOINTS" -ForegroundColor Cyan
Write-Host "==================================" -ForegroundColor Cyan

# Test 1: Get Balance
Write-Host "`nTEST 1: GET /wallets/balance" -ForegroundColor Yellow
try {
    $balance = Invoke-RestMethod -Uri "$baseUrl/wallets/balance" `
        -Method GET `
        -Headers $headers
    
    Write-Host "✓ Lấy balance thành công!" -ForegroundColor Green
    Write-Host "Balance: $($balance.balance) $($balance.currency)" -ForegroundColor Green
    Write-Host "Total Transactions: $($balance.totalTransactions)" -ForegroundColor Gray
} catch {
    Write-Host "✗ Lỗi: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Response: $($_.ErrorDetails.Message)" -ForegroundColor Red
}

# Test 2: Get Transactions (should be empty)
Write-Host "`nTEST 2: GET /wallets/transactions" -ForegroundColor Yellow
try {
    $transactions = Invoke-RestMethod -Uri "$baseUrl/wallets/transactions?page=1&limit=10" `
        -Method GET `
        -Headers $headers
    
    Write-Host "✓ Lấy transactions thành công!" -ForegroundColor Green
    Write-Host "Total: $($transactions.pagination.total)" -ForegroundColor Gray
    if ($transactions.data.Count -gt 0) {
        Write-Host "Transactions:" -ForegroundColor Gray
        $transactions.data | ForEach-Object {
            Write-Host "  - $($_.type): $($_.amount) $($_.status)" -ForegroundColor Gray
        }
    } else {
        Write-Host "  (Chưa có giao dịch nào)" -ForegroundColor Gray
    }
} catch {
    Write-Host "✗ Lỗi: $($_.Exception.Message)" -ForegroundColor Red
}

# Test 3: Deposit
Write-Host "`nTEST 3: POST /wallets/deposit" -ForegroundColor Yellow
$depositBody = @{
    amount = 500000
    gateway = "momo"
} | ConvertTo-Json

try {
    $deposit = Invoke-RestMethod -Uri "$baseUrl/wallets/deposit" `
        -Method POST `
        -Headers $headers `
        -Body $depositBody
    
    Write-Host "✓ Deposit initiated thành công!" -ForegroundColor Green
    Write-Host "Transaction ID: $($deposit.transactionId)" -ForegroundColor Gray
    Write-Host "Payment ID: $($deposit.paymentId)" -ForegroundColor Gray
    Write-Host "Amount: $($deposit.amount) VND" -ForegroundColor Gray
    Write-Host "Status: $($deposit.status)" -ForegroundColor Gray
    Write-Host "Payment URL: $($deposit.paymentUrl)" -ForegroundColor Cyan
} catch {
    Write-Host "✗ Lỗi: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Response: $($_.ErrorDetails.Message)" -ForegroundColor Red
}

# Test 4: Withdraw (should fail - insufficient balance)
Write-Host "`nTEST 4: POST /wallets/withdraw (Small amount - auto approve)" -ForegroundColor Yellow
$withdrawBody = @{
    amount = 200000
    bankAccount = "1234567890"
    bankName = "Vietcombank"
} | ConvertTo-Json

try {
    $withdraw = Invoke-RestMethod -Uri "$baseUrl/wallets/withdraw" `
        -Method POST `
        -Headers $headers `
        -Body $withdrawBody
    
    Write-Host "✓ Withdraw thành công!" -ForegroundColor Green
    Write-Host "Transaction ID: $($withdraw.transactionId)" -ForegroundColor Gray
    Write-Host "Amount: $($withdraw.amount) VND" -ForegroundColor Gray
    Write-Host "Status: $($withdraw.status)" -ForegroundColor Gray
    Write-Host "Message: $($withdraw.message)" -ForegroundColor Cyan
} catch {
    $errorResponse = $_.ErrorDetails.Message | ConvertFrom-Json
    if ($errorResponse.message -like "*Insufficient balance*") {
        Write-Host "✓ Validation hoạt động đúng: $($errorResponse.message)" -ForegroundColor Yellow
    } else {
        Write-Host "✗ Lỗi: $($errorResponse.message)" -ForegroundColor Red
    }
}

# Test 5: Withdraw large amount (should require approval)
Write-Host "`nTEST 5: POST /wallets/withdraw (Large amount - need approval)" -ForegroundColor Yellow
$withdrawLargeBody = @{
    amount = 5000000
    bankAccount = "9876543210"
    bankName = "ACB"
} | ConvertTo-Json

try {
    $withdrawLarge = Invoke-RestMethod -Uri "$baseUrl/wallets/withdraw" `
        -Method POST `
        -Headers $headers `
        -Body $withdrawLargeBody
    
    Write-Host "✓ Withdraw request submitted!" -ForegroundColor Green
    Write-Host "Transaction ID: $($withdrawLarge.transactionId)" -ForegroundColor Gray
    Write-Host "Status: $($withdrawLarge.status)" -ForegroundColor Gray
    Write-Host "Message: $($withdrawLarge.message)" -ForegroundColor Cyan
    if ($withdrawLarge.note) {
        Write-Host "Note: $($withdrawLarge.note)" -ForegroundColor Yellow
    }
} catch {
    $errorResponse = $_.ErrorDetails.Message | ConvertFrom-Json
    Write-Host "Expected error: $($errorResponse.message)" -ForegroundColor Yellow
}

# Test 6: Invalid deposit amount
Write-Host "`nTEST 6: POST /wallets/deposit (Invalid amount - validation test)" -ForegroundColor Yellow
$invalidDepositBody = @{
    amount = 50000  # Less than minimum 100,000
    gateway = "momo"
} | ConvertTo-Json

try {
    $invalidDeposit = Invoke-RestMethod -Uri "$baseUrl/wallets/deposit" `
        -Method POST `
        -Headers $headers `
        -Body $invalidDepositBody
    
    Write-Host "✗ Validation không hoạt động!" -ForegroundColor Red
} catch {
    $errorResponse = $_.ErrorDetails.Message | ConvertFrom-Json
    Write-Host "✓ Validation hoạt động đúng!" -ForegroundColor Green
    Write-Host "Error: $($errorResponse.message)" -ForegroundColor Yellow
}

# Test 7: Invalid gateway
Write-Host "`nTEST 7: POST /wallets/deposit (Invalid gateway - validation test)" -ForegroundColor Yellow
$invalidGatewayBody = @{
    amount = 500000
    gateway = "paypal"  # Not in enum
} | ConvertTo-Json

try {
    $invalidGateway = Invoke-RestMethod -Uri "$baseUrl/wallets/deposit" `
        -Method POST `
        -Headers $headers `
        -Body $invalidGatewayBody
    
    Write-Host "✗ Validation không hoạt động!" -ForegroundColor Red
} catch {
    $errorResponse = $_.ErrorDetails.Message | ConvertFrom-Json
    Write-Host "✓ Validation hoạt động đúng!" -ForegroundColor Green
    Write-Host "Error: $($errorResponse.message)" -ForegroundColor Yellow
}

# Final: Check transactions again
Write-Host "`nFINAL: GET /wallets/transactions (After tests)" -ForegroundColor Yellow
try {
    $finalTransactions = Invoke-RestMethod -Uri "$baseUrl/wallets/transactions?page=1&limit=20" `
        -Method GET `
        -Headers $headers
    
    Write-Host "✓ Tổng số transactions: $($finalTransactions.pagination.total)" -ForegroundColor Green
    if ($finalTransactions.data.Count -gt 0) {
        Write-Host "`nDanh sách transactions:" -ForegroundColor Cyan
        $finalTransactions.data | ForEach-Object {
            Write-Host "  [$($_.createdAt)] $($_.type): $($_.amount) VND - Status: $($_.status)" -ForegroundColor Gray
        }
    }
} catch {
    Write-Host "✗ Lỗi: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Write-Host "==================================" -ForegroundColor Cyan
Write-Host "TEST COMPLETED" -ForegroundColor Cyan
Write-Host "==================================" -ForegroundColor Cyan

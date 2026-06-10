<#
===========================================================================
Project : NBExpenseManager
Author  : Salman Khan
Purpose : Create Flutter + Node.js + MongoDB Expense Manager Folder Structure
===========================================================================

This script creates:

1. Flutter Mobile Application Structure
2. Backend API Structure
3. Assets, Models, Services, Features
4. MongoDB Backend Architecture Folders

=========================================================================== 
#>

# ============================================================
# ROOT PROJECT FOLDER
# ============================================================

$RootFolder = "NBExpenseManager"

Write-Host "Creating Project Structure..." -ForegroundColor Green

New-Item -ItemType Directory -Path $RootFolder -Force | Out-Null

# ============================================================
# FLUTTER MOBILE APP
# ============================================================

Write-Host "Creating Flutter Structure..." -ForegroundColor Cyan

$FlutterFolders = @(

    "$RootFolder\mobile-app",

    # Core
    "$RootFolder\mobile-app\lib\core",
    "$RootFolder\mobile-app\lib\core\constants",
    "$RootFolder\mobile-app\lib\core\theme",
    "$RootFolder\mobile-app\lib\core\routes",
    "$RootFolder\mobile-app\lib\core\utils",

    # Config
    "$RootFolder\mobile-app\lib\config",

    # Models
    "$RootFolder\mobile-app\lib\models",

    # Services
    "$RootFolder\mobile-app\lib\services",

    # Features
    "$RootFolder\mobile-app\lib\features",
    "$RootFolder\mobile-app\lib\features\auth",
    "$RootFolder\mobile-app\lib\features\dashboard",
    "$RootFolder\mobile-app\lib\features\expenses",
    "$RootFolder\mobile-app\lib\features\reports",
    "$RootFolder\mobile-app\lib\features\reminders",
    "$RootFolder\mobile-app\lib\features\loans",
    "$RootFolder\mobile-app\lib\features\credit_cards",
    "$RootFolder\mobile-app\lib\features\debts",
    "$RootFolder\mobile-app\lib\features\savings",
    "$RootFolder\mobile-app\lib\features\settings",

    # Shared
    "$RootFolder\mobile-app\lib\shared",
    "$RootFolder\mobile-app\lib\shared\widgets",
    "$RootFolder\mobile-app\lib\shared\helpers",

    # Assets
    "$RootFolder\mobile-app\assets",
    "$RootFolder\mobile-app\assets\images",
    "$RootFolder\mobile-app\assets\icons",

    # Android
    "$RootFolder\mobile-app\android"
)

foreach ($Folder in $FlutterFolders)
{
    New-Item -ItemType Directory -Path $Folder -Force | Out-Null
}

# ============================================================
# FLUTTER FILES
# ============================================================

Write-Host "Creating Flutter Files..." -ForegroundColor Yellow

$FlutterFiles = @(

    "$RootFolder\mobile-app\lib\main.dart",
    "$RootFolder\mobile-app\lib\app.dart",

    "$RootFolder\mobile-app\lib\config\api_config.dart",
    "$RootFolder\mobile-app\lib\config\firebase_options.dart",

    "$RootFolder\mobile-app\lib\models\user_model.dart",
    "$RootFolder\mobile-app\lib\models\expense_model.dart",
    "$RootFolder\mobile-app\lib\models\loan_model.dart",
    "$RootFolder\mobile-app\lib\models\credit_card_model.dart",
    "$RootFolder\mobile-app\lib\models\debt_model.dart",
    "$RootFolder\mobile-app\lib\models\report_model.dart",

    "$RootFolder\mobile-app\lib\services\auth_service.dart",
    "$RootFolder\mobile-app\lib\services\api_service.dart",
    "$RootFolder\mobile-app\lib\services\notification_service.dart",
    "$RootFolder\mobile-app\lib\services\pdf_service.dart",

    "$RootFolder\mobile-app\pubspec.yaml"
)

foreach ($File in $FlutterFiles)
{
    New-Item -ItemType File -Path $File -Force | Out-Null
}

# ============================================================
# BACKEND API
# ============================================================

Write-Host "Creating Backend Structure..." -ForegroundColor Magenta

$BackendFolders = @(

    "$RootFolder\backend-api",

    "$RootFolder\backend-api\src",

    # Config
    "$RootFolder\backend-api\src\config",

    # Middleware
    "$RootFolder\backend-api\src\middleware",

    # Models
    "$RootFolder\backend-api\src\models",

    # Routes
    "$RootFolder\backend-api\src\routes",

    # Controllers
    "$RootFolder\backend-api\src\controllers",

    # Services
    "$RootFolder\backend-api\src\services",

    # Utils
    "$RootFolder\backend-api\src\utils"
)

foreach ($Folder in $BackendFolders)
{
    New-Item -ItemType Directory -Path $Folder -Force | Out-Null
}

# ============================================================
# BACKEND FILES
# ============================================================

Write-Host "Creating Backend Files..." -ForegroundColor DarkYellow

$BackendFiles = @(

    # Root
    "$RootFolder\backend-api\.env",
    "$RootFolder\backend-api\package.json",
    "$RootFolder\backend-api\README.md",

    # App
    "$RootFolder\backend-api\src\server.js",
    "$RootFolder\backend-api\src\app.js",

    # Config
    "$RootFolder\backend-api\src\config\db.js",
    "$RootFolder\backend-api\src\config\firebaseAdmin.js",
    "$RootFolder\backend-api\src\config\env.js",

    # Middleware
    "$RootFolder\backend-api\src\middleware\authMiddleware.js",
    "$RootFolder\backend-api\src\middleware\errorMiddleware.js",
    "$RootFolder\backend-api\src\middleware\validateRequest.js",

    # Models
    "$RootFolder\backend-api\src\models\User.js",
    "$RootFolder\backend-api\src\models\Expense.js",
    "$RootFolder\backend-api\src\models\Loan.js",
    "$RootFolder\backend-api\src\models\CreditCard.js",
    "$RootFolder\backend-api\src\models\Debt.js",
    "$RootFolder\backend-api\src\models\Reminder.js",
    "$RootFolder\backend-api\src\models\Report.js",

    # Routes
    "$RootFolder\backend-api\src\routes\authRoutes.js",
    "$RootFolder\backend-api\src\routes\expenseRoutes.js",
    "$RootFolder\backend-api\src\routes\loanRoutes.js",
    "$RootFolder\backend-api\src\routes\creditCardRoutes.js",
    "$RootFolder\backend-api\src\routes\debtRoutes.js",
    "$RootFolder\backend-api\src\routes\reminderRoutes.js",
    "$RootFolder\backend-api\src\routes\reportRoutes.js",
    "$RootFolder\backend-api\src\routes\savingRoutes.js",

    # Controllers
    "$RootFolder\backend-api\src\controllers\authController.js",
    "$RootFolder\backend-api\src\controllers\expenseController.js",
    "$RootFolder\backend-api\src\controllers\loanController.js",
    "$RootFolder\backend-api\src\controllers\creditCardController.js",
    "$RootFolder\backend-api\src\controllers\debtController.js",
    "$RootFolder\backend-api\src\controllers\reminderController.js",
    "$RootFolder\backend-api\src\controllers\reportController.js",
    "$RootFolder\backend-api\src\controllers\savingController.js",

    # Services
    "$RootFolder\backend-api\src\services\notificationService.js",
    "$RootFolder\backend-api\src\services\pdfService.js",
    "$RootFolder\backend-api\src\services\reportService.js",
    "$RootFolder\backend-api\src\services\savingSuggestionService.js",

    # Utils
    "$RootFolder\backend-api\src\utils\asyncHandler.js",
    "$RootFolder\backend-api\src\utils\responseHandler.js",

    # Root README
    "$RootFolder\README.md"
)

foreach ($File in $BackendFiles)
{
    New-Item -ItemType File -Path $File -Force | Out-Null
}

# ============================================================
# COMPLETED
# ============================================================

Write-Host ""
Write-Host "==========================================" -ForegroundColor Green
Write-Host "NBExpenseManager Folder Structure Created" -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Green
Write-Host ""

Write-Host "Location: $(Get-Location)\NBExpenseManager" -ForegroundColor Cyan
# Base Variables
$apiBaseURL     = "https://pvwa.example.com"
$aamCCPBaseURL  = "https://ccp.example.com"
$apiURI         = "${apiBaseURL}/api"

# Endpoint Variables
$apiAuthType    = "/auth/ldap"
$apiLogon       = "${apiURI}${apiAuthType}/logon"
$apiLogoff      = "${apiURI}/auth/logoff"
$apiAccounts    = "${apiURI}/accounts"
$apiSafes       = "${apiURI}/safes"
$apiApplications = "${apiBaseURL}/WebServices/PIMServices.svc/Applications"

# Logon Variables
$splatLogon = @{
    Uri         = $apiLogon
    Method      = "Post"
    ContentType = "application/json"
}
$splatAAMCCP = @{
    Uri         = "${aamCCPBaseURL}?AppID=DemoApp&Safe=DemoSafe&UserName=DemoUser"
    Method      = "Get"
    ContentType = "application/json"
}

# Accounts Variables
$accountsUserName = "testuser" + $(Get-Random -Minimum 1000 -Maximum 9999)
$splatAccounts = @{
    Uri         = $apiAccounts
    Method      = "Get"
    ContentType = "application/json"
}

# Safes Variables
$safesSafeName = "testsafe" + $(Get-Random -Minimum 1000 -Maximum 9999)
$splatSafes = @{
    Uri         = $apiSafes
    Method      = "Get"
    ContentType = "application/json"
}
$safesSafeMember = "CyberArk_Vault_Users"
$splatSafeMembers = @{
    Uri         = $apiSafes + "/" + $safesSafeName + "/Members"
    Method      = "Get"
    ContentType = "application/json"
}

# Application Variables
$applicationsAppID = "testappid" + $(Get-Random -Minimum 1000 -Maximum 9999)
$splatApplications = @{
    Uri         = $apiApplications
    Method      = "Get"
    ContentType = "application/json"
}

# Application Authentication Variables
$splatApplicationAuthentication = @{
    Uri         = $apiApplications + "/" + $applicationsAppID + "/Authentications"
    Method      = "Post"
    ContentType = "application/json"
}

# Logoff Variables
$splatLogoff = @{
    Uri         = $apiLogoff
    Method      = "Post"
    ContentType = "application/json"
    ErrorAction = "SilentlyContinue"
}

# Logon
$sessionToken = Invoke-RestMethod @splatLogon -Body $(@{ Username="DemoUser"; Password=$(Invoke-RestMethod @splatAAMCCP).Content } | ConvertTo-Json)
$sessionToken | Format-Table

# Set new header parameters with session token
$apiHeader = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$apiHeader.Add("Authorization", $sessionToken)

# Get Accounts
$respGetAccounts = Invoke-RestMethod @splatAccounts -Headers $apiHeader
$respGetAccounts.value | Format-Table

# Add Account
$splatAccounts['Method'] = "Post"
$bodyAddAccount = @{
    Name        = "DemoSafe-${accountsUserName}"
    Address     = "localhost"
    UserName    = $accountsUserName
    PlatformID  = "WinServerLocal"
    SafeName    = "DemoSafe"
    SecretType  = "password"
    Secret      = "Cyberark1"
    SecretManagement = @{
        AutomaticManagementEnabled  = $False
        ManualManagementReason      = "For Script Example"
    }
} | ConvertTo-Json -Depth 2
$respAddAccount = Invoke-RestMethod @splatAccounts -Body $bodyAddAccount -Headers $apiHeader
$respAddAccount | Format-Table
$accountsID     = $respAddAccount.id

# Delete Account
$splatAccounts['Uri']       += "/" + $accountsID
$splatAccounts['Method']    = "Delete"
$respDeleteAccount          = Invoke-RestMethod @splatAccounts -Headers $apiHeader
$respDeleteAccount

# List Safes
$respListSafes = Invoke-RestMethod @splatSafes -Headers $apiHeader
$respListSafes.Safes | Format-Table

# Add Safe
$splatSafes['Uri']      = $apiBaseURL + "/WebServices/PIMServices.svc/Safes"
$splatSafes['Method']   = "Post"
$bodyAddSafe = @{
    safe = @{
        SafeName                    = $safesSafeName
        Description                 = "Created by Script Example"
        OLACEnabled                 = $False
        ManagingCPM                 = "PasswordManager"
        NumberOfVersionsRetention   = 5
    }
} | ConvertTo-Json -Depth 2
$bodyAddSafe
$respAddSafe = Invoke-RestMethod @splatSafes -Body $bodyAddSafe -Headers $apiHeader
$respAddSafe.AddSafeResult | Format-Table

# List Safe Members
$respListSafeMembers = Invoke-RestMethod @splatSafeMembers -Headers $apiHeader
$respListSafeMembers.SafeMembers | Format-Table

# Add Safe Member
$splatSafeMembers['Uri']    = $apiBaseURL + "/WebServices/PIMServices.svc/Safes/" + $safesSafeName + "/Members"
$splatSafeMembers['Method'] = "Post"
$bodySafeMembers = @{
    member = @{
        MemberName  = $safesSafeMember
        SearchIn    = "example.com"
        Permissions = @(
            @{Key="UseAccounts";Value=$true}
            @{Key="RetrieveAccounts";Value=$false}
            @{Key="ListAccounts";Value=$true}
            @{Key="AddAccounts";Value=$false}
            @{Key="UpdateAccountContent";Value=$false}
            @{Key="UpdateAccountProperties";Value=$false}
            @{Key="InitiateCPMAccountManagementOperations";Value=$false}
            @{Key="SpecifyNextAccountContent";Value=$false}
            @{Key="RenameAccounts";Value=$false}
            @{Key="DeleteAccounts";Value=$false}
            @{Key="UnlockAccounts";Value=$false}
            @{Key="ManageSafe";Value=$false}
            @{Key="ManageSafeMembers";Value=$false}
            @{Key="BackupSafe";Value=$false}
            @{Key="ViewAuditLog";Value=$true}
            @{Key="ViewSafeMembers";Value=$false}
            @{Key="RequestsAuthorizationLevel";Value=0}
            @{Key="AccessWithoutConfirmation";Value=$false}
            @{Key="CreateFolders";Value=$false}
            @{Key="DeleteFolders";Value=$false}
            @{Key="MoveAccountsAndFolders";Value=$false}
        )
    }
} | ConvertTo-Json -Depth 3
$splatSafeMembers
$respAddSafeMember = Invoke-RestMethod @splatSafeMembers -Body $bodySafeMembers -Headers $apiHeader
$respAddSafeMember.member | Format-Table

# Remove Safe Member
$splatSafeMembers['Uri']    += "/" + $safesSafeMember
$splatSafeMembers['Method'] = "Delete"
$respDeleteSafeMember       = Invoke-RestMethod @splatSafeMembers -Headers $apiHeader
$respDeleteSafeMember

# Remove Safe
$splatSafes['Uri']      += "/" + $safesSafeName
$splatSafes['Method']   = "Delete"
$respDeleteSafe         = Invoke-RestMethod @splatSafes -Headers $apiHeader
$respDeleteSafe

# List Applications
$bodyListApplications = @{
    Location            = "\"
    IncludeSublocations = $true
} | ConvertTo-Json
$respListApplications = Invoke-RestMethod @splatApplications -Body $bodyListApplications -Headers $apiHeader
$respListApplications.application | Format-Table

# Add Application
$splatApplications['Method'] = "Post"
$bodyAddApplication = @{
    application = @{
        AppID               = $applicationsAppID
        Description         = "For script example"
        BusinessOwnerFName  = "Joe"
        BusinessOwnerLName  = "Garcia"
        BusinessOwnerEmail  = "joe.garcia@cyberark.com"
        BusinessOwnerPhone  = "555-555-1234"
    }
} | ConvertTo-Json -Depth 2
$respAddApplication = Invoke-RestMethod @splatApplications -Body $bodyAddApplication -Headers $apiHeader
$respAddApplication

# Add Application Authentication
$bodyAddApplicationAuthentication = @{
    authentication = @{
        AuthType                = "machineAddress"
        AuthValue               = "127.0.0.1"
    }
} | ConvertTo-Json -Depth 2
$respAddApplicationAuthentication = Invoke-RestMethod @splatApplicationAuthentication -Body $bodyAddApplicationAuthentication -Headers $apiHeader
$respAddApplicationAuthentication

# Get Application Authentications
$splatApplicationAuthentication['Method'] = "Get"
$respListApplicationAuthentications = Invoke-RestMethod @splatApplicationAuthentication -Headers $apiHeader
$respListApplicationAuthentications.authentication | Format-Table

# Delete Application Authentication
$splatApplicationAuthentication['Method'] = "Delete"
$bodyDeleteApplicationAuthentication = @{
    authID = 1
} | ConvertTo-Json
$respDeleteApplicationAuthentication = Invoke-RestMethod @splatApplicationAuthentication -Body $bodyDeleteApplicationAuthentication -Headers $apiHeader
$respDeleteApplicationAuthentication

# Remove Application
$splatApplications['Uri'] += "?AppID=" + $applicationsAppID
$splatApplications['Method'] = "Delete"
$bodyDeleteApplication = @{
    AppID = $applicationsAppID
} | ConvertTo-Json
$respDeleteApplication = Invoke-RestMethod @splatApplications -Body $bodyDeleteApplication -Headers $apiHeader
$respDeleteApplication

# Logoff
Invoke-RestMethod @splatLogoff -Headers $apiHeader | Out-Null

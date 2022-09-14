function Get-AzLogin {
    <#
        .SYNOPSIS
            Checks AZ login status and account
        .DESCRIPTION
            Use this module to check Azure PowerShell login status and make sure that user is logged in.

            It also accepts either subscription name or ID to be set right after checking login.
        .EXAMPLE
            Get-AzLogin
        .EXAMPLE
            Get-AzLogin [[-Subscription] <string>]
    #>
    param (
        [string] $Subscription
    )

    Write-Host "[Get-AzLogin] Checking Azure PowerShell Login... " -NoNewline
    # Check if logged in to Azure PowerShell
    $AccessToken = Get-AzAccessToken -ErrorAction SilentlyContinue
    if (!$AccessToken) {
        Write-Host "Login needed"
        try {
            # Login-AzAccount -ErrorAction stop > Out-Null
            Connect-AzAccount 
        }
        catch
        {
            throw "Could not login to Azure"
        }
    } else {
            Write-Host "Already logged in"
    }

    # Try setting subscription if provided
    if ($Subscription) {
        Write-Host "[Get-AzLogin] Found subscription as argument. Will run Set-AzContext... " -NoNewline
        try {
            Set-AzContext -SubscriptionId $Subscription -ErrorAction stop | Out-Null
            Write-Host "set to $((get-azcontext).Subscription.name)"
        }
        catch
        {
            throw "Could not set Subscription $Subscription"
        }
    }
}

Get-AzLogin

Get-AzSubscription | ForEach-Object { 
    $subscrName = $_.Name
    Set-AzContext -SubscriptionId $_.SubscriptionId
    $subscrId = $_.SubscriptionId 

    (Get-AzResourceGroup).ResourceGroupName | ForEach-Object {
        $rgp = $_
        $tags = Get-AzTag -ResourceId (Get-AzResourceGroup -Name "$rgp").ResourceId -ErrorAction SilentlyContinue
        
        Get-AzResource -ResourceGroupName $rgp | Select-Object -Property Name, ResourceType, ResourceGroupName, `
            @{ name="Owner"; Expression = { $tags.Properties.TagsProperty.Owner } }, `
            @{ name="Subscription ID"; Expression = { $subscrId } }, `
            @{ name="Subscription Name"; Expression = { $subscrName } } -ErrorAction SilentlyContinue

        try {
            if((Get-AzResourceGroup $rgp -ErrorAction SilentlyContinue)) {
                Export-AzViz -ResourceGroup $rgp -Theme light -OutputFilePath /Users/rvance/Documents/Azure/$rgp.svg -OutputFormat svg -LabelVerbosity 1
            }
        }
        Catch { (Get-AzResourceGroup $rgp -ErrorAction SilentlyContinue) }
    }
  }
